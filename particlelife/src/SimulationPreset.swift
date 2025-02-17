//
//  SettingsGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//

import Foundation

struct SimulationPreset: Hashable {
    let name: String
    let numSpecies: Int
    let numParticles: ParticleCount
    let forceMatrixType: MatrixType
    let distributionType: DistributionType
    let maxDistance: Float
    let minDistance: Float
    let beta: Float
    let friction: Float
    let repulsionStrength: Float

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: SimulationPreset, rhs: SimulationPreset) -> Bool {
        return lhs.name == rhs.name
    }
}

extension SimulationPreset {
    static let defaultPreset = SimulationPreset(
        name: "Default",
        numSpecies: 6,
        numParticles: .k40,
        forceMatrixType: .random,
        distributionType: .uniform,
        maxDistance: SimulationSettings.maxDistanceDefault,
        minDistance: SimulationSettings.minDistanceDefault,
        beta: SimulationSettings.betaDefault,
        friction: SimulationSettings.frictionDefault,
        repulsionStrength: SimulationSettings.repulsionStrengthDefault
    )
    
    static let snakesPreset = SimulationPreset(
        name: "Snakes",
        numSpecies: 6,
        numParticles: .k30,
        forceMatrixType: .snakes,
        distributionType: .colorBands,
        maxDistance: 0.5,
        minDistance: 0.08,
        beta: 0.1,
        friction: 0.5,
        repulsionStrength: 0.03
    )
    
    static let allPresets: [SimulationPreset] = [
        .defaultPreset,
        .snakesPreset
    ]

}
