//
//  SettingsGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//

import Foundation

enum SimulationPreset {
    case `default`
    case snakes
}

class SettingsGenerator {
    static func applyPreset(_ preset: SimulationPreset) {
        let settings = SimulationSettings.shared
        
        switch preset {
        case .default:
            settings.maxDistance = SimulationSettings.maxDistanceDefault
            settings.minDistance = SimulationSettings.minDistanceDefault
            settings.beta = SimulationSettings.betaDefault
            settings.friction = SimulationSettings.frictionDefault
            settings.repulsionStrength = SimulationSettings.repulsionStrengthDefault
            
        case .snakes:
            settings.maxDistance = 0.5
            settings.minDistance = 0.08
            settings.beta = 0.1
            settings.friction = 0.7
            settings.repulsionStrength = 0.06
        }
        
        print("✅ Applied preset: \(preset)")
    }
}
