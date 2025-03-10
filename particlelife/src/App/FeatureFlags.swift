//
//  TestConfig.swift
//  particlelife
//
//  Created by Rob Silverman on 3/8/25.
//

import Foundation

enum Environment: String {
    case debug
    case production
}

struct FeatureFlag: CustomStringConvertible {
    var description: String { return "\(name) is \(state)" }
    
    let name: String
    var state: State
    
    enum State: String { case on, off }

    init(name: String, defaultState: State = .off) {
        self.name = name
        self.state = defaultState
    }
    
    var isOn: Bool { state == .on }
    var isOff: Bool { state == .off }
    
    mutating func turnOn() { state = .on }
    mutating func turnOff() { state = .off }
    
}

struct FeatureFlags {
    
    // Feature Toggles (Safe Defaults: `.off`)
    static var enableLogging = FeatureFlag(name: "Enable Logging", defaultState: .off)
    static var enableFileLogging = FeatureFlag(name: "Enable File Logging", defaultState: .off)
    static var forceBoomPreset = FeatureFlag(name: "Force Boom Preset", defaultState: .off)
    static var noStartupInFullScreen = FeatureFlag(name: "No Startup in Full Screen", defaultState: .off)
    
    static var allFlags: [FeatureFlag] {
        return [enableLogging, enableFileLogging, forceBoomPreset, noStartupInFullScreen]
    }
    
    /// Configures flags dynamically (e.g., at app launch)
    static func configure(for environment: Environment) {
        
        if environment == .debug {
            enableLogging.turnOn()
            enableFileLogging.turnOn()
            forceBoomPreset.turnOff()
            noStartupInFullScreen.turnOff()
            Logger.log("Environment configured for debug")
            logAllFlags()
        } else {
            enableLogging.turnOn()
            Logger.log("Environment configured for release") // this will be the only log in prod
            enableLogging.turnOff()
            enableFileLogging.turnOff()
            forceBoomPreset.turnOff()
            noStartupInFullScreen.turnOff()
        }
    }
    
    static func logAllFlags() {
        var description = "Feature Flags:"
        
        for flag in allFlags {
            description += "\n\t|-\(flag)"
        }
        
        Logger.log(description, level: .debug)
    }
}
