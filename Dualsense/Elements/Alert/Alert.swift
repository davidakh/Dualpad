//
//  Alert.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/31/25.
//

import SwiftUI

struct Alert: View {
    var name: String = "Name"
    
    var body: some View {
        HStack {
            Text(name)
                .font(.headline)
        }
        .frame(height: 48)
    }
}

#Preview {
    Alert()
}
