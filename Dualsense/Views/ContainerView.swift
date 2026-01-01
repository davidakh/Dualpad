//
//  ContainerView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct ContainerView: View {
    
    @Binding var otherEnabled: Bool
    @State private var otherHover = false
    
    @Binding var emulationEnabled: Bool
    @State private var emulationHover = false
    
    @Binding var hapticsEnabled: Bool
    @State private var hapticsHover = false
    
    @Binding var adaptiveEnabled: Bool
    @State private var adaptiveHover = false
    
    @Binding var lightEnabled: Bool
    @State private var lightHover = false
    
    @Binding var touchpadEnabled: Bool
    @Binding var touchpadMenu: Bool
    @State private var touchpadHover = false
    
    @Binding var experimentalEnabled: Bool
    @State private var experimentalHover = false
    
    @Binding var debugEnabled: Bool
    @State private var debugHover = false
    
    @State private var settingsEnabled = false
    @State private var settingsHover = false
    
    var body: some View {
        VStack(spacing: 2) {
            Item(interactive: false,
                 enabled: $emulationEnabled,
                 hover: $emulationHover,
                 symbol: "xmark.triangle.circle.square",
                 color: .accent,
                 fill: false,
                 offset: 0,
                 animation: .none,
                 name: "Emulation",
                 showDescription: false,
                 description: "",
                 showElement: true,
                 element: "chevron.right")
            
            Item(interactive: false,
                 enabled: $hapticsEnabled,
                 hover: $hapticsHover,
                 symbol: "waveform",
                 color: .accent,
                 fill: false,
                 offset: 0,
                 animation: .none,
                 name: "Haptics",
                 showDescription: false,
                 description: "",
                 showElement: true,
                 element: "chevron.right")
            
            Item(interactive: false,
                 enabled: $adaptiveEnabled,
                 hover: $adaptiveHover,
                 symbol: "waveform.path.ecg",
                 color: .accent,
                 fill: false,
                 offset: 0,
                 animation: .none,
                 name: "Adaptive Triggers",
                 showDescription: false,
                 description: "",
                 showElement: true,
                 element: "chevron.right")
            
            Item(interactive: false,
                 enabled: $lightEnabled,
                 hover: $lightHover,
                 symbol: "lightbulb",
                 color: .accent,
                 fill: false,
                 offset: 0,
                 animation: .none,
                 name: "Controller Light",
                 showDescription: false,
                 description: "",
                 showElement: true,
                 element: "chevron.right")
            
            Item(interactive: true,
                 enabled: $touchpadEnabled,
                 hover: $touchpadHover,
                 symbol: "pointer.arrow.ipad",
                 color: .accent,
                 fill: false,
                 offset: 0.5,
                 animation: .none,
                 name: "Touchpad",
                 showDescription: false,
                 description: "",
                 showElement: true,
                 element: "slider.horizontal.3",
                 isElementButton: true,
                 elementButtonAction: {
                withAnimation {
                    touchpadMenu.toggle()
                }
            })
            
            if !touchpadHover && !experimentalHover {
                Divider()
                    .padding(.horizontal, 6)
            } else {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.clear)
            }
            
            Item(interactive: false,
                 enabled: $experimentalEnabled,
                 hover: $experimentalHover,
                 symbol: "flask",
                 color: .accent,
                 fill: false,
                 offset: 0,
                 animation: .none,
                 name: "Experimental",
                 showDescription: false,
                 description: "",
                 showElement: true,
                 element: "chevron.right")
            
            Item(interactive: false,
                 enabled: $debugEnabled,
                 hover: $debugHover,
                 symbol: "ladybug",
                 color: .accent,
                 fill: false,
                 offset: 0,
                 animation: .none,
                 name: "Debug",
                 showDescription: false,
                 description: "",
                 showElement: true,
                 element: "chevron.right")
        }
    }
}
