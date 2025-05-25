//
//  Downloads_CleanerApp.swift
//  Downloads Cleaner
//
//  Created by Braden Schneider on 24/5/25.
//

import SwiftUI

@main
struct Downloads_CleanerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 420, maxWidth: 420, minHeight: 284, maxHeight: 284)
                .onAppear {
                    for window in NSApplication.shared.windows {
                        window.tabbingMode = .disallowed
                    }
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {} // Remove the new window option from menu bar
        }
    }
}
