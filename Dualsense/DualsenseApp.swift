//
//  DualsenseApp.swift
//  Dualsense
//
//  Created by David Akhmedbayev on 12/29/25.
//

import SwiftUI

@main
struct DualsenseApp: App {
    @State private var appData = AppData()
    
    var body: some Scene {
        MenuBarExtra("Dualsense", systemImage: appData.menuSymbol) {
            MenuView()
                .cornerRadius(32)
                .environment(appData)
        }
        .menuBarExtraStyle(.window)
    }
}
