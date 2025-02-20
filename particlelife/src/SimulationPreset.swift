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
    
    static let random3Preset = makeRandomPreset(speciesCount: 3)
    static let random6Preset = makeRandomPreset(speciesCount: 6)
    static let random9Preset = makeRandomPreset(speciesCount: 9)
    static let empty2Preset = makeEmptyPreset(speciesCount: 2)
    static let empty3Preset = makeEmptyPreset(speciesCount: 3)
    static let empty4Preset = makeEmptyPreset(speciesCount: 4)
    static let empty5Preset = makeEmptyPreset(speciesCount: 5)
    static let empty6Preset = makeEmptyPreset(speciesCount: 6)
    static let empty7Preset = makeEmptyPreset(speciesCount: 7)
    static let empty8Preset = makeEmptyPreset(speciesCount: 8)
    static let empty9Preset = makeEmptyPreset(speciesCount: 9)
    
    static let defaultPreset: SimulationPreset = aliens

    static let allPresets: [SimulationPreset] = [
        random3Preset, random6Preset, random9Preset,
        inchworm, cells, comet, snuggleBugs,
        aliens,
        empty2Preset, empty3Preset, empty4Preset, empty5Preset, empty6Preset, empty7Preset, empty8Preset, empty9Preset
    ]
}

extension SimulationPreset {

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
        maxDistance: 1.5,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 17,
        worldSize: 2.00
    )
    
    static let aliens = SimulationPreset(
        name: "Aliens",
        numSpecies: 9,
        numParticles: .k40,
        forceMatrixType: .custom([
            [0.99, 0.16, -0.79, 0.89, -0.13, 0.94, 0.94, 0.33, 0.18],
            [-0.68, -0.99, 0.63, 0.30, 0.26, 0.32, 0.06, 0.63, 0.47],
            [-0.59, -0.64, 0.81, -0.17, -0.97, 0.68, 0.90, 0.19, 0.31],
            [-0.40, 0.98, 0.74, 0.61, 0.08, 0.75, 0.82, 0.99, 0.80],
            [-0.41, -0.70, -0.36, -0.34, 0.09, 0.58, -0.29, 0.76, -0.61],
            [0.27, -0.70, 0.72, -0.90, -0.27, 0.45, 0.21, 0.61, -0.70],
            [-0.37, 0.26, 0.98, -0.66, 0.83, -0.83, -1.00, 0.88, 0.11],
            [0.66, 0.28, 0.30, 0.81, -0.23, -0.63, 0.59, 0.10, -0.23],
            [0.94, 0.87, -0.77, -0.56, -0.11, -0.92, 0.40, 0.22, -0.44]
        ]),
        distributionType: .colorWheel,
        maxDistance: 0.75,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.10,
        repulsion: 0.03,
        pointSize: 19,
        worldSize: 4
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
        pointSize: 17,
        worldSize: 1.0
    )
}

extension SimulationPreset {
    
    static func makeRandomPreset(speciesCount: Int, forceMatrixType: MatrixType = .random) -> SimulationPreset {
        return SimulationPreset(
            name: "Random \(speciesCount)x\(speciesCount)",
            numSpecies: speciesCount,
            numParticles: .k40,
            forceMatrixType: forceMatrixType,
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
    
    static func makeEmptyPreset(speciesCount: Int) -> SimulationPreset {
        
        let emptyMatrix = MatrixType.custom(Array(repeating: Array(repeating: 0.0, count: speciesCount), count: speciesCount))

        return SimulationPreset(
            name: "Empty \(speciesCount)x\(speciesCount)",
            numSpecies: speciesCount,
            numParticles: .k20,
            forceMatrixType: emptyMatrix,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 5,
            worldSize: 0.5
        )
    }
}
