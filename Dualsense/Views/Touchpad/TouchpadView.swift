//
//  TouchpadView.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/31/25.
//

import SwiftUI

struct TouchpadView: View {
    @Environment(DualsenseManager.self) private var dualsenseManager
    @State private var mouseHover = false
    
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
                        get: { touchpadManager.isEnabled },
                        set: { touchpadManager.isEnabled = $0 }
                     ),
                     hover: $mouseHover,
                     symbol: "cursorarrow.click.2",
                     color: .accent,
                     fill: false,
                     offset: 0.5,
                     wiggle: true,
                     name: "Touchpad to Mouse",
                     showDescription: true,
                     description: touchpadManager.isEnabled ? "System-wide cursor control" : "Enable for mouse control",
                     showElement: true,
                     element: "slider.horizontal.3")
            }
            
            // Settings (only shown when enabled)
            if touchpadManager.isEnabled {
                VStack(spacing: 8) {
                    // Sensitivity slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "hare.fill")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text("Sensitivity")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(touchpadManager.sensitivity * 100))%")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .monospacedDigit()
                        }
                        
                        Slider(value: Binding(
                            get: { Double(touchpadManager.sensitivity) },
                            set: { touchpadManager.sensitivity = Float($0) }
                        ), in: 0.1...1.0)
                        .tint(.accent)
                    }
                    .padding(.horizontal, 16)
                    
                    // Acceleration slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text("Acceleration")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(touchpadManager.acceleration * 100))%")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .monospacedDigit()
                        }
                        
                        Slider(value: Binding(
                            get: { Double(touchpadManager.acceleration) },
                            set: { touchpadManager.acceleration = Float($0) }
                        ), in: 0.0...1.0)
                        .tint(.accent)
                    }
                    .padding(.horizontal, 16)
                    
                    // Scroll speed slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "scroll")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text("Scroll Speed")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(touchpadManager.scrollSpeed * 100))%")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .monospacedDigit()
                        }
                        
                        Slider(value: Binding(
                            get: { Double(touchpadManager.scrollSpeed) },
                            set: { touchpadManager.scrollSpeed = Float($0) }
                        ), in: 0.1...1.0)
                        .tint(.accent)
                    }
                    .padding(.horizontal, 16)
                    
                    // Gesture help
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.point.up.left.fill")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                            Text("One finger: Move cursor")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "hand.point.up.left.and.text.fill")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                            Text("Two fingers: Scroll")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "hand.tap.fill")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                            Text("Two finger tap: Right-click")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "button.programmable")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                            Text("Button press: Left-click")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
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
                        .padding(.horizontal, 16)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: touchpadManager.isEnabled)
            }
        }
    }
}

#Preview {
    @Previewable @State var manager = DualsenseManager()
    
    TouchpadView()
        .environment(manager)
        .frame(width: 400)
        .padding()
}
