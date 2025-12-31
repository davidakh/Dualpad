//
//  TouchpadManager.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/27/25.
//

import Foundation
import CoreGraphics
import ApplicationServices
import AppKit
import GameController
import CoreHaptics

@MainActor
@Observable
class TouchpadManager {
    
    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startTracking()
            } else {
                stopTracking()
            }
        }
    }
    
    var sensitivity: Float = 0.5
    var acceleration: Float = 0.25
    var scrollSpeed: Float = 0.5
    
    private var lastTouchPosition: (x: Float, y: Float)? = nil
    private var isTouching: Bool = false
    private var wasPressed: Bool = false
    
    // Two-finger gesture tracking
    private var lastSecondaryTouchPosition: (x: Float, y: Float)? = nil
    private var isTwoFingerTouch: Bool = false
    private var twoFingerGestureStartTime: Date?
    private var didPerformRightClick: Bool = false
    
    // Use DispatchSourceTimer for reliable operation
    private var displayLink: DispatchSourceTimer?
    
    // Background execution activity to prevent App Nap
    private var backgroundActivity: NSObjectProtocol?
    
    // Keep GameController active in background
    private var keepAliveTimer: DispatchSourceTimer?
    
    // Exponential moving average for ultra-smooth movement
    private var smoothedDeltaX: Float = 0
    private var smoothedDeltaY: Float = 0
    private let smoothingFactor: Float = 0.4 // Lower = smoother but more latency
    
    // Two-finger scroll smoothing
    private var smoothedScrollDeltaX: Float = 0
    private var smoothedScrollDeltaY: Float = 0
    private let scrollSmoothingFactor: Float = 0.5
    
    // Accumulated sub-pixel movement for precision
    private var accumulatedX: CGFloat = 0
    private var accumulatedY: CGFloat = 0
    private var accumulatedScrollX: CGFloat = 0
    private var accumulatedScrollY: CGFloat = 0
    
    private weak var dualsenseManager: DualsenseManager?
    
    // Haptic engine for click feedback
    private var hapticEngine: CHHapticEngine?
    private var hapticPlayer: CHHapticPatternPlayer?
    
    // Screen bounds for cursor clamping
    private var screenBounds: CGRect {
        NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }
    
    init(dualsenseManager: DualsenseManager? = nil) {
        self.dualsenseManager = dualsenseManager
    }
    
    func configure(with manager: DualsenseManager) {
        self.dualsenseManager = manager
    }
    
    private func startTracking() {
        guard let manager = dualsenseManager else {
            print("⚠️ Cannot start touchpad tracking: DualsenseManager not available")
            isEnabled = false
            return
        }
        
        guard manager.controller != nil else {
            print("⚠️ Cannot start touchpad tracking: No controller connected")
            isEnabled = false
            return
        }
        
        // Verify accessibility permissions
        if !Self.checkAccessibilityPermissions() {
            print("⚠️ Touchpad control requires Accessibility permissions to work outside the app")
            print("   Go to System Settings > Privacy & Security > Accessibility")
        }
        
        // Prevent App Nap from throttling background operations
        startBackgroundActivity()
        
        // Keep GameController active even when app is in background
        startControllerKeepalive()
        
        // Initialize haptic engine
        setupHapticEngine()
        
        // Create high-frequency timer (250Hz for ultra-smooth tracking)
        // Runs on main thread to avoid actor isolation issues
        displayLink = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        displayLink?.schedule(deadline: .now(), repeating: .milliseconds(4), leeway: .milliseconds(0)) // ~250Hz with no leeway for precise timing
        displayLink?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            // Safe to access manager properties on main thread
            guard let manager = self.dualsenseManager,
                  let controller = manager.controller,
                  let dualSensePad = controller.extendedGamepad as? GCDualSenseGamepad else { 
                return 
            }
            
            // Read touchpad values directly from the controller
            let primaryX = dualSensePad.touchpadPrimary.xAxis.value
            let primaryY = dualSensePad.touchpadPrimary.yAxis.value
            let secondaryX = dualSensePad.touchpadSecondary.xAxis.value
            let secondaryY = dualSensePad.touchpadSecondary.yAxis.value
            let touchpadPressed = dualSensePad.touchpadButton.isPressed
            
            // Create a local state struct to pass to the handler
            let touchpadState = DualsenseManager.TouchpadStates(
                primary: (x: primaryX, y: primaryY),
                secondary: (x: secondaryX, y: secondaryY)
            )
            
            // Already on main actor, call directly
            self.handleTouchpadUpdate(touchpadState)
            self.handleTouchpadButtonUpdate(isPressed: touchpadPressed)
        }
        displayLink?.resume()
        
        print("✅ Touchpad mouse control started (cursor, scroll, right-click, 250Hz polling, system-wide)")
    }
    
    private func stopTracking() {
        displayLink?.cancel()
        displayLink = nil
        
        // Stop controller keepalive
        stopControllerKeepalive()
        
        resetState()
        cleanupHapticEngine()
        
        // End background activity
        stopBackgroundActivity()
        
        print("Touchpad mouse control stopped")
    }
    
    private func resetState() {
        lastTouchPosition = nil
        lastSecondaryTouchPosition = nil
        isTouching = false
        isTwoFingerTouch = false
        twoFingerGestureStartTime = nil
        didPerformRightClick = false
        smoothedDeltaX = 0
        smoothedDeltaY = 0
        smoothedScrollDeltaX = 0
        smoothedScrollDeltaY = 0
        accumulatedX = 0
        accumulatedY = 0
        accumulatedScrollX = 0
        accumulatedScrollY = 0
    }
    
    private func handleTouchpadButtonUpdate(isPressed: Bool) {
        // Detect touchpad button press (rising edge)
        if isPressed && !wasPressed {
            simulateClick()
        }
        wasPressed = isPressed
    }
    
    private func handleTouchpadUpdate(_ states: DualsenseManager.TouchpadStates) {
        let currentX = states.primary.x
        let currentY = states.primary.y
        let secondaryX = states.secondary.x
        let secondaryY = states.secondary.y
        
        // Detect if fingers are on touchpad
        let nowTouching = abs(currentX) > 0.001 || abs(currentY) > 0.001
        let secondaryTouching = abs(secondaryX) > 0.001 || abs(secondaryY) > 0.001
        let nowTwoFingerTouch = nowTouching && secondaryTouching
        
        // Handle transition from two-finger to one-finger or lift
        if isTwoFingerTouch && !nowTwoFingerTouch {
            // Reset two-finger state
            lastSecondaryTouchPosition = nil
            isTwoFingerTouch = false
            twoFingerGestureStartTime = nil
            didPerformRightClick = false
            smoothedScrollDeltaX = 0
            smoothedScrollDeltaY = 0
            accumulatedScrollX = 0
            accumulatedScrollY = 0
            
            // If no fingers remain, reset everything
            if !nowTouching {
                resetState()
                return
            }
        }
        
        // Handle complete finger lift (all fingers up)
        if isTouching && !nowTouching {
            resetState()
            return
        }
        
        // Handle new touch
        if nowTouching && !isTouching {
            lastTouchPosition = (currentX, currentY)
            isTouching = true
            
            if nowTwoFingerTouch {
                lastSecondaryTouchPosition = (secondaryX, secondaryY)
                isTwoFingerTouch = true
                twoFingerGestureStartTime = Date()
                didPerformRightClick = false
            }
            return
        }
        
        // Handle two-finger gestures (scrolling or right-click)
        if nowTwoFingerTouch {
            if !isTwoFingerTouch {
                // Transition from one-finger to two-finger
                lastSecondaryTouchPosition = (secondaryX, secondaryY)
                isTwoFingerTouch = true
                twoFingerGestureStartTime = Date()
                didPerformRightClick = false
                return
            }
            
            guard let lastPrimary = lastTouchPosition,
                  let lastSecondary = lastSecondaryTouchPosition,
                  let gestureStart = twoFingerGestureStartTime else { return }
            
            // Calculate movement of both fingers
            let primaryDeltaX = currentX - lastPrimary.x
            let primaryDeltaY = currentY - lastPrimary.y
            let secondaryDeltaX = secondaryX - lastSecondary.x
            let secondaryDeltaY = secondaryY - lastSecondary.y
            
            // Average the deltas for scrolling
            let avgDeltaX = (primaryDeltaX + secondaryDeltaX) / 2.0
            let avgDeltaY = (primaryDeltaY + secondaryDeltaY) / 2.0
            
            let totalMovement = sqrt(avgDeltaX * avgDeltaX + avgDeltaY * avgDeltaY)
            let timeSinceStart = Date().timeIntervalSince(gestureStart)
            
            // Right-click: Two-finger tap (minimal movement within 0.3s)
            if !didPerformRightClick && timeSinceStart < 0.3 && totalMovement < 0.02 {
                // Wait a bit to see if it's a tap or scroll
            } else if !didPerformRightClick && timeSinceStart >= 0.3 && totalMovement < 0.02 {
                // It's a static two-finger hold - trigger right-click
                simulateRightClick()
                didPerformRightClick = true
                print("Two-finger tap detected - right-click")
            } else if totalMovement > 0.02 {
                // It's a scroll gesture
                didPerformRightClick = true // Mark as used so we don't right-click after scrolling
                
                // Apply exponential moving average smoothing for scroll
                smoothedScrollDeltaX = scrollSmoothingFactor * avgDeltaX + (1 - scrollSmoothingFactor) * smoothedScrollDeltaX
                smoothedScrollDeltaY = scrollSmoothingFactor * avgDeltaY + (1 - scrollSmoothingFactor) * smoothedScrollDeltaY
                
                // Scale for scrolling with adjustable scroll speed
                let scrollMultiplier: Float = 150.0 * scrollSpeed
                let scrollDeltaX = CGFloat(smoothedScrollDeltaX * scrollMultiplier)
                let scrollDeltaY = CGFloat(smoothedScrollDeltaY * scrollMultiplier)
                
                // Accumulate sub-pixel scrolling
                accumulatedScrollX += scrollDeltaX
                accumulatedScrollY += scrollDeltaY
                
                // Only scroll when we have at least 0.5 units of movement
                if abs(accumulatedScrollX) >= 0.5 || abs(accumulatedScrollY) >= 0.5 {
                    performScroll(deltaX: accumulatedScrollX, deltaY: accumulatedScrollY)
                    accumulatedScrollX = 0
                    accumulatedScrollY = 0
                }
            }
            
            // Update last positions for both fingers
            lastTouchPosition = (currentX, currentY)
            lastSecondaryTouchPosition = (secondaryX, secondaryY)
            isTouching = true
            isTwoFingerTouch = true
            return
        }
        
        // Handle single-finger movement (cursor control)
        if nowTouching && !nowTwoFingerTouch, let last = lastTouchPosition {
            // Calculate raw delta
            let rawDeltaX = currentX - last.x
            let rawDeltaY = currentY - last.y
            
            // Apply exponential moving average smoothing
            smoothedDeltaX = smoothingFactor * rawDeltaX + (1 - smoothingFactor) * smoothedDeltaX
            smoothedDeltaY = smoothingFactor * rawDeltaY + (1 - smoothingFactor) * smoothedDeltaY
            
            // Apply velocity-based acceleration curve
            let velocity = sqrt(smoothedDeltaX * smoothedDeltaX + smoothedDeltaY * smoothedDeltaY)
            let accelerationMultiplier: Float
            
            if velocity < 0.005 {
                // Very slow movement - precision mode
                accelerationMultiplier = 0.5
            } else if velocity < 0.02 {
                // Normal movement - linear scaling
                accelerationMultiplier = 1.0 + (velocity * 20)
            } else {
                // Fast movement - accelerated
                accelerationMultiplier = 1.0 + pow(velocity * 15, acceleration)
            }
            
            // Calculate final delta with sensitivity and acceleration
            let baseMultiplier: Float = 800 * sensitivity
            let finalDeltaX = CGFloat(smoothedDeltaX * accelerationMultiplier * baseMultiplier)
            let finalDeltaY = CGFloat(smoothedDeltaY * accelerationMultiplier * baseMultiplier)
            
            // Accumulate sub-pixel movement
            accumulatedX += finalDeltaX
            accumulatedY += finalDeltaY
            
            // Only move when we have at least 0.5 pixel of movement
            if abs(accumulatedX) >= 0.5 || abs(accumulatedY) >= 0.5 {
                moveCursor(deltaX: accumulatedX, deltaY: accumulatedY)
                accumulatedX = 0
                accumulatedY = 0
            }
            
            // Update last position
            lastTouchPosition = (currentX, currentY)
        }
        
        isTouching = nowTouching
        isTwoFingerTouch = nowTwoFingerTouch
    }
    
    private func moveCursor(deltaX: CGFloat, deltaY: CGFloat) {
        // Get current cursor position
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
        // Calculate new position (Y is inverted for natural scrolling feel)
        var newX = currentLocation.x + deltaX
        var newY = currentLocation.y - deltaY // Invert Y for natural movement
        
        // Clamp to screen bounds
        let bounds = screenBounds
        newX = max(bounds.minX, min(bounds.maxX, newX))
        newY = max(bounds.minY, min(bounds.maxY, newY))
        
        // Create and post mouse move event
        // Using .cgSessionEventTap allows it to work system-wide (requires accessibility permissions)
        if let moveEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: .mouseMoved,
                                   mouseCursorPosition: CGPoint(x: newX, y: newY),
                                   mouseButton: .left) {
            moveEvent.post(tap: .cgSessionEventTap)
        }
    }
    
    /// Perform smooth scrolling
    private func performScroll(deltaX: CGFloat, deltaY: CGFloat) {
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
        // Create scroll event (using pixel-based scrolling for smooth results)
        // Note: Positive Y scrolls down, negative Y scrolls up (natural scrolling)
        if let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                     units: .pixel,
                                     wheelCount: 2,
                                     wheel1: Int32(deltaY),  // Vertical scroll
                                     wheel2: Int32(deltaX),  // Horizontal scroll
                                     wheel3: 0) {
            scrollEvent.post(tap: .cgSessionEventTap)
        }
    }
    
    /// Simulate a mouse click at current cursor position
    func simulateClick() {
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
        // Trigger haptic feedback
        triggerClickHaptic()
        
        // Mouse down
        if let downEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: .leftMouseDown,
                                   mouseCursorPosition: currentLocation,
                                   mouseButton: .left) {
            downEvent.post(tap: .cgSessionEventTap)
        }
        
        // Small delay for reliable click detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            // Mouse up
            if let upEvent = CGEvent(mouseEventSource: nil,
                                     mouseType: .leftMouseUp,
                                     mouseCursorPosition: currentLocation,
                                     mouseButton: .left) {
                upEvent.post(tap: .cgSessionEventTap)
            }
        }
    }
    
    /// Simulate a right-click at current cursor position
    func simulateRightClick() {
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
        // Trigger haptic feedback
        triggerClickHaptic()
        
        if let downEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: .rightMouseDown,
                                   mouseCursorPosition: currentLocation,
                                   mouseButton: .right) {
            downEvent.post(tap: .cgSessionEventTap)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if let upEvent = CGEvent(mouseEventSource: nil,
                                     mouseType: .rightMouseUp,
                                     mouseCursorPosition: currentLocation,
                                     mouseButton: .right) {
                upEvent.post(tap: .cgSessionEventTap)
            }
        }
    }
    
    /// Trigger a quick haptic feedback for touchpad click
    private func triggerClickHaptic() {
        // Use the pre-created player if available
        guard let player = hapticPlayer else { return }
        
        do {
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // If playback fails, try to recreate the haptic setup
            setupHapticEngine()
        }
    }
    
    /// Set up the haptic engine and pattern player
    private func setupHapticEngine() {
        guard let manager = dualsenseManager,
              let controller = manager.controller,
              let haptics = controller.haptics else { return }
        
        // Clean up existing engine first
        cleanupHapticEngine()
        
        do {
            // Create haptic engine for the controller handles
            guard let engine = try haptics.createEngine(withLocality: .handles) else { return }
            
            // Create a short transient haptic pattern (similar to a tap)
            let sharpness: Float = 1.0  // High sharpness for crisp click feel
            let intensity: Float = 1.0   // Medium intensity
            
            let pattern = try CHHapticPattern(
                events: [
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                        ],
                        relativeTime: 0
                    )
                ],
                parameters: []
            )
            
            // Create the player once and reuse it
            let player = try engine.makePlayer(with: pattern)
            
            // Start the engine
            try engine.start()
            
            // Store references
            self.hapticEngine = engine
            self.hapticPlayer = player
            
        } catch {
            print("Failed to set up haptic feedback: \(error.localizedDescription)")
        }
    }
    
    /// Clean up haptic resources
    private func cleanupHapticEngine() {
        hapticPlayer = nil
        hapticEngine?.stop()
        hapticEngine = nil
    }
    
    /// Check if accessibility permissions are granted
    static func checkAccessibilityPermissions() -> Bool {
        // Check without prompting first
        let trusted = AXIsProcessTrusted()
        
        if !trusted {
            // If not trusted, prompt the user
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            return AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        
        return trusted
    }
    
    // MARK: - Background Activity Management
    
    /// Start background activity to prevent App Nap from throttling the app
    private func startBackgroundActivity() {
        // If already running, don't start again
        guard backgroundActivity == nil else { return }
        
        // Request background execution with user-initiated QoS
        // This prevents macOS from throttling the app when it's not in focus
        backgroundActivity = ProcessInfo.processInfo.beginActivity(
            options: [
                .userInitiated,           // High priority
                .idleSystemSleepDisabled, // Prevent sleep during use
                .suddenTerminationDisabled, // Clean shutdown
                .automaticTerminationDisabled, // Don't auto-terminate
                .background               // Explicitly request background execution
            ],
            reason: "DualSense touchpad mouse control requires continuous background processing"
        )
        
        print("🔋 Background activity started - App Nap disabled for touchpad control")
    }
    
    /// Stop background activity
    private func stopBackgroundActivity() {
        if let activity = backgroundActivity {
            ProcessInfo.processInfo.endActivity(activity)
            backgroundActivity = nil
            print("🔋 Background activity stopped - App Nap re-enabled")
        }
    }
    
    /// Keep GameController framework active in background
    private func startControllerKeepalive() {
        guard keepAliveTimer == nil else { return }
        
        // Create a low-frequency timer that keeps the controller connection alive
        // Use main queue to avoid actor isolation issues
        keepAliveTimer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        keepAliveTimer?.schedule(deadline: .now(), repeating: .milliseconds(100)) // 10Hz keepalive
        keepAliveTimer?.setEventHandler { [weak self] in
            guard let self = self,
                  let manager = self.dualsenseManager,
                  let controller = manager.controller else { return }
            
            // Just access the controller to keep it active
            // This prevents the GameController framework from suspending
            _ = controller.isAttachedToDevice
            _ = controller.extendedGamepad
        }
        keepAliveTimer?.resume()
        
        print("🎮 Controller keepalive started")
    }
    
    /// Stop controller keepalive
    private func stopControllerKeepalive() {
        keepAliveTimer?.cancel()
        keepAliveTimer = nil
        print("🎮 Controller keepalive stopped")
    }
}
