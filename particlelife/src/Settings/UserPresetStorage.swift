//
//  UserPresetStorage.swift
//  particlelife
//
//  Created by Rob Silverman on 2/20/25.
//

import Foundation

class UserPresetStorage {
    private static let userPresetsKey = "userPresets"
    private static let migrationVersionKey = "userPresetsVersion"  // Track migrations
    static private var isMigrating = false  // Prevent infinite loops

    static func loadUserPresets(checkMigration: Bool = false) -> [SimulationPreset] {
        if checkMigration {
            migrateIfNeeded()  // Only runs when explicitly requested
        }

        guard let data = UserDefaults.standard.data(forKey: userPresetsKey) else {
            Logger.log("No user presets found in storage")
            return []
        }

        let decoder = JSONDecoder()
        if let presets = try? decoder.decode([SimulationPreset].self, from: data) {
            let sortedPresets = presets.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            Logger.log("Loaded \(sortedPresets.count) user preset\(sortedPresets.count == 1 ? "" : "s"):\n" +
                sortedPresets.map { "  - \($0.name) (\($0.speciesCount) species, \($0.particleCount))" }.joined(separator: "\n")
            )

            return sortedPresets
        } else {
            Logger.log("Failed to decode user presets", level: .error)
            return []
        }
    }
    
    static func migrateIfNeeded() {
        let currentVersion = 3
        let storedVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)

        guard storedVersion < currentVersion else {
            Logger.log("No need to migrate from v\(storedVersion) to v\(currentVersion)")
            return
        }

        Logger.log("Running preset migration from v\(storedVersion) to v\(currentVersion)...")

        var presets = loadUserPresets(checkMigration: false)
        let originalPresets = presets // Keep original state for comparison

        Logger.log("Original Presets:")
        originalPresets.forEach { print($0.asCode) }

        // perform any migration here
        presets = presets.map { preset in
            return preset
//            return preset.copy(
//                newBeta: preset.beta == 0 ? 0.3 : preset.beta,
//                newPointSize: preset.pointSize < 1 ? 10.0 : preset.pointSize
//            )
        }

        // Safety Check 1: Ensure at least one preset was modified
        guard presets != originalPresets else {
            Logger.log("Migration resulted in no changes, skipping save.")
            UserDefaults.standard.set(currentVersion, forKey: migrationVersionKey)
            return
        }

        // Safety Check 2: Ensure encoding won’t fail before persisting
        guard let encodedPresets = try? JSONEncoder().encode(presets) else {
            Logger.log("Migration failed: Unable to encode presets", level: .error)
            return
        }

        // Safety Check 3: Ensure non-empty valid presets before saving
        guard !presets.isEmpty else {
            Logger.log("Migration failed: Resulting presets are empty", level: .error)
            return
        }

        // Save safely
        UserDefaults.standard.set(encodedPresets, forKey: userPresetsKey)
        UserDefaults.standard.set(currentVersion, forKey: migrationVersionKey)
        Logger.log("Preset migration complete")
    }
    
    static func saveUserPreset(_ preset: SimulationPreset) -> SimulationPreset {
        var presets = loadUserPresets()
        let uniqueName = ensureUniqueName(for: preset.name, existingPresets: presets)
        let newPreset = preset.copy(withName: uniqueName)
        presets.append(newPreset)
        persistUserPresets(presets)
        return newPreset
    }
    
    static func deleteUserPreset(named presetName: String) {
        let presets = loadUserPresets()
        let filteredPresets = presets.filter { $0.name != presetName }

        if presets.count == filteredPresets.count {
            Logger.log("Preset '\(presetName)' not found. No deletion occurred", level: .error)
            return
        }

        persistUserPresets(filteredPresets)
    }
    
    static func persistUserPresets(_ presets: [SimulationPreset]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(presets) {
            UserDefaults.standard.set(data, forKey: userPresetsKey)
        } else {
            Logger.log("Failed to encode user presets", level: .error)
        }
    }

    /// Ensures preset names are unique
    private static func ensureUniqueName(for name: String, existingPresets: [SimulationPreset]) -> String {
        var uniqueName = name
        let allPresetNames = Set(existingPresets.map { $0.name })

        var counter = 1
        while allPresetNames.contains(uniqueName) {
            counter += 1
            uniqueName = "\(name) \(counter)"
        }

        return uniqueName
    }
}
