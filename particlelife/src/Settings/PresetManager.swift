//
//  PresetManager.swift
//  particlelife
//
//  Created by Rob Silverman on 2/20/25.
//
import Foundation

class PresetManager {
    static let shared = PresetManager()
    private var userPresets: [SimulationPreset] = UserPresetStorage.loadUserPresets()
    
    func getUserPresets() -> [SimulationPreset] {
        return userPresets.sorted  { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    func getAllPresets() -> [SimulationPreset] {
        return PresetDefinitions.getAllBuiltInPresets() + userPresets
    }

    func getPreset(named name: String) -> SimulationPreset? {
        return getAllPresets().first { $0.name == name }
    }
    
    func addUserPreset(_ preset: SimulationPreset) -> SimulationPreset {
        let savedPreset = UserPresetStorage.saveUserPreset(preset)
        userPresets.append(savedPreset)
        return savedPreset
    }
    
    func deleteUserPreset(named presetName: String) {
        // Remove from storage
        UserPresetStorage.deleteUserPreset(named: presetName)

        // Remove from in-memory list
        userPresets.removeAll { $0.name == presetName }

        print("🗑️ Preset deleted: \(presetName)")
    }
}
