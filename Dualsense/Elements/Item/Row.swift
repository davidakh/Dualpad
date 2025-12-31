//
//  Row.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

enum SymbolAnimation {
    case none
    case wiggle
    case bounce
    case breathe
    case pulse
    case scale
}

struct Row: View {
    var interactive: Bool
    var enabled: Bool
    
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
    var isElementButton: Bool
    var elementButtonAction: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: enabled && fill && interactive ? "\(symbol).fill" : "\(symbol)")
                .font(.system(size: 12))
                .apply { view in
                    switch animation {
                    case .none:
                        view
                    case .wiggle:
                        view.symbolEffect(.wiggle, isActive: enabled)
                    case .bounce:
                        view.symbolEffect(.bounce, isActive: enabled)
                    case .breathe:
                        view.symbolEffect(.breathe, isActive: enabled)
                    case .pulse:
                        view.symbolEffect(.pulse, isActive: enabled)
                    case .scale:
                        view.symbolEffect(.scale, isActive: enabled)
                    }
                }
                .foregroundStyle(enabled && interactive ? color : .secondary)
                .frame(width: 24, height: 24)
                .offset(x: offset)
                .background(enabled && interactive ? Color.white : .fill)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.body)
                    .fontWeight(.regular)
                
                if showDescription && enabled {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if showElement {
                if isElementButton, let action = elementButtonAction {
                    Button(action: action) {
                        Image(systemName: element)
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: element)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(6)
    }
}

// Helper extension to apply conditional modifiers
extension View {
    func apply<V: View>(@ViewBuilder _ transform: (Self) -> V) -> V {
        transform(self)
    }
}

#Preview {
    VStack(spacing: 12) {
        Row(interactive: false, enabled: false, symbol: "heart", color: .accent, fill: false, offset: 0, animation: .none, name: "Element", showDescription: true, description: "Some Description", showElement: true, element: "chevron.right", isElementButton: false, elementButtonAction: nil)
        
        Row(interactive: true, enabled: true, symbol: "heart", color: .pink, fill: true, offset: 0, animation: .wiggle, name: "Wiggle Animation", showDescription: true, description: "This wiggles", showElement: true, element: "chevron.right", isElementButton: false, elementButtonAction: nil)
        
        Row(interactive: true, enabled: true, symbol: "star", color: .yellow, fill: true, offset: 0, animation: .bounce, name: "Bounce Animation", showDescription: false, description: "", showElement: true, element: "gearshape", isElementButton: true, elementButtonAction: {
            print("Button tapped!")
        })
    }
    .padding()
}
