//
//  AppDelegate.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
        
    class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationDidFinishLaunching(_ notification: Notification) {
            // Nothing extra needed! Storyboard handles the window creation.
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

