//
//  PresetDefinitions.swift
//  particlelife
//
//  Created by Rob Silverman on 2/20/25.
//

import Foundation

class PresetDefinitions {
    
    static let randomPresets = [3, 6, 9].map { makeRandomPreset(speciesCount: $0) }
    static let specialPresets = [snake, cells, comet, snuggleBugs, spaceWars]
    static let emptyPresets = (2...9).map { makeEmptyPreset(speciesCount: $0) }
    
    static func getAllBuiltInPresets() -> [SimulationPreset] {
        return randomPresets + specialPresets + emptyPresets
    }
    
    static func getDefaultPreset() -> SimulationPreset {
        return randomPresets[0]
    }
    
    static func makeRandomPreset(speciesCount: Int, forceMatrixType: MatrixType = .random) -> SimulationPreset {
        return SimulationPreset(
            name: "Random \(speciesCount)x\(speciesCount)",
            speciesCount: speciesCount,
            particleCount: .k40,
            matrixType: forceMatrixType,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 11,
            worldSize: 1.0,
            isBuiltIn: true
        )
    }
    
    static func makeEmptyPreset(speciesCount: Int) -> SimulationPreset {
        
        let emptyMatrix = MatrixType.custom(Array(repeating: Array(repeating: 0.0, count: speciesCount), count: speciesCount))
        
        return SimulationPreset(
            name: "Empty \(speciesCount)x\(speciesCount)",
            speciesCount: speciesCount,
            particleCount: ParticleCount.particles(for: speciesCount),
            matrixType: emptyMatrix,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 5,
            worldSize: 0.5,
            isBuiltIn: true
        )
    }
}

extension PresetDefinitions {

    static let snake = SimulationPreset(
        name: "Snake",
        speciesCount: 9,
        particleCount: .k40,
        matrixType: .custom([
            [1.00, 0.25, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 1.00, 0.25, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 1.00, 0.25, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 1.00, 0.25, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 1.00, 0.25, 0.04, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.25, 0.25],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, -0.25, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, -0.25]
        ]),
        distributionType: .line,
        maxDistance: 0.60,
        minDistance: 0.02,
        beta: 0.15,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 5,
        worldSize: 0.75,
        isBuiltIn: true
    )
    
    static let cells = SimulationPreset(
        name: "Cells",
        speciesCount: 3,
        particleCount: .k40,
        matrixType: .custom([
            [-1.00,  -0.05,  1.00],
            [-0.05,  0.50,  -0.05],
            [1.00,  -0.05,  -1.00]
        ]),
        distributionType: .line,
        maxDistance: 0.80,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 15,
        worldSize: 1.25,
        isBuiltIn: true
    )
    
    static let comet = SimulationPreset(
        name: "Comet",
        speciesCount: 3,
        particleCount: .k40,
        matrixType: .custom([
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
        worldSize: 2.00,
        isBuiltIn: true
    )
    
    static let spaceWars = SimulationPreset(
        name: "Space Wars",
        speciesCount: 9,
        particleCount: .k40,
        matrixType: .custom([
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
        worldSize: 4,
        isBuiltIn: true
    )
    
    static let snuggleBugs = SimulationPreset(
        name: "Snuggle Bugs",
        speciesCount: 9,
        particleCount: .k40,
        matrixType: .custom([
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
        worldSize: 1.0,
        isBuiltIn: true
    )
}
