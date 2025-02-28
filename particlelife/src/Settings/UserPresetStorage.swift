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
            
//            Logger.log("Loaded \(sortedPresets.count) user preset(s):")
//            for preset in sortedPresets {
//                Logger.log("  - \(preset.name) (ID: \(preset.id), \(preset.speciesCount) species, \(preset.particleCount))")
//            }

            return sortedPresets
        } else {
            Logger.log("Failed to decode user presets", level: .error)
            return []
        }
    }
    
    static func migrateIfNeeded() {
        let currentVersion = 1
        let storedVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)
        
        guard storedVersion < currentVersion else {
            Logger.log("No need to migrate from v\(storedVersion) to v\(currentVersion)")
            return
        }
        
        Logger.log("Running preset migration from v\(storedVersion) to v\(currentVersion)...")
        
        var presets = loadUserPresets(checkMigration: false)
        
        // Early exit if no presets exist
        if presets.isEmpty {
            Logger.log("No user presets found. Skipping migration.")
            UserDefaults.standard.set(currentVersion, forKey: migrationVersionKey)
            return
        }
        
        let originalPresets = presets  // Keep original state for comparison
        
        Logger.log("Checking for changes in presets...")
        
        // Perform migration
        presets = presets.map { preset in
            preset.copy(newShouldResetEverything: true)
        }
        
        // Detect modified presets
        let changedPresets = zip(originalPresets, presets).filter { $0 != $1 }
        
        if changedPresets.isEmpty {
            Logger.log("Migration check complete: No changes detected, skipping save.")
            UserDefaults.standard.set(currentVersion, forKey: migrationVersionKey)
            return
        }
        
        // Log only the changes
        Logger.log("Changes detected during migration:")
        changedPresets.forEach { original, migrated in
            Logger.log("  - Preset '\(original.name)' modified.")
            if original.shouldResetEverything != migrated.shouldResetEverything {
                Logger.log("    * shouldResetSpeciesCountAndColors: \(original.shouldResetEverything) → \(migrated.shouldResetEverything)")
            }
        }
        
        // Safety Check: Ensure encoding works before persisting
        guard let encodedPresets = try? JSONEncoder().encode(presets) else {
            Logger.log("Migration failed: Unable to encode presets", level: .error)
            return
        }
        
        // Safety Check: Ensure presets are not empty before saving
        guard !presets.isEmpty else {
            Logger.log("Migration failed: Resulting presets are empty", level: .error)
            return
        }
        
        // Save updated presets
        UserDefaults.standard.set(encodedPresets, forKey: userPresetsKey)
        UserDefaults.standard.set(currentVersion, forKey: migrationVersionKey)
        Logger.log("Preset migration complete")
    }
    
    static func saveUserPreset(_ preset: SimulationPreset, replaceExisting: Bool = false) -> SimulationPreset {
        var presets = loadUserPresets()

        Logger.log("Saving preset '\(preset.name)' (Initial ID: \(preset.id))", level: .debug)

        var finalPreset = preset

        if replaceExisting {
            if let index = presets.firstIndex(where: { $0.name == preset.name }) {
                let existingPreset = presets[index]
                finalPreset = preset.copy(id: existingPreset.id) // Preserve the UUID
                presets[index] = finalPreset
                Logger.log("Replacing existing preset '\(preset.name)' with ID \(existingPreset.id)", level: .debug)
            } else {
                presets.append(preset) // Should never happen, but fallback
            }
        } else {
            let allPresets = presets
            let uniqueName = ensureUniqueName(for: preset.name, existingPresets: allPresets)
            finalPreset = preset.copy(withName: uniqueName)
            presets.append(finalPreset)
        }

        persistUserPresets(presets)
        Logger.log("Persisted preset '\(finalPreset.name)' (ID: \(finalPreset.id))", level: .debug)

        let reloadedPresets = loadUserPresets()

        if let storedPreset = reloadedPresets.first(where: { $0.id == finalPreset.id }) {
            Logger.log("Successfully found saved preset after reload: \(storedPreset.name) (ID: \(storedPreset.id))", level: .debug)
            return storedPreset
        } else {
            Logger.log("ERROR: Saved preset '\(finalPreset.name)' (ID: \(finalPreset.id)) not found after reload!", level: .error)
            return finalPreset // Fallback in case of an issue
        }
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
            Logger.log("Successfully saved \(presets.count) user presets.")
        } else {
            Logger.log("Failed to encode user presets", level: .error)
        }
    }
    /// Ensures preset names are unique
    private static func ensureUniqueName(for name: String, existingPresets: [SimulationPreset], allowReplace: Bool = false) -> String {
        if allowReplace {
            return name // Skip renaming if we're explicitly allowing replacement
        }
        
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
