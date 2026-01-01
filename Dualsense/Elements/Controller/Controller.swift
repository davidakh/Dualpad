//
//  Controller.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI
import GameController

struct Controller: View {
    let controllerInfo: DualSenseInfo?
    
    var body: some View {
        VStack {
            HStack {
                Image("Dualsense")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(controllerInfo?.name ?? "No Controller")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .frame(width: 4, height: 4)
                            .foregroundStyle(controllerInfo?.isConnected == true ? .green : .red)
                        
                        if let info = controllerInfo {
                            Text("\(info.connectionType.description)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if info.batteryPercentage != nil || info.batteryState != .discharging {
                                Text("• \(info.batteryStatusDescription)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Not Connected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color.fill)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        // Connected via Bluetooth with battery
        Controller(controllerInfo: DualSenseInfo(
            name: "David's DualSense",
            connectionType: .bluetooth,
            batteryLevel: 0.75,
            batteryState: .discharging,
            isConnected: true
        ))
        
        // Charging via wired
        Controller(controllerInfo: DualSenseInfo(
            name: "DualSense Controller",
            connectionType: .wired,
            batteryLevel: 0.85,
            batteryState: .charging,
            isConnected: true
        ))
        
        // Low battery
        Controller(controllerInfo: DualSenseInfo(
            name: "DualSense Controller",
            connectionType: .bluetooth,
            batteryLevel: 0.15,
            batteryState: .discharging,
            isConnected: true
        ))
        
        // Not connected
        Controller(controllerInfo: nil)
    }
    .padding()
}
