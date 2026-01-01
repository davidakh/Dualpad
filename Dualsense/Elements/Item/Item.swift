//
//  Item.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct Item: View {
    
    var interactive: Bool
    var hoverable: Bool = true
    @Binding var enabled: Bool
    @Binding var hover: Bool
    var symbol: String
    var color: Color
    var fill: Bool
    var offset: CGFloat
    var animation: SymbolAnimation
    var name: String
    var showDescription: Bool
    var description: String
    var showElement: Bool
    var element: String
    var isElementButton: Bool = false
    var elementButtonAction: (() -> Void)? = nil
    
    var body: some View {
        Row(interactive: interactive, enabled: enabled, symbol: symbol, color: color, fill: fill, offset: offset, animation: animation, name: name, showDescription: showDescription, description: description, showElement: showElement, element: element, isElementButton: isElementButton, elementButtonAction: elementButtonAction)
            .background(hover ? .fill : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    enabled.toggle()
                }
            }
            .onHover { hovering in
                if hoverable {
                    withAnimation {
                        hover = hovering
                    }
                }
            }
    }
}
