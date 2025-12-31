//
//  TouchpadView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/31/25.
//

import SwiftUI

struct TouchpadView: View {
    @Environment(DualsenseManager.self) private var dualsenseManager
    @Environment(AppData.self) private var appData
    @State private var mouseHover = false
    @State private var menuPresent = false
    
    var body: some View {
        if let touchpadManager = dualsenseManager.touchpadManager {
            touchpadContent(for: touchpadManager)
        } else {
            Text("Touchpad manager not available")
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func touchpadContent(for touchpadManager: TouchpadManager) -> some View {
        VStack(spacing: 12) {
            // Main toggle
            VStack(alignment: .center, spacing: 2) {
                Item(interactive: true,
                     enabled: Binding(
                        get: { appData.mouseActive },
                        set: { appData.mouseActive = $0 }
                     ),
                     hover: $mouseHover,
                     symbol: "cursorarrow.click.2",
                     color: .accent,
                     fill: false,
                     offset: 0,
                     animation: .bounce,
                     name: "Touchpad to Mouse",
                     showDescription: true,
                     description: appData.mouseActive ? "System-wide cursor control" : "Enable for mouse control",
                     showElement: true,
                     element: "slider.horizontal.3",
                     isElementButton: true,
                     elementButtonAction: {
                        withAnimation {
                            menuPresent.toggle()
                        }
                     })
            }
            
            if menuPresent {
                VStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Sensitivity")
                                .font(.body)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "tortoise")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                            
                            Slider(value: Binding(
                                get: { appData.mouseSensitivity },
                                set: { appData.mouseSensitivity = $0 }
                            ), in: 0.1...1.0)
                            
                            Image(systemName: "hare")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(12)
                    .background(Color.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Acceleration")
                                .font(.body)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.dots.needle.0percent")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                            
                            Slider(value: Binding(
                                get: { appData.mouseAcceleration },
                                set: { appData.mouseAcceleration = $0 }
                            ), in: 0.1...1.0)
                            
                            Image(systemName: "gauge.with.dots.needle.100percent")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(12)
                    .background(Color.fill)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // Accessibility permission warning
                    if !TouchpadManager.checkAccessibilityPermissions() {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("Requires Accessibility permissions")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: appData.mouseActive)
            }
        }
    }
}

#Preview {
    @Previewable @State var manager = DualsenseManager()
    @Previewable @State var appData = AppData()
    
    TouchpadView()
        .environment(manager)
        .environment(appData)
        .frame(width: 400)
        .padding()
}
