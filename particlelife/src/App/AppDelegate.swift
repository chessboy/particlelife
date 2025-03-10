//
//  AppDelegate.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
    
        #if DEBUG
        FeatureFlags.configure(for: .debug)
        #else
        FeatureFlags.configure(for: .production)
        #endif
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
