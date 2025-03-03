//
//  PresetDefinitions.swift
//  particlelife
//
//  Created by Rob Silverman on 2/20/25.
//

import Foundation

class PresetDefinitions {
        
    static let randomPreset = makeRandomPreset(speciesCount: 3)
    static let emptyPreset = makeEmptyPreset(speciesCount: 3)
    static let specialPresets = UserPresetStorage.loadPresetsFromBundle()
    
    static func getAllBuiltInPresets() -> [SimulationPreset] {
        return [randomPreset] + [emptyPreset] + specialPresets
    }
    
    static func getDefaultPreset() -> SimulationPreset {
        return randomPreset
    }
    
    static var storedPaletteIndex: Int {
        return max(0, min(UserSettings.shared.int(forKey: UserSettingsKeys.colorPaletteIndex), SpeciesPalette.allCases.count - 1))
    }
    
    static var storedSpeciesColorOffset: Int {
        return max(0, min(UserSettings.shared.int(forKey: UserSettingsKeys.speciesColorOffset), SpeciesPalette.colorCount - 1))
    }

    static func makeRandomPreset(speciesCount: Int) -> SimulationPreset {
        return SimulationPreset(
            name: "Random",
            speciesCount: speciesCount,
            particleCount: ParticleCount.particles(for: speciesCount),
            matrixType: .randomSymmetry,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.14,
            repulsion: 0.03,
            pointSize: 9,
            worldSize: 1.0,
            preservesUISettings: true,
            speciesColorOffset: storedSpeciesColorOffset,
            paletteIndex: storedPaletteIndex
        )
    }
    
    static func makeEmptyPreset(speciesCount: Int) -> SimulationPreset {
        
        let emptyMatrix = MatrixType.custom(Array(repeating: Array(repeating: 0.0, count: speciesCount), count: speciesCount))

        return SimulationPreset(
            name: "New",
            speciesCount: speciesCount,
            particleCount: ParticleCount.particles(for: speciesCount),
            matrixType: emptyMatrix,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.14,
            repulsion: 0.03,
            pointSize: 5,
            worldSize: 0.5,
            preservesUISettings: true,
            speciesColorOffset: storedSpeciesColorOffset,
            paletteIndex: storedPaletteIndex
        )
    }
}
