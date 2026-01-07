import Foundation
import GameController
import SwiftUI
import AppKit
import CoreGraphics
import ApplicationServices
import CoreHaptics

enum ConnectionType {
    case bluetooth
    case wired
    case unknown
    
    var description: String {
        switch self {
        case .bluetooth: return "Bluetooth"
        case .wired: return "Wired"
        case .unknown: return "Unknown"
        }
    }
}

struct DualSenseInfo {
    let name: String
    let connectionType: ConnectionType
    let batteryLevel: Float?
    let batteryState: GCDeviceBattery.State
    let isConnected: Bool
    
    var batteryPercentage: Int? {
        guard let level = batteryLevel else { return nil }
        return Int(level * 100)
    }
    
    var batteryStatusDescription: String {
        switch batteryState {
        case .discharging:
            if let percentage = batteryPercentage {
                return "\(percentage)%"
            }
            return "Discharging"
        case .charging:
            if let percentage = batteryPercentage {
                return "Charging"
            }
            return "Charging"
        case .full:
            return "Full"
        @unknown default:
            return "Unknown"
        }
    }
}

@Observable
class DualsenseManager {
    private(set) var connectedControllers: [DualSenseInfo] = []
    private var controllerObservers: [NSObjectProtocol] = []
    
    // Primary controller reference
    private(set) var controller: GCController?
    
    // Flag to track if touchpad should be enabled when controller connects
    var shouldEnableTouchpadOnConnect: Bool = false
    
    // Discovery management - prevent continuous scanning
    private var discoveryTimer: DispatchSourceTimer?
    private var isDiscoveryActive: Bool = false
    
    // Button states
    struct ButtonStates {
        var triangle = false
        var x = false
        var circle = false
        var square = false
        var dpadUp = false
        var dpadDown = false
        var dpadLeft = false
        var dpadRight = false
        var r1 = false
        var l1 = false
        var r3 = false
        var l3 = false
        var playstation = false
        var mic = false
        var options = false
        var create = false
        var touchpad = false
    }
    
    struct TouchpadStates {
        var primary: (x: Float, y: Float) = (0, 0)
        var secondary: (x: Float, y: Float) = (0, 0)
    }
    
    var buttonStates = ButtonStates()
    var touchpadStates = TouchpadStates()
    
    // Touchpad Manager
    private(set) var touchpadManager: TouchpadManager?
    
    var primaryController: DualSenseInfo? {
        connectedControllers.first
    }
    
    var isAnyControllerConnected: Bool {
        !connectedControllers.isEmpty
    }
    
    var isConnected: Bool {
        controller != nil && isAnyControllerConnected
    }
    
    var controllerName: String {
        controller?.vendorName ?? "DualSense Controller"
    }
    
    var connectionType: ConnectionType {
        guard let controller = controller else { return .unknown }
        return determineConnectionType(controller)
    }
    
    var batteryLevel: Float? {
        controller?.battery?.batteryLevel
    }
    
    var batteryState: GCDeviceBattery.State? {
        controller?.battery?.batteryState
    }
    
    init() {
        setupControllerNotifications()
        checkForExistingControllers()
        
        // Initialize touchpad manager
        touchpadManager = TouchpadManager(dualsenseManager: self)
    }
    
    deinit {
        removeControllerNotifications()
        stopDiscovery()
    }
    
    private func setupControllerNotifications() {
        let connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.handleControllerConnected(controller)
            }
        }
        
        let disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.handleControllerDisconnected(controller)
            }
        }
        
        controllerObservers = [connectObserver, disconnectObserver]
    }
    
    private func removeControllerNotifications() {
        controllerObservers.forEach { NotificationCenter.default.removeObserver($0) }
        controllerObservers.removeAll()
    }
    
    private func checkForExistingControllers() {
        // First check already-connected controllers (no discovery needed)
        scanForControllers()
        
        // Only start discovery if no controllers found, and auto-stop after 3 seconds
        if connectedControllers.isEmpty {
            startTimeLimitedDiscovery()
        }
    }
    
    /// Starts wireless discovery with automatic timeout to prevent continuous CPU usage
    private func startTimeLimitedDiscovery() {
        guard !isDiscoveryActive else { return }
        
        isDiscoveryActive = true
        GCController.startWirelessControllerDiscovery { [weak self] in
            // Discovery completion handler - called when discovery completes or is stopped
            self?.isDiscoveryActive = false
        }
        
        // Auto-stop discovery after 3 seconds to save CPU
        discoveryTimer?.cancel()
        discoveryTimer = DispatchSource.makeTimerSource(queue: .main)
        discoveryTimer?.schedule(deadline: .now() + 3.0)
        discoveryTimer?.setEventHandler { [weak self] in
            self?.stopDiscovery()
        }
        discoveryTimer?.resume()
    }
    
    private func scanForControllers() {
        let dualsenseControllers = GCController.controllers()
            .filter { isDualSenseController($0) }
        
        connectedControllers = dualsenseControllers.map { createControllerInfo(from: $0) }
        
        // Set primary controller if available
        if controller == nil, let firstController = dualsenseControllers.first {
            controller = firstController
            configureController(firstController)
        }
    }
    
    private func handleControllerConnected(_ controller: GCController) {
        guard isDualSenseController(controller) else { return }
        
        // Stop discovery once a controller connects - saves CPU
        stopDiscovery()
        
        // Enable background event monitoring (this is handled by the framework, not us)
        GCController.shouldMonitorBackgroundEvents = true
        
        let info = createControllerInfo(from: controller)
        
        if !connectedControllers.contains(where: { $0.name == info.name }) {
            connectedControllers.append(info)
        }
        
        // Set as primary if no controller is set
        if self.controller == nil {
            self.controller = controller
            configureController(controller)
            print("DualSense Controller connected: \(info.name) via \(info.connectionType.description)")
            
            // Enable touchpad if it was previously enabled (saved in UserDefaults)
            if shouldEnableTouchpadOnConnect {
                // Small delay to ensure controller is fully configured
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.touchpadManager?.isEnabled = true
                    print("🎮 Auto-enabled touchpad mouse control (restored from saved state)")
                }
            }
        }
    }
    
    private func handleControllerDisconnected(_ controller: GCController) {
        let controllerName = controller.vendorName ?? "DualSense Controller"
        connectedControllers.removeAll { $0.name == controllerName }
        
        // Stop touchpad mouse control when controller disconnects
        touchpadManager?.isEnabled = false
        
        // Clear primary controller if it was disconnected
        if self.controller == controller {
            self.controller = nil
            buttonStates = ButtonStates()
            print("DualSense Controller disconnected")
            
            // Brief discovery attempt to find another controller (with timeout)
            startTimeLimitedDiscovery()
        }
    }
    
    private func isDualSenseController(_ controller: GCController) -> Bool {
        let productCategory = controller.productCategory
        let vendorName = controller.vendorName ?? ""
        
        return vendorName.localizedCaseInsensitiveContains("DualSense") ||
               productCategory == "DualSense Wireless Controller" ||
               productCategory.localizedCaseInsensitiveContains("DualSense")
    }
    
    private func determineConnectionType(_ controller: GCController) -> ConnectionType {
        guard let battery = controller.battery else {
            // No battery info - assume Bluetooth for DualSense
            // (Wired connections typically provide battery info)
            return .bluetooth
        }
        
        // Check battery state
        switch battery.batteryState {
        case .charging:
            return .wired
        case .discharging:
            return .bluetooth
        case .full:
            // When full, check battery level to determine connection
            // Wired typically shows exactly 1.0, Bluetooth shows slightly less
            return battery.batteryLevel >= 0.99 ? .wired : .bluetooth
        @unknown default:
            return .bluetooth
        }
    }
    
    private func createControllerInfo(from controller: GCController) -> DualSenseInfo {
        let connectionType = determineConnectionType(controller)
        let battery = controller.battery
        
        return DualSenseInfo(
            name: controller.vendorName ?? "DualSense Controller",
            connectionType: connectionType,
            batteryLevel: battery?.batteryLevel,
            batteryState: battery?.batteryState ?? .discharging,
            isConnected: true
        )
    }
    
    private func configureController(_ controller: GCController) {
        controller.playerIndex = .index1
        
        // Log haptics availability
        if let haptics = controller.haptics {
            print("Haptics available: \(haptics.supportedLocalities)")
        }
        
        // Configure button handlers for DualSense
        if let dualSensePad = controller.extendedGamepad as? GCDualSenseGamepad {
            dualSensePad.buttonA.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.x = pressed
            }
            dualSensePad.buttonB.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.circle = pressed
            }
            dualSensePad.buttonY.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.triangle = pressed
            }
            dualSensePad.buttonX.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.square = pressed
            }
            dualSensePad.dpad.up.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.dpadUp = pressed
            }
            dualSensePad.dpad.down.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.dpadDown = pressed
            }
            dualSensePad.dpad.left.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.dpadLeft = pressed
            }
            dualSensePad.dpad.right.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.dpadRight = pressed
            }
            dualSensePad.rightShoulder.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.r1 = pressed
            }
            dualSensePad.leftShoulder.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.l1 = pressed
            }
            dualSensePad.leftThumbstickButton?.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.l3 = pressed
            }
            dualSensePad.rightThumbstickButton?.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.r3 = pressed
            }
            dualSensePad.buttonMenu.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.options = pressed
            }
            dualSensePad.buttonOptions?.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.create = pressed
            }
            dualSensePad.touchpadButton.valueChangedHandler = { [weak self] (_: GCControllerButtonInput, value: Float, pressed: Bool) in
                self?.buttonStates.touchpad = pressed
            }
            
            dualSensePad.touchpadPrimary.valueChangedHandler = { [weak self] (_: GCControllerDirectionPad, xValue: Float, yValue: Float) in
                self?.touchpadStates.primary = (xValue, yValue)
            }
            
            dualSensePad.touchpadSecondary.valueChangedHandler = { [weak self] (_: GCControllerDirectionPad, xValue: Float, yValue: Float) in
                self?.touchpadStates.secondary = (xValue, yValue)
            }
        }
    }
    
    func refresh() {
        scanForControllers()
    }
    
    func startDiscovery() {
        startTimeLimitedDiscovery()
        print("Started wireless controller discovery (auto-stops after 3s)...")
    }
    
    func stopDiscovery() {
        discoveryTimer?.cancel()
        discoveryTimer = nil
        
        if isDiscoveryActive {
            GCController.stopWirelessControllerDiscovery()
            isDiscoveryActive = false
            print("Stopped wireless controller discovery")
        }
    }
}

