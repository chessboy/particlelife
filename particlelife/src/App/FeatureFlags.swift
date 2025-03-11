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
    var description: String { return "\(name): \(state)" }
    
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
    static var enableLogging = FeatureFlag(name: "Enable Logging")
    static var enableFileLogging = FeatureFlag(name: "Enable File Logging")
    static var forceBoomPreset = FeatureFlag(name: "Force Boom Preset")
    static var noStartupInFullScreen = FeatureFlag(name: "No Startup in Full Screen")
    
    // Set to `.cpuOnly`, `.integratedGPU`, or `.dedicatedGPU` (nil allows detection)
    static var debugGPUType: GPUType? = nil
    // Set to a custom core count e.g., 10, 16, 30 (nil allows detection)
    static var debugGPUCoreCount: Int? = 10

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
            forceProductionConfig() // Ensures production safety
        }
    }
    
    /// 📴 Ensures production settings are always safe (All Off)
    static func forceProductionConfig() {
        enableLogging.turnOff()
        enableFileLogging.turnOff()
        forceBoomPreset.turnOff()
        noStartupInFullScreen.turnOff()
        
        debugGPUType = nil
        debugGPUCoreCount = nil
    }
    
    static func logAllFlags() {
        var description = "Feature Flags:"
        
        for flag in allFlags {
            description += "\n\t|-\(flag)"
        }
        
        description += "\n\t|-Debug GPU Type: \(debugGPUType?.rawValue ?? "nil")"
        description += "\n\t|-Debug GPU Core Count: \(debugGPUCoreCount?.description ?? "nil")"

        Logger.log(description, level: .debug)
    }
}
