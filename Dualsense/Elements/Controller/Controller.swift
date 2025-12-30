//
//  Controller.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

struct Controller: View {
    var body: some View {
        HStack {
            Image(systemName: "playstation.logo")
                .foregroundStyle(.white)
                .font(.system(size: 16))
                .frame(width: 36, height: 36)
                .background(.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 0) {
                Text("David's DualSense")
                    .font(.title3)
                    .fontWeight(.semibold)
                HStack(spacing: 4) {
                    Circle()
                        .frame(width: 4, height: 4)
                        .foregroundStyle(.green)
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.fill)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    Controller()
}
