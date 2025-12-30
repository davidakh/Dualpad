//
//  Item.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct Item: View {
    
    var interactive: Bool
    @Binding var enabled: Bool
    @Binding var hover: Bool
    var symbol: String
    var color: Color
    var fill: Bool
    var offset: CGFloat
    var wiggle: Bool
    var name: String
    var showDescription: Bool
    var description: String
    var showElement: Bool
    var element: String
    
    var body: some View {
        Row(interactive: interactive, enabled: enabled, symbol: symbol, color: color, fill: fill, offset: offset, wiggle: wiggle, name: name, showDescription: showDescription, description: description, showElement: showElement, element: element)
            .background(hover ? .fill : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    enabled.toggle()
                }
            }
            .onHover { hovering in
                withAnimation {
                    hover.toggle()
                }
            }
    }
}
