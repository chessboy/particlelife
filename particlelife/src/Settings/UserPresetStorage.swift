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
