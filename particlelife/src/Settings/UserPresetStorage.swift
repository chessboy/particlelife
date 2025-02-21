//
//  UserPresetStorage.swift
//  particlelife
//
//  Created by Rob Silverman on 2/20/25.
//

import Foundation

class UserPresetStorage {
    private static let userPresetsKey = "userPresets"

    static func loadUserPresets() -> [SimulationPreset] {
        guard let data = UserDefaults.standard.data(forKey: userPresetsKey) else {
            print("ℹ️ No user presets found in storage.")
            return []
        }
        let decoder = JSONDecoder()
        if let presets = try? decoder.decode([SimulationPreset].self, from: data) {
            print("✅ Loaded \(presets.count) user presets.")
            print(presets)
            return presets
        } else {
            print("❌ Failed to decode user presets.")
            return []
        }
    }
    
    static func saveUserPreset(_ preset: SimulationPreset) -> SimulationPreset {
        var presets = loadUserPresets()
        let uniqueName = ensureUniqueName(for: preset.name, existingPresets: presets)
        let newPreset = preset.copy(withName: uniqueName)
        presets.append(newPreset)
        persistUserPresets(presets)
        print("✅ Saved preset: \(newPreset.name)")

        return newPreset
    }
    
    static func deleteUserPreset(named presetName: String) {
        var presets = loadUserPresets()

        // Filter out the preset with the given name
        let filteredPresets = presets.filter { $0.name != presetName }

        if presets.count == filteredPresets.count {
            print("⚠️ Preset '\(presetName)' not found. No deletion occurred.")
            return
        }

        persistUserPresets(filteredPresets)
        print("🗑️ Deleted preset: \(presetName)")
    }
    
    static func persistUserPresets(_ presets: [SimulationPreset]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(presets) {
            UserDefaults.standard.set(data, forKey: userPresetsKey)
        } else {
            print("❌ Failed to encode user presets.")
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
