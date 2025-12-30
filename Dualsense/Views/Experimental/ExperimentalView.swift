//
//  ExperimentalView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct ExperimentalView: View {
    @State private var wineEnabled = false
    @State private var wineHover = false
    
    @State private var bluetoothHapticsEnbled = false
    @State private var bluetoothHapticsHover = false
    
    var body: some View {
        VStack(spacing: 6) {
            Item(interactive: true,
                 enabled: $wineEnabled,
                 hover: $wineHover,
                 symbol: "wineglass",
                 color: .burgundy,
                 fill: true,
                 offset: 0,
                 wiggle: false,
                 name: "Wine Compatibility",
                 showDescription: false,
                 description: "Default",
                 showElement: false,
                 element: "chevron.right")
            
            Item(interactive: true,
                 enabled: $bluetoothHapticsEnbled,
                 hover: $bluetoothHapticsHover,
                 symbol: "bolt.horizontal.fill",
                 color: .blue,
                 fill: false,
                 offset: 0,
                 wiggle: false,
                 name: "Bluetooth Haptics",
                 showDescription: false,
                 description: "Default",
                 showElement: false,
                 element: "chevron.right")
        }
    }
}

#Preview {
    ExperimentalView()
}
