//
//  AppData.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import Foundation
import SwiftUI

@Observable
class AppData {
    // Menu
    var menuSymbol: String = "DualsenseIcon"
    
    var menuBarCornerRadius: Double = 20.0 {
        didSet {
            UserDefaults.standard.set(menuBarCornerRadius, forKey: "menuBarCornerRadius")
        }
    }
    
    // Touchpad to Mouse
    var mouseActive = false {
        didSet {
            UserDefaults.standard.set(mouseActive, forKey: "mouseActive")
        }
    }
    
    var mouseSensitivity: Double = 0.5 {
        didSet {
            UserDefaults.standard.set(mouseSensitivity, forKey: "mouseSensitivity")
        }
    }
    
    var mouseAcceleration: Double = 0.5 {
        didSet {
            UserDefaults.standard.set(mouseAcceleration, forKey: "mouseAcceleration")
        }
    }
    
    init() {
        if UserDefaults.standard.object(forKey: "mouseActive") != nil {
            self.mouseActive = UserDefaults.standard.bool(forKey: "mouseActive")
        }
        
        if UserDefaults.standard.object(forKey: "mouseSensitivity") != nil {
            self.mouseSensitivity = UserDefaults.standard.double(forKey: "mouseSensitivity")
        }
        
        if UserDefaults.standard.object(forKey: "mouseAcceleration") != nil {
            self.mouseAcceleration = UserDefaults.standard.double(forKey: "mouseAcceleration")
        }
        
        if UserDefaults.standard.object(forKey: "menuBarCornerRadius") != nil {
            self.menuBarCornerRadius = UserDefaults.standard.double(forKey: "menuBarCornerRadius")
        }
    }
    
    // Synchronization
    func syncToDualsenseManager(_ manager: DualsenseManager) {
        // Set the flag so touchpad will auto-enable when controller connects
        manager.shouldEnableTouchpadOnConnect = mouseActive
        
        // Synchronization with TouchpadManager
        if let touchpadManager = manager.touchpadManager {
            touchpadManager.isEnabled = mouseActive && manager.isConnected
            touchpadManager.sensitivity = Float(mouseSensitivity)
            touchpadManager.acceleration = Float(mouseAcceleration)
        }
    }
    
    // Update
    func updateFromDualsenseManager(_ manager: DualsenseManager) {
        if let touchpadManager = manager.touchpadManager {
            mouseActive = touchpadManager.isEnabled
            mouseSensitivity = Double(touchpadManager.sensitivity)
            mouseAcceleration = Double(touchpadManager.acceleration)
        }
    }
}

