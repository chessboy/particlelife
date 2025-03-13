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
    static var specialPresets: [SimulationPreset] = []

    static func loadSpecialPresets() {
        specialPresets = UserPresetStorage.loadPresetsFromBundle()
        Logger.log("\n" + specialPresets.map { "  - \($0.name) (\($0.speciesCount) species, \($0.particleCount.displayString))" }.joined(separator: "\n"))
    }
    
    static func getAllBuiltInPresets() -> [SimulationPreset] {
        return [randomPreset] + [emptyPreset] + specialPresets
    }
    
    static func getDefaultPreset() -> SimulationPreset {
        return randomPreset
    }
    
    static func randomSpecialPreset(excluding excludedPreset: SimulationPreset? = nil) -> SimulationPreset {
        if FeatureFlags.forceBoomPreset.isOn {
            if let boomPreset = (specialPresets.filter({ $0.name == "Boom"}).first) {
                return boomPreset
            }
        }
        
        let availablePresets = specialPresets.filter { $0.id != excludedPreset?.id }
        return availablePresets.randomElement() ?? randomPreset
    }
    static var storedPaletteIndex: Int {
        return max(0, min(UserSettings.shared.int(forKey: UserSettingsKeys.colorPaletteIndex), ColorPalette.allCases.count - 1))
    }
    
    static var storedSpeciesColorOffset: Int {
        return max(0, min(UserSettings.shared.int(forKey: UserSettingsKeys.speciesColorOffset), ColorPalette.speciesCount - 1))
    }

    static func makeRandomPreset(speciesCount: Int) -> SimulationPreset {
        return SimulationPreset(
            name: "Random",
            speciesCount: speciesCount,
            particleCount: ParticleCount.particles(for: speciesCount, gpuCoreCount: SystemCapabilities.shared.gpuCoreCount, gpuType: SystemCapabilities.shared.gpuType),
            matrixType: .randomSymmetry,
            distributionType: .perlinNoise,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.14,
            repulsion: 0.03,
            pointSize: 9,
            worldSize: 1.0,
            preservesUISettings: true,
            speciesColorOffset: storedSpeciesColorOffset,
            paletteIndex: storedPaletteIndex,
            colorEffect: .textured
        )
    }
    
    static func makeEmptyPreset(speciesCount: Int) -> SimulationPreset {
        let emptyMatrix = MatrixType.custom(Array(repeating: Array(repeating: 0.0, count: speciesCount), count: speciesCount))
        return SimulationPreset(
            name: "New",
            speciesCount: speciesCount,
            particleCount: ParticleCount.particles(for: speciesCount, gpuCoreCount: SystemCapabilities.shared.gpuCoreCount, gpuType: SystemCapabilities.shared.gpuType),
            matrixType: emptyMatrix,
            distributionType: .perlinNoise,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.14,
            repulsion: 0.03,
            pointSize: 5,
            worldSize: 0.5,
            preservesUISettings: true,
            speciesColorOffset: storedSpeciesColorOffset,
            paletteIndex: storedPaletteIndex,
            colorEffect: .textured
        )
    }
}
