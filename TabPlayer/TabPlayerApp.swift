//
//  TabPlayerApp.swift
//  TabPlayer
//
//  Created by clement leclerc on 05/01/2026.
//

import SwiftUI

@main
struct TabPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingView()
        }
    }
}
