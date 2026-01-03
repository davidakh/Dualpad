//
//  MenuView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI
import AppKit

enum Mode: String, CaseIterable {
    case none = "Unknown"
    case other = "Other Controllers"
    case emulation = "Emulation"
    case haptics = "Haptics"
    case adaptive = "Adaptive Triggers"
    case light = "Light"
    case touchpad = "Touchpad"
    case experimental = "Experimental"
    case debug = "Debug"
}

struct MenuView: View {
    @State private var hidden = true
    @State private var mode: Mode = .none
    @State private var controllerManager = DualsenseManager()
    @State private var appData = AppData()
    
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
        .onChange(of: appData.lightBrightness) { _, newValue in
            controllerManager.setLightBarBrightness(newValue)
        }
        .onChange(of: appData.mouseActive) { _, newValue in
            // Only enable touchpad mouse if there's a controller connected
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
            // If the user wants mouseActive and a controller was just connected, enable the feature
            if newValue && appData.mouseActive {
                controllerManager.touchpadManager?.isEnabled = true
            }
            // If the controller is disconnected, disable the feature
            if !newValue {
                controllerManager.touchpadManager?.isEnabled = false
            }
        }
    }
    
    @ViewBuilder
    private func topView() -> some View {
        if mode != .none {
            Toolbar(name: .constant(mode.rawValue), onBack: { mode = .none })
                .transition(.blurReplace)
        } else {
            Controller(controllerInfo: controllerManager.primaryController)
        }
    }
    
    @ViewBuilder
    private func modeView() -> some View {
        if mode == .haptics {
            HapticsView()
                .transition(.blurReplace)
        } else if mode == .adaptive {
            AdaptiveView()
                .transition(.blurReplace)
        } else if mode == .light {
            LightView(dualsenseManager: controllerManager)
                .transition(.blurReplace)
        } else if mode == .touchpad {
            TouchpadView()
                .transition(.blurReplace)
        } else if mode == .experimental {
            ExperimentalView()
                .transition(.blurReplace)
        } else if mode == .debug {
            DebugView()
        } else {
            ContainerView(
                otherEnabled: Binding (
                    get: { mode == .other },
                    set: { if $0 { mode = .other } else if mode == .other { mode = .none } }
                ),
                emulationEnabled: Binding(
                    get: { mode == .emulation },
                    set: { if $0 { mode = .emulation } else if mode == .emulation { mode = .none } }
                ),
                hapticsEnabled: Binding(
                    get: { mode == .haptics },
                    set: { if $0 { mode = .haptics } else if mode == .haptics { mode = .none } }
                ),
                adaptiveEnabled: Binding(
                    get: { mode == .adaptive },
                    set: { if $0 { mode = .adaptive } else if mode == .adaptive { mode = .none } }
                ),
                lightEnabled: Binding(
                    get: { mode == .light },
                    set: { if $0 { mode = .light } else if mode == .light { mode = .none } }
                ),
                touchpadEnabled: Binding(
                    get: { appData.mouseActive },
                    set: { appData.mouseActive = $0 }
                ),
                touchpadMenu: Binding(
                    get: { mode == .touchpad },
                    set: { if $0 { mode = .touchpad } else if mode == .touchpad { mode = .none } }
                ),
                experimentalEnabled: Binding(
                    get: { mode == .experimental },
                    set: { if $0 { mode = .experimental } else if mode == .experimental { mode = .none } }
                ),
                debugEnabled: Binding(
                    get: { mode == .debug },
                    set: { if $0 { mode = .debug } else if mode == .debug { mode = .none } }
                )
            )
            .transition(.blurReplace)
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
