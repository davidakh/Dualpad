//
//  Toolbar.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct Toolbar: View {
    @Binding var name: String
    var onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    onBack()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .heavy))
                    .offset(x: 0.5)
                    .frame(width: 20, height: 20)
                    .background(Color.fill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Rectangle()
                .frame(width: 20, height: 20)
                .foregroundStyle(.clear)
        }
        .padding(6)
        .frame(height: 32)
    }
}
