//
//  DualsenseApp.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI
import AppKit

@main
struct DualsenseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var floatingPanel: FloatingPanel?
    var appData = AppData()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateStatusItemImage()
            button.action = #selector(togglePanel)
            button.target = self
        }
        
        // Observe appData changes to update icon
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStatusItemImage),
            name: NSNotification.Name("UpdateMenuIcon"),
            object: nil
        )
    }
    
    private func createPanelIfNeeded() {
        guard floatingPanel == nil else { return }
        
        // Create floating panel lazily when first needed
        floatingPanel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 500),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        floatingPanel?.delegate = self
        floatingPanel?.contentView = NSHostingView(
            rootView: MenuView()
                .frame(width: 280)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .environment(appData)
        )
    }
    
    @objc func togglePanel() {
        // Create panel on first use
        createPanelIfNeeded()
        
        guard let panel = floatingPanel, let button = statusItem?.button else { return }
        
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            // Position panel below menu bar icon
            let buttonRect = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
            let panelX = buttonRect.midX - panel.frame.width / 2
            let panelY = buttonRect.minY - panel.frame.height - 8
            
            panel.setFrameOrigin(NSPoint(x: panelX, y: panelY))
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func updateStatusItemImage() {
        if let button = statusItem?.button {
            // Load custom image from Assets catalog
            if let image = NSImage(named: "DualsenseIcon") {
                image.isTemplate = true // Makes it adapt to menu bar appearance
                
                // Resize to standard menu bar icon size (18x18 points)
                let resizedImage = NSImage(size: NSSize(width: 18, height: 18))
                resizedImage.lockFocus()
                image.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18))
                resizedImage.unlockFocus()
                resizedImage.isTemplate = true
                
                button.image = resizedImage
            }
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        floatingPanel?.orderOut(nil)
    }
}

class FloatingPanel: NSPanel {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        self.level = .normal
        self.isOpaque = true
        self.backgroundColor = .clear
        self.hasShadow = true
        
        // Enable layer and set corner radius
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 28
        self.contentView?.layer?.masksToBounds = false
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}

