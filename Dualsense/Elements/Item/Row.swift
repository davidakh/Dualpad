//
//  Row.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct Row: View {
    var interactive: Bool
    var enabled: Bool
    
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
        HStack {
            Image(systemName: enabled && fill && interactive ? "\(symbol).fill" : "\(symbol)")
                .font(.system(size: 12))
                .symbolEffect(.wiggle, isActive: enabled && wiggle)
                .foregroundStyle(enabled && interactive ? color : .secondary)
                .frame(width: 24, height: 24)
                .offset(x: offset)
                .background(enabled && interactive ? .white : .fill)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.title3)
                    .fontWeight(.medium)
                
                if showDescription && enabled {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if showElement {
                Image(systemName: element)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(6)
    }
}

#Preview {
    Row(interactive: false, enabled: false, symbol: "heart", color: .accent, fill: false, offset: 0, wiggle: false, name: "Element", showDescription: true, description: "Some Description", showElement: true, element: "chevron.right")
}
