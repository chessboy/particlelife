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
    let pointSize: Float
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: SimulationPreset, rhs: SimulationPreset) -> Bool {
        return lhs.name == rhs.name
    }
}

extension SimulationPreset {
    
    static func makeRandomPreset(speciesCount: Int) -> SimulationPreset {
        return SimulationPreset(
            name: "Random \(speciesCount)",
            numSpecies: speciesCount,
            numParticles: .k40,
            forceMatrixType: .random,
            distributionType: .uniform,
            maxDistance: SimulationSettings.maxDistanceDefault,
            minDistance: SimulationSettings.minDistanceDefault,
            beta: SimulationSettings.betaDefault,
            friction: SimulationSettings.frictionDefault,
            repulsionStrength: SimulationSettings.repulsionStrengthDefault,
            pointSize: SimulationSettings.pointSizeDefault
        )}
    
    static let random3Preset = makeRandomPreset(speciesCount: 3)
    static let random6Preset = makeRandomPreset(speciesCount: 6)
    static let random9Preset = makeRandomPreset(speciesCount: 9)
    
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
        repulsionStrength: 0.03,
        pointSize: 20
    )
    
    static let colorClash = SimulationPreset(
        name: "Color Clash",
        numSpecies: 6,
        numParticles: .k40,
        forceMatrixType: .chains3,
        distributionType: .uniform,
        maxDistance: 0.66,
        minDistance: 0.03,
        beta: 0.29,
        friction: 0.06,
        repulsionStrength: 0.02,
        pointSize: SimulationSettings.pointSizeDefault
    )
    
    static let cool = SimulationPreset(
        name: "Cool",
        numSpecies: 3,
        numParticles: .k40,
        forceMatrixType: .custom([
            [ 0.89, -0.81, -0.31],
            [-0.72,  0.08,  0.76],
            [ 0.95, -0.96, -0.64]
        ]),
        distributionType: .uniform,
        maxDistance: SimulationSettings.maxDistanceDefault,
        minDistance: SimulationSettings.minDistanceDefault,
        beta: SimulationSettings.betaDefault,
        friction: SimulationSettings.frictionDefault,
        repulsionStrength: SimulationSettings.repulsionStrengthDefault,
        pointSize: SimulationSettings.pointSizeDefault
    )
    
    static let paintSpatters = SimulationPreset(
        name: "Paint Spatters",
        numSpecies: 8,
        numParticles: .k40,
        forceMatrixType: .custom([
            [ 0.47, -0.37, -0.57, -0.54,  0.06,  0.85, -0.15,  0.37],
            [-0.21, -0.26,  0.42,  0.06, -0.64, -0.38,  0.65,  0.86],
            [-0.39,  0.96, -0.25, -0.82,  0.57, -0.51,  0.70,  0.14],
            [-0.63,  0.25,  0.81, -0.59, -0.16, -0.49, -0.22,  0.85],
            [ 0.58, -0.82, -1.00,  0.53, -0.85, -0.14, -0.68,  0.96],
            [ 0.34,  0.70, -0.93,  0.20, -0.09,  0.76,  0.88, -0.24],
            [ 0.74,  0.42, -0.92, -0.63,  0.86, -0.80,  0.07,  0.59],
            [ 0.62,  0.28, -0.14, -0.22,  0.10, -0.11, -0.78,  0.96]
        ]),
        distributionType: .colorBattle,
        maxDistance: 1.19,
        minDistance: 0.01,
        beta: 0.22,
        friction: 0.21,
        repulsionStrength: 0.03,
        pointSize: SimulationSettings.pointSizeDefault
    )
    
    static let defaultPreset: SimulationPreset = .random6Preset
    
    static let allPresets: [SimulationPreset] = [
        .random3Preset,
        .random6Preset,
        .random9Preset,
        .snakesPreset,
        .cool,
        .colorClash,
        paintSpatters
    ]
    
}
