//
//  MenuView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI
import AppKit

struct MenuView: View {
    @State private var appData = AppData()
    @State private var controllerManager = DualsenseManager()
    
    @State private var hidden = true
    @State private var settingsPresent = false
    
    var body: some View {
        VStack(spacing: 6) {
            topView()
            
            if hidden {
                modeView()
            }
            
            bottomView()
        }
        .padding(6)
        .glassEffect(in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
        .frame(width: 280)
        .fixedSize()
        .buttonStyle(.plain)
        .environment(controllerManager)
        .environment(appData)
        .onAppear {
            appData.syncToDualsenseManager(controllerManager)
        }
        .onChange(of: appData.mouseActive) { _, newValue in
            // Update the flag so it persists across controller disconnects/reconnects
            controllerManager.shouldEnableTouchpadOnConnect = newValue
            
            if newValue && controllerManager.isConnected {
                controllerManager.touchpadManager?.isEnabled = true
            } else {
                controllerManager.touchpadManager?.isEnabled = false
            }
        }
        .onChange(of: appData.mouseSensitivity) { _, newValue in
            controllerManager.touchpadManager?.sensitivity = Float(newValue)
        }
        .onChange(of: appData.mouseAcceleration) { _, newValue in
            controllerManager.touchpadManager?.acceleration = Float(newValue)
        }
        .onChange(of: controllerManager.isConnected) { _, newValue in
            if newValue && appData.mouseActive {
                controllerManager.touchpadManager?.isEnabled = true
            }
            if !newValue {
                controllerManager.touchpadManager?.isEnabled = false
            }
        }
    }
    
    @ViewBuilder
    private func topView() -> some View {
        Controller(controllerInfo: controllerManager.primaryController)
    }
    
    @ViewBuilder
    private func modeView() -> some View {
        VStack(spacing: 6) {
            ContainerView(
                touchpadEnabled: $appData.mouseActive,
                touchpadMenu: $settingsPresent
            )
            if settingsPresent {
                TouchpadView()
            }
        }
    }
    
    @ViewBuilder
    private func bottomView() -> some View {
        BottomToolbar(hidden: $hidden, action: $hidden, symbol: hidden ? "chevron.compact.up" : "chevron.compact.down")
    }
}

#Preview {
    MenuView()
        .frame(width: 280)
}
