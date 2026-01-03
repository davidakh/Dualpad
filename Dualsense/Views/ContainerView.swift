//
//  ContainerView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct ContainerView: View {
    @Binding var touchpadEnabled: Bool
    @Binding var touchpadMenu: Bool
    @State private var touchpadHover = false
    
    var body: some View {
        VStack(spacing: 2) {
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
        }
    }
}
