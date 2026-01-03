//
//  Toolbar.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 1/3/26.
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

struct BottomToolbar: View {
    @State private var hover = false
    @Binding var hidden: Bool
    @Binding var action: Bool
    var symbol: String = "chevron.compact.up"
    
    var body: some View {
        HStack {
            Spacer()
                .frame(width: 20)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    action.toggle()
                }
            }) {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .frame(width: 32, height: 12)
                    .background(hover ? Color.fill : .clear)
                    .clipShape(Capsule())
                    .padding(.horizontal, 6)
                    .onHover{ hovering in
                        hover = hovering
                    }
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(Color.fill)
                .clipShape(Circle())
        }
        .padding(.horizontal, 6)
        .padding(.top, hidden ? 0 : 6)
        .padding(.bottom, 6)
        .buttonStyle(.plain)
    }
}
