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
    
    private var scrollSpeed: Float = 0.9
    
    // Adaptive polling - more aggressive idle reduction
    private var currentPollingInterval: Int = 8 // Start at 125Hz (8ms)
    private let highPollInterval: Int = 8 // 125Hz - active use
    private let lowPollInterval: Int = 100 // 10Hz - idle (was 33ms/30Hz, now much lower)
    private var idleFrameCount: Int = 0
    private let idleThreshold: Int = 60 // ~0.5 second at 125Hz before reducing polling
    
    private var lastTouchPosition: (x: Float, y: Float)? = nil
    private var isTouching: Bool = false
    private var wasPressed: Bool = false
    
    private var lastSecondaryTouchPosition: (x: Float, y: Float)? = nil
    private var isTwoFingerTouch: Bool = false
    private var twoFingerGestureStartTime: Date?
    private var didPerformRightClick: Bool = false
    
    private var displayLink: DispatchSourceTimer?
    
    private var backgroundActivity: NSObjectProtocol?
    
    private var smoothedDeltaX: Float = 0
    private var smoothedDeltaY: Float = 0
    private let smoothingFactor: Float = 1
    
    private var smoothedScrollDeltaX: Float = 0
    private var smoothedScrollDeltaY: Float = 0
    private let scrollSmoothingFactor: Float = 1
    
    private var accumulatedX: CGFloat = 0
    private var accumulatedY: CGFloat = 0
    private var accumulatedScrollX: CGFloat = 0
    private var accumulatedScrollY: CGFloat = 0
    
    private var scrollVelocityX: CGFloat = 0
    private var scrollVelocityY: CGFloat = 0
    private var momentumScrollTimer: DispatchSourceTimer?
    private let momentumDecay: CGFloat = 0.92
    private let momentumThreshold: CGFloat = 0.1
    
    private var consecutiveSlowMovementFrames: Int = 0
    private let slowMovementThreshold: Float = 1
    private let dampeningFactor: Float = 0.25
    
    private weak var dualsenseManager: DualsenseManager?
    
    private var hapticEngine: CHHapticEngine?
    private var hapticPlayer: CHHapticPatternPlayer?
    
    private var screenBounds: CGRect {
        NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 2560, height: 1440)
    }
    
    init(dualsenseManager: DualsenseManager? = nil) {
        self.dualsenseManager = dualsenseManager
    }
    
    func configure(with manager: DualsenseManager) {
        self.dualsenseManager = manager
    }
    
    private func startTracking() {
        guard let manager = dualsenseManager else {
            print("􀇾 Cannot start touchpad tracking: DualsenseManager not available")
            isEnabled = false
            return
        }
        
        guard manager.controller != nil else {
            print("􀇾 Cannot start touchpad tracking: No controller connected")
            isEnabled = false
            return
        }
        
        if !Self.checkAccessibilityPermissions() {
            print("􀇾 Touchpad control requires Accessibility permissions to work outside the app")
            print("   Go to System Settings > Privacy & Security > Accessibility")
        }
        
        startBackgroundActivity()
        
        setupHapticEngine()
        
        // Start with high polling rate
        currentPollingInterval = highPollInterval
        idleFrameCount = 0
        
        scheduleTimer(interval: currentPollingInterval)
        
        print("􀺰 Touchpad mouse control started (cursor, scroll, right-click, adaptive 10-125Hz polling, system-wide)")
    }
    
    private func stopTracking() {
        displayLink?.cancel()
        displayLink = nil
        
        stopMomentumScrolling()
        
        resetState()
        cleanupHapticEngine()
        
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
        scrollVelocityX = 0
        scrollVelocityY = 0
        consecutiveSlowMovementFrames = 0
        idleFrameCount = 0
        currentPollingInterval = highPollInterval
    }
    
    /// Schedules the timer with the given interval - single source of truth for timer creation
    private func scheduleTimer(interval: Int) {
        displayLink?.cancel()
        
        displayLink = DispatchSource.makeTimerSource(queue: .main)
        displayLink?.schedule(deadline: .now(), repeating: .milliseconds(interval), leeway: .milliseconds(2))
        displayLink?.setEventHandler { [weak self] in
            self?.pollTouchpad()
        }
        displayLink?.resume()
    }
    
    /// Single polling function called by the timer
    private func pollTouchpad() {
        guard let manager = dualsenseManager,
              let controller = manager.controller,
              let dualSensePad = controller.extendedGamepad as? GCDualSenseGamepad else {
            return
        }
        
        let primaryX = dualSensePad.touchpadPrimary.xAxis.value
        let primaryY = dualSensePad.touchpadPrimary.yAxis.value
        let secondaryX = dualSensePad.touchpadSecondary.xAxis.value
        let secondaryY = dualSensePad.touchpadSecondary.yAxis.value
        let touchpadPressed = dualSensePad.touchpadButton.isPressed
        
        let touchpadState = DualsenseManager.TouchpadStates(
            primary: (x: primaryX, y: primaryY),
            secondary: (x: secondaryX, y: secondaryY)
        )
        
        handleTouchpadUpdate(touchpadState)
        handleTouchpadButtonUpdate(isPressed: touchpadPressed)
        
        // Adaptive polling: reduce rate when idle
        updatePollingRate()
    }
    
    private func updatePollingRate() {
        let isActive = isTouching || isTwoFingerTouch || abs(scrollVelocityX) > momentumThreshold || abs(scrollVelocityY) > momentumThreshold
        
        if isActive {
            // Reset idle counter when active
            idleFrameCount = 0
            
            // Switch to high polling if needed
            if currentPollingInterval != highPollInterval {
                currentPollingInterval = highPollInterval
                scheduleTimer(interval: currentPollingInterval)
            }
        } else {
            // Increment idle counter
            idleFrameCount += 1
            
            // Switch to low polling after idle threshold
            if idleFrameCount >= idleThreshold && currentPollingInterval != lowPollInterval {
                currentPollingInterval = lowPollInterval
                scheduleTimer(interval: currentPollingInterval)
            }
        }
    }
    
    private func handleTouchpadButtonUpdate(isPressed: Bool) {
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
        
        let nowTouching = abs(currentX) > 0.001 || abs(currentY) > 0.001
        let secondaryTouching = abs(secondaryX) > 0.001 || abs(secondaryY) > 0.001
        let nowTwoFingerTouch = nowTouching && secondaryTouching
        
        if isTwoFingerTouch && !nowTwoFingerTouch {
            startMomentumScrolling()
            
            lastSecondaryTouchPosition = nil
            isTwoFingerTouch = false
            twoFingerGestureStartTime = nil
            didPerformRightClick = false
            smoothedScrollDeltaX = 0
            smoothedScrollDeltaY = 0
            accumulatedScrollX = 0
            accumulatedScrollY = 0
            
            if !nowTouching {
                resetState()
                return
            }
        }
        
        if isTouching && !nowTouching {
            resetState()
            return
        }
        
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
        
        if nowTwoFingerTouch {
            if !isTwoFingerTouch {
                lastSecondaryTouchPosition = (secondaryX, secondaryY)
                isTwoFingerTouch = true
                twoFingerGestureStartTime = Date()
                didPerformRightClick = false
                return
            }
            
            guard let lastPrimary = lastTouchPosition,
                  let lastSecondary = lastSecondaryTouchPosition,
                  let gestureStart = twoFingerGestureStartTime else { return }
            
            let primaryDeltaX = currentX - lastPrimary.x
            let primaryDeltaY = currentY - lastPrimary.y
            let secondaryDeltaX = secondaryX - lastSecondary.x
            let secondaryDeltaY = secondaryY - lastSecondary.y
            
            let avgDeltaX = (primaryDeltaX + secondaryDeltaX) / 2.0
            let avgDeltaY = (primaryDeltaY + secondaryDeltaY) / 2.0
            
            let totalMovement = sqrt(avgDeltaX * avgDeltaX + avgDeltaY * avgDeltaY)
            let timeSinceStart = Date().timeIntervalSince(gestureStart)
            
            if !didPerformRightClick && timeSinceStart < 0.5 && totalMovement < 0.02 {
            } else if !didPerformRightClick && timeSinceStart >= 0.5 && totalMovement < 0.02 {
                simulateRightClick()
                didPerformRightClick = true
                print("Two-finger tap detected - right-click")
            } else if totalMovement > 0.02 {
                didPerformRightClick = true
                
                stopMomentumScrolling()
                
                smoothedScrollDeltaX = scrollSmoothingFactor * avgDeltaX + (1 - scrollSmoothingFactor) * smoothedScrollDeltaX
                smoothedScrollDeltaY = scrollSmoothingFactor * avgDeltaY + (1 - scrollSmoothingFactor) * smoothedScrollDeltaY
                
                let scrollVelocity = sqrt(smoothedScrollDeltaX * smoothedScrollDeltaX + smoothedScrollDeltaY * smoothedScrollDeltaY)
                let scrollAccelerationMultiplier: Float
                
                if scrollVelocity < 0.01 {
                    scrollAccelerationMultiplier = 0.6
                } else if scrollVelocity < 0.05 {
                    scrollAccelerationMultiplier = 1.0 + (scrollVelocity * 12)
                } else {
                    scrollAccelerationMultiplier = 1.0 + pow(scrollVelocity * 8, 0.3)
                }
                
                let baseScrollMultiplier: Float = 500 * scrollSpeed
                let scrollDeltaX = CGFloat(smoothedScrollDeltaX * scrollAccelerationMultiplier * baseScrollMultiplier)
                let scrollDeltaY = CGFloat(smoothedScrollDeltaY * scrollAccelerationMultiplier * baseScrollMultiplier)
                
                scrollVelocityX = scrollDeltaX
                scrollVelocityY = -scrollDeltaY
                
                accumulatedScrollX += scrollDeltaX
                accumulatedScrollY += -scrollDeltaY
                
                if abs(accumulatedScrollX) >= 0.5 || abs(accumulatedScrollY) >= 0.5 {
                    performScroll(deltaX: accumulatedScrollX, deltaY: accumulatedScrollY)
                    accumulatedScrollX = 0
                    accumulatedScrollY = 0
                }
            }
            
            lastTouchPosition = (currentX, currentY)
            lastSecondaryTouchPosition = (secondaryX, secondaryY)
            isTouching = true
            isTwoFingerTouch = true
            return
        }
        
        if nowTouching && !nowTwoFingerTouch, let last = lastTouchPosition {
            let rawDeltaX = currentX - last.x
            let rawDeltaY = currentY - last.y
            
            smoothedDeltaX = smoothingFactor * rawDeltaX + (1 - smoothingFactor) * smoothedDeltaX
            smoothedDeltaY = smoothingFactor * rawDeltaY + (1 - smoothingFactor) * smoothedDeltaY
            
            let velocity = sqrt(smoothedDeltaX * smoothedDeltaX + smoothedDeltaY * smoothedDeltaY)
            let accelerationMultiplier: Float
            
            if velocity < slowMovementThreshold {
                consecutiveSlowMovementFrames += 1
            } else {
                consecutiveSlowMovementFrames = 0
            }
            
            let precisionDampening: Float = (consecutiveSlowMovementFrames > 3) ? dampeningFactor : 1.0
            
            if velocity < 0.005 {
                accelerationMultiplier = 0.5 * precisionDampening
            } else if velocity < 0.02 {
                accelerationMultiplier = (1.0 + (velocity * 20)) * precisionDampening
            } else {
                accelerationMultiplier = 1.0 + pow(velocity * 15, acceleration)
            }
            
            let baseMultiplier: Float = 800 * sensitivity
            let finalDeltaX = CGFloat(smoothedDeltaX * accelerationMultiplier * baseMultiplier)
            let finalDeltaY = CGFloat(smoothedDeltaY * accelerationMultiplier * baseMultiplier)
            
            accumulatedX += finalDeltaX
            accumulatedY += finalDeltaY
            
            if abs(accumulatedX) >= 0.5 || abs(accumulatedY) >= 0.5 {
                moveCursor(deltaX: accumulatedX, deltaY: accumulatedY)
                accumulatedX = 0
                accumulatedY = 0
            }
            
            lastTouchPosition = (currentX, currentY)
        }
        
        isTouching = nowTouching
        isTwoFingerTouch = nowTwoFingerTouch
    }
    
    private func moveCursor(deltaX: CGFloat, deltaY: CGFloat) {
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
        var newX = currentLocation.x + deltaX
        var newY = currentLocation.y - deltaY
        
        let bounds = screenBounds
        newX = max(bounds.minX, min(bounds.maxX, newX))
        newY = max(bounds.minY, min(bounds.maxY, newY))
        
        if let moveEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: .mouseMoved,
                                   mouseCursorPosition: CGPoint(x: newX, y: newY),
                                   mouseButton: .left) {
            moveEvent.post(tap: .cgSessionEventTap)
        }
    }
    
    private func performScroll(deltaX: CGFloat, deltaY: CGFloat) {
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
        if let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                     units: .pixel,
                                     wheelCount: 2,
                                     wheel1: Int32(deltaY),
                                     wheel2: Int32(deltaX),
                                     wheel3: 0) {
            scrollEvent.post(tap: .cgSessionEventTap)
        }
    }
    
    func simulateClick() {
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
        triggerClickHaptic()
        
        if let downEvent = CGEvent(mouseEventSource: nil,
                                   mouseType: .leftMouseDown,
                                   mouseCursorPosition: currentLocation,
                                   mouseButton: .left) {
            downEvent.post(tap: .cgSessionEventTap)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if let upEvent = CGEvent(mouseEventSource: nil,
                                     mouseType: .leftMouseUp,
                                     mouseCursorPosition: currentLocation,
                                     mouseButton: .left) {
                upEvent.post(tap: .cgSessionEventTap)
            }
        }
    }
    
    func simulateRightClick() {
        guard let currentLocation = CGEvent(source: nil)?.location else { return }
        
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
    
    private func triggerClickHaptic() {
        guard let player = hapticPlayer else { return }
        
        do {
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            setupHapticEngine()
        }
    }
    
    private func setupHapticEngine() {
        guard let manager = dualsenseManager,
              let controller = manager.controller,
              let haptics = controller.haptics else { return }
        
        cleanupHapticEngine()
        
        do {
            guard let engine = try haptics.createEngine(withLocality: .handles) else { return }
            
            let sharpness: Float = 0.1
            let intensity: Float = 0.1
            let time: Float = 0.1
            
            let pattern = try CHHapticPattern(
                events: [
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                            CHHapticEventParameter(parameterID: .releaseTime, value: time)
                        ],
                        relativeTime: 0
                    )
                ],
                parameters: []
            )
            
            let player = try engine.makePlayer(with: pattern)
            
            try engine.start()
            
            self.hapticEngine = engine
            self.hapticPlayer = player
            
        } catch {
            print("Failed to set up haptic feedback: \(error.localizedDescription)")
        }
    }
    
    private func cleanupHapticEngine() {
        hapticPlayer = nil
        hapticEngine?.stop()
        hapticEngine = nil
    }
    
    static func checkAccessibilityPermissions() -> Bool {
        let trusted = AXIsProcessTrusted()
        
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            return AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        
        return trusted
    }
    
    private func startBackgroundActivity() {
        guard backgroundActivity == nil else { return }
        
        // Use minimal options needed for touchpad control
        // .userInitiatedAllowingIdleSystemSleep allows system sleep but keeps processing alive
        backgroundActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep],
            reason: "DualSense touchpad mouse control"
        )
    }
    
    private func stopBackgroundActivity() {
        if let activity = backgroundActivity {
            ProcessInfo.processInfo.endActivity(activity)
            backgroundActivity = nil
        }
    }
    
    private func startMomentumScrolling() {
        let totalVelocity = sqrt(scrollVelocityX * scrollVelocityX + scrollVelocityY * scrollVelocityY)
        guard totalVelocity > momentumThreshold else {
            scrollVelocityX = 0
            scrollVelocityY = 0
            return
        }
        
        stopMomentumScrolling()
        
        momentumScrollTimer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        momentumScrollTimer?.schedule(deadline: .now(), repeating: .milliseconds(16))
        momentumScrollTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            self.performScroll(deltaX: self.scrollVelocityX, deltaY: self.scrollVelocityY)
            
            self.scrollVelocityX *= self.momentumDecay
            self.scrollVelocityY *= self.momentumDecay
            
            let currentVelocity = sqrt(self.scrollVelocityX * self.scrollVelocityX + 
                                      self.scrollVelocityY * self.scrollVelocityY)
            if currentVelocity < self.momentumThreshold {
                self.stopMomentumScrolling()
            }
        }
        momentumScrollTimer?.resume()
    }
    
    private func stopMomentumScrolling() {
        momentumScrollTimer?.cancel()
        momentumScrollTimer = nil
        scrollVelocityX = 0
        scrollVelocityY = 0
    }
}
