//
//  AdaptiveView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct AdaptiveView: View {
    var body: some View {
        VStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "l.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    Text("Left Trigger Effect")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Menu {
                    Text("Normal Trigger")
                } label: {
                    HStack {
                        Rectangle()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.clear)
                        Spacer()
                        
                        Text("Normal Trigger")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 32)
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                    )
                }
            }
            .buttonStyle(.plain)
            .padding(12)
            .background(Color.fill)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "r.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fontWeight(.semibold)
                    Text("Right Trigger Effect")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Menu {
                    Text("Normal Trigger")
                } label: {
                    HStack {
                        Rectangle()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.clear)
                        Spacer()
                        
                        Text("Normal Trigger")
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12))
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 32)
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                    )
                }
            }
            .buttonStyle(.plain)
            .padding(12)
            .background(Color.fill)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

#Preview {
    AdaptiveView()
}
