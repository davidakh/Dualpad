//
//  HapticsView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct HapticsView: View {
    @State private var haptics: Double = 1
    
    @State private var playerEnabled = false
    @State private var playerHover = false
    
    @State private var micEnabled = false
    @State private var micHover = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Haptic Feedback")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "waveform.low")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                    
                    Slider(value: $haptics,in: 0...100, step: 25)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(12)
            .background(Color.fill)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            Item(interactive: true,
                 enabled: $playerEnabled,
                 hover: $playerHover,
                 symbol: "gamecontroller",
                 color: .accent,
                 fill: true,
                 offset: 0,
                 animation: .wiggle,
                 name: "Controller Haptics",
                 showDescription: true,
                 description: "Requires a wired connection",
                 showElement: true,
                 element: "slider.horizontal.3",
                 isElementButton: true,
                 elementButtonAction: {
                     print("Open haptics settings")
                 })
            
            Item(interactive: true,
                 enabled: $micEnabled,
                 hover: $micHover,
                 symbol: "music.note",
                 color: .pink,
                 fill: false,
                 offset: 0,
                 animation: .bounce,
                 name: "Audio Haptics",
                 showDescription: true,
                 description: "Requires a wired connection",
                 showElement: false,
                 element: "slider.horizontal.3")
            
            Spacer()
        }
    }
}

#Preview {
    HapticsView()
}
