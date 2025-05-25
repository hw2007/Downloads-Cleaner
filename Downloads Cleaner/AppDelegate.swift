//
//  AppDelegate.swift
//  Downloads Cleaner
//
//  Created by Braden Schneider on 25/5/25.
//

import Foundation
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
