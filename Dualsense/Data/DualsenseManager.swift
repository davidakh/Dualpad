import Foundation
import GameController
import SwiftUI
import AppKit

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
    
    // Light bar properties
    var lightBarColor: Color? = Color(red: 0.0, green: 0.3, blue: 1.0) {
        didSet {
            updateLightBarColor()
        }
    }
    
    var lightBarBrightness: Double = 1.0 {
        didSet {
            updateLightBarColor()
        }
    }
    
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
        GCController.startWirelessControllerDiscovery()
        scanForControllers()
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
        
        let info = createControllerInfo(from: controller)
        
        if !connectedControllers.contains(where: { $0.name == info.name }) {
            connectedControllers.append(info)
        }
        
        // Set as primary if no controller is set
        if self.controller == nil {
            self.controller = controller
            configureController(controller)
            print("DualSense Controller connected: \(info.name) via \(info.connectionType.description)")
        }
    }
    
    private func handleControllerDisconnected(_ controller: GCController) {
        let controllerName = controller.vendorName ?? "DualSense Controller"
        connectedControllers.removeAll { $0.name == controllerName }
        
        // Clear primary controller if it was disconnected
        if self.controller == controller {
            self.controller = nil
            print("DualSense Controller disconnected")
            
            // Try to reconnect to another DualSense if available
            GCController.startWirelessControllerDiscovery()
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
        
        // Set light bar color
        updateLightBarColor()
        
        // Log haptics availability
        if let haptics = controller.haptics {
            print("Haptics available: \(haptics.supportedLocalities)")
        }
    }
    
    private func updateLightBarColor() {
        guard let controller = controller, let light = controller.light else { return }
        
        // If color is nil, turn off the light (set to black)
        guard let lightBarColor = lightBarColor else {
            light.color = GCColor(red: 0.0, green: 0.0, blue: 0.0)
            print("Light bar turned off")
            return
        }
        
        // Convert SwiftUI Color to RGB components with brightness applied
        let nsColor = NSColor(lightBarColor)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return }
        
        // Apply brightness by scaling RGB values
        let adjustedRed = Float(rgbColor.redComponent * lightBarBrightness)
        let adjustedGreen = Float(rgbColor.greenComponent * lightBarBrightness)
        let adjustedBlue = Float(rgbColor.blueComponent * lightBarBrightness)
        
        light.color = GCColor(red: adjustedRed, green: adjustedGreen, blue: adjustedBlue)
        
        print("Light bar updated - Color: RGB(\(adjustedRed), \(adjustedGreen), \(adjustedBlue)), Brightness: \(lightBarBrightness)")
    }
    
    func setLightBarColor(_ color: Color?) {
        lightBarColor = color
    }
    
    func setLightBarBrightness(_ brightness: Double) {
        lightBarBrightness = max(0.0, min(1.0, brightness))
    }
    
    func refresh() {
        scanForControllers()
    }
    
    func startDiscovery() {
        GCController.startWirelessControllerDiscovery()
        print("Started wireless controller discovery...")
    }
    
    func stopDiscovery() {
        GCController.stopWirelessControllerDiscovery()
        print("Stopped wireless controller discovery")
    }
}

