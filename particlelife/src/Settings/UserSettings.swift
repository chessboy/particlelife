//
//  UserSettings.swift
//  particlelife
//
//  Created by Rob Silverman on 3/1/25.
//

import Foundation

final class UserSettings {
    static let shared = UserSettings()
    private let defaults = UserDefaults.standard

    private init() {} // Prevent external instantiation

    // MARK: - Logging Helper
    private func logChange(_ key: String, value: Any) {
        //Logger.log("Updated setting: '\(key)' = \(value)", level: .debug)
    }

    private func logAccess(_ key: String, value: Any) {
        //Logger.log("Accessed setting: '\(key)' = \(value)", level: .debug)
    }

    // MARK: - Setters with Logging
    func set(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
        logChange(key, value: value)
    }

    func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
        logChange(key, value: value)
    }

    func set(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
        logChange(key, value: value)
    }

    func set(_ value: Float, forKey key: String) {
        defaults.set(value, forKey: key)
        logChange(key, value: value)
    }
    
    // MARK: - Getters with Logging
    func int(forKey key: String, defaultValue: Int = 0) -> Int {
        let value = defaults.object(forKey: key) as? Int ?? defaultValue
        logAccess(key, value: value)
        return value
    }

    func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        let value = defaults.object(forKey: key) as? Bool ?? defaultValue
        logAccess(key, value: value)
        return value
    }

    func string(forKey key: String, defaultValue: String = "") -> String {
        let value = defaults.object(forKey: key) as? String ?? defaultValue
        logAccess(key, value: value)
        return value
    }

    func float(forKey key: String, defaultValue: Float = 0.0) -> Float {
        let value = defaults.object(forKey: key) as? Float ?? defaultValue
        logAccess(key, value: value)
        return value
    }
}
