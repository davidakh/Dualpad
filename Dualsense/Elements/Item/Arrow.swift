//
//  Arrow.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 1/1/26.
//

import SwiftUI

struct Arrow: View {
    @State private var hover = false
    var symbol: String = "chevron.compact.up"
    
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 16))
            .frame(width: 32, height: 12)
            .background(hover ? Color.fill : .clear)
            .clipShape(Capsule())
            .padding(6)
            .onHover{ hovering in
                hover = hovering
            }
    }
}

#Preview {
    Arrow()
}
