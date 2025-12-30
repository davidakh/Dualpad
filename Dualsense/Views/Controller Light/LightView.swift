//
//  LightView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct LightView: View {
    @State private var brightness: Double = 1
    
    @State private var playerEnabled = false
    @State private var playerHover = false
    
    @State private var micEnabled = false
    @State private var micHover = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Brightness")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(brightness * 100, specifier: "%.0f")%")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fontWeight(.regular)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                    
                    Slider(value: $brightness)
                    
                    Image(systemName: "sun.max.fill")
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
                 symbol: "person",
                 color: .orange,
                 fill: true,
                 offset: 0,
                 wiggle: false,
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
                 wiggle: false,
                 name: "Mic Light",
                 showDescription: false,
                 description: "Pulse",
                 showElement: false,
                 element: "chevron.right")
            
            Spacer()
        }
    }
}

#Preview {
    LightView()
}
