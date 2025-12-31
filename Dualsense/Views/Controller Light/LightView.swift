//
//  LightView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct LightView: View {
    @Environment(AppData.self) private var appData
    @State private var dualsenseManager: DualsenseManager
    @State private var selectedColor: Color? = .accent
    
    @State private var playerEnabled = false
    @State private var playerHover = false
    
    @State private var micEnabled = false
    @State private var micHover = false
    
    init(dualsenseManager: DualsenseManager) {
        self.dualsenseManager = dualsenseManager
        self._selectedColor = State(initialValue: dualsenseManager.lightBarColor)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Brightness")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(appData.lightBrightness * 100, specifier: "%.0f")%")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                    
                    Slider(value: $appData.lightBrightness)
                    
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(12)
            .background(Color.fill)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            HStack(alignment: .center, spacing: 6) {
                Text("Color")
                    .font(.body)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    selectedColor = nil
                    dualsenseManager.setLightBarColor(nil)
                }) {
                    ZStack {
                        Circle()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color.fill)
                        
                        Image(systemName: "slash.circle")
                            .foregroundStyle(.primary)
                            .font(.system(size: 10))
                    }
                }
                .background(selectedColor == nil ? Circle().stroke(Color.accentColor, lineWidth: 2).frame(width: 20, height: 20) : nil)
                
                ColorButton(color: .accent, selectedColor: $selectedColor, dualsenseManager: dualsenseManager)
                ColorButton(color: .red, selectedColor: $selectedColor, dualsenseManager: dualsenseManager)
                ColorButton(color: .green, selectedColor: $selectedColor, dualsenseManager: dualsenseManager)
                ColorButton(color: .yellow, selectedColor: $selectedColor, dualsenseManager: dualsenseManager)
                ColorButton(color: .purple, selectedColor: $selectedColor, dualsenseManager: dualsenseManager)
            }
            .padding(12)
            .background(Color.fill)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            Item(interactive: true,
                 enabled: $playerEnabled,
                 hover: $playerHover,
                 symbol: "person",
                 color: .accent,
                 fill: true,
                 offset: 0,
                 animation: .none,
                 name: "Player Light",
                 showDescription: false,
                 description: "Default",
                 showElement: false,
                 element: "chevron.right")
            
            Item(interactive: true,
                 enabled: $micEnabled,
                 hover: $micHover,
                 symbol: "mic",
                 color: .orange,
                 fill: true,
                 offset: 0,
                 animation: .pulse,
                 name: "Mic Light",
                 showDescription: false,
                 description: "Pulse",
                 showElement: false,
                 element: "chevron.right")
        }
        .buttonStyle(.plain)
    }
}

// Helper view for color buttons
struct ColorButton: View {
    let color: Color
    @Binding var selectedColor: Color?
    let dualsenseManager: DualsenseManager
    
    var body: some View {
        Button(action: {
            selectedColor = color
            dualsenseManager.setLightBarColor(color)
        }) {
            Circle()
                .frame(width: 16, height: 16)
                .foregroundStyle(color)
        }
        .background(
            selectedColor == color ? 
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 20, height: 20)
                : nil
        )
    }
}

#Preview {
    LightView(dualsenseManager: DualsenseManager())
}
