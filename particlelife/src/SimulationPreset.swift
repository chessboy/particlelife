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
    let repulsion: Float
    let pointSize: Float
    let worldSize: Float

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: SimulationPreset, rhs: SimulationPreset) -> Bool {
        return lhs.name == rhs.name
    }
    
    static func makeRandomPreset(speciesCount: Int) -> SimulationPreset {
        return SimulationPreset(
            name: "Random Symmetric \(speciesCount)",
            numSpecies: speciesCount,
            numParticles: .k40,
            forceMatrixType: .symmetry,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 11,
            worldSize: 1.0
        )
    }
    
    static let random3Preset = makeRandomPreset(speciesCount: 3)
    static let random6Preset = makeRandomPreset(speciesCount: 6)
    static let random9Preset = makeRandomPreset(speciesCount: 9)
    static let defaultPreset: SimulationPreset = random6Preset

    static let inchworm = SimulationPreset(
        name: "Inchworm",
        numSpecies: 6,
        numParticles: .k30,
        forceMatrixType: .snakes,
        distributionType: .colorBands,
        maxDistance: 0.8,
        minDistance: 0.08,
        beta: 0.28,
        friction: 0.3,
        repulsion: 0.04,
        pointSize: 21,
        worldSize: 1.0
    )
        
    static let cells = SimulationPreset(
        name: "Cells",
        numSpecies: 3,
        numParticles: .k40,
        forceMatrixType: .custom([
            [-1.00,  -0.25,  1.00],
            [-0.25,  0.50,  -0.25],
            [1.00,  -0.25,  -1.00]
        ]),
        distributionType: .uniform,
        maxDistance: 0.80,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 15,
        worldSize: 1.25
    )
    
    static let comet = SimulationPreset(
        name: "Comet",
        numSpecies: 3,
        numParticles: .k40,
        forceMatrixType: .custom([
            [-1.00, 1.00, -0.25],
            [1.00, -1.00, 0.50],
            [-0.25, -0.25, 0.50]
        ]),
        distributionType: .uniform,
        maxDistance: 0.65,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 11,
        worldSize: 1.00
    )

    static let snuggleBugs = SimulationPreset(
        name: "Snuggle Bugs",
        numSpecies: 9,
        numParticles: .k40,
        forceMatrixType: .custom([
            [0.25, 0.20, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.25, 0.20, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.25, 0.20, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.25, 0.20, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.25, 0.20, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.25, 0.20, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.25, 0.20, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.25, 0.20],
            [0.20, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.25]
        ]),
        distributionType: .uniform,
        maxDistance: 0.50,
        minDistance: 0.05,
        beta: 0.1,
        friction: 0.20,
        repulsion: 0.01,
        pointSize: 25,
        worldSize: 1.0
    )
        
    static let allPresets: [SimulationPreset] = [
        random3Preset,
        random6Preset,
        random9Preset,
        inchworm,
        cells,
        comet,
        snuggleBugs
    ]
}
