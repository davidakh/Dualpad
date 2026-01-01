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
    var mode: Mode = .none
    var menuSymbol: String = "gamecontroller.fill"
    
    var menuBarCornerRadius: Double = 20.0 {
        didSet {
            UserDefaults.standard.set(menuBarCornerRadius, forKey: "menuBarCornerRadius")
        }
    }
    
    // Light
    var lightBrightness: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(lightBrightness, forKey: "lightBrightness")
        }
    }
    
    var lightColor = "none" {
        didSet {
            UserDefaults.standard.set(lightColor, forKey: "lightColor")
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
        // Loader
        if UserDefaults.standard.object(forKey: "lightBrightness") != nil {
            self.lightBrightness = UserDefaults.standard.double(forKey: "lightBrightness")
        }
        
        if let savedColor = UserDefaults.standard.string(forKey: "lightColor") {
            self.lightColor = savedColor
        }
        
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
        manager.setLightBarBrightness(lightBrightness)
        
        // Synchronization with TouchpadManager
        if let touchpadManager = manager.touchpadManager {
            touchpadManager.isEnabled = mouseActive
            touchpadManager.sensitivity = Float(mouseSensitivity)
            touchpadManager.acceleration = Float(mouseAcceleration)
        }
    }
    
    // Update
    func updateFromDualsenseManager(_ manager: DualsenseManager) {
        lightBrightness = manager.lightBarBrightness
        
        if let touchpadManager = manager.touchpadManager {
            mouseActive = touchpadManager.isEnabled
            mouseSensitivity = Double(touchpadManager.sensitivity)
            mouseAcceleration = Double(touchpadManager.acceleration)
        }
    }
}

