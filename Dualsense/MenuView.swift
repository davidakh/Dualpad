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
    case emulation = "Emulation"
    case haptics = "Haptics"
    case adaptive = "Adaptive Triggers"
    case light = "Light"
    case touchpad = "Touchpad"
    case gyro = "Gyro"
    case experimental = "Experimental"
    case debug = "Debug"
}

struct MenuView: View {
    
    @State private var mode: Mode = .none
    @State private var controllerManager = DualsenseManager()
    
    var body: some View {
        VStack {
            if mode != .none {
                Toolbar(name: .constant(mode.rawValue), onBack: { mode = .none })
                    .transition(.blurReplace)
            }
            
            Controller(controllerInfo: controllerManager.primaryController)
            
            if mode == .haptics {
                HapticsView()
                    .transition(.blurReplace)
            } else if mode == .adaptive {
                AdaptiveView()
                    .transition(.blurReplace)
            } else if mode == .light {
                LightView(dualsenseManager: controllerManager)
                    .transition(.blurReplace)
            } else if mode == .experimental {
                ExperimentalView()
                    .transition(.blurReplace)
            } else {
                ContainerView(
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
                        get: { mode == .touchpad },
                        set: { if $0 { mode = .touchpad } else if mode == .touchpad { mode = .none } }
                    ),
                    gyroEnabled: Binding(
                        get: { mode == .gyro },
                        set: { if $0 { mode = .gyro } else if mode == .gyro { mode = .none } }
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
        .padding(8)
    }
}

#Preview {
    MenuView()
        .frame(width: 360)
}
