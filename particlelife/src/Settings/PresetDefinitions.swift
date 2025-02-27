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
    static let specialPresets = [snake, cells, sandArt, spaceWars, breathing, comet, comet2, moreCells, lava].sorted() { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    
    static func getAllBuiltInPresets() -> [SimulationPreset] {
        return [randomPreset] + [emptyPreset] + specialPresets
    }
    
    static func getDefaultPreset() -> SimulationPreset {
        return emptyPreset
    }
    
    static func makeRandomPreset(speciesCount: Int) -> SimulationPreset {
        return SimulationPreset(
            name: "Random",
            speciesCount: speciesCount,
            particleCount: .k40,
            matrixType: .random,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 7,
            worldSize: 1.0,
            isBuiltIn: true,
            shouldResetSpeciesCount: false,
            speciesColorOffset: 0
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
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 5,
            worldSize: 0.5,
            isBuiltIn: true,
            shouldResetSpeciesCount: false,
            speciesColorOffset: 0
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
            [0.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.015, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, -0.25, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, -0.25, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, -0.25, 0.00]
        ]),
        distributionType: .ring,
        maxDistance: 0.60,
        minDistance: 0.02,
        beta: 0.15,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 4,
        worldSize: 0.75,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 0
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
        pointSize: 12,
        worldSize: 1.25,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 0
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
        pointSize: 10,
        worldSize: 2.00,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 0
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
        distributionType: .line,
        maxDistance: 1.05,
        minDistance: 0.02,
        beta: 0.30,
        friction: 0.10,
        repulsion: 0.03,
        pointSize: 10,
        worldSize: 3.00,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 0
    )
    
    static let sandArt = SimulationPreset(
        name: "Sand Art",
        speciesCount: 6,
        particleCount: .k40,
        matrixType: .custom([
            [0.00, -0.75, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, -1.00, 0.00, 0.00, 0.25],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.50, 0.00, 0.00, -0.75, 0.00, -0.75],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.25, -0.50, 0.00, 0.00]
        ]),
        distributionType: .line,
        maxDistance: 0.60,
        minDistance: 0.02,
        beta: 0.30,
        friction: 0.15,
        repulsion: 0.14,
        pointSize: 5,
        worldSize: 0.50,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 0
    )
    
    static let breathing = SimulationPreset(
        name: "Breathing",
        speciesCount: 3,
        particleCount: .k20,
        matrixType: .custom([
            [0.00, 0.00, 1.00],
            [0.00, -1.00, 0.00],
            [0.00, 0.00, 0.00]
        ]),
        distributionType: .uniform,
        maxDistance: 0.65,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.15,
        repulsion: 0.03,
        pointSize: 6,
        worldSize: 0.50,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 3
    )

    static let comet2 = SimulationPreset(
        name: "Comet 2",
        speciesCount: 3,
        particleCount: .k40,
        matrixType: .custom([
            [-0.78, 0.11, 0.38],
            [0.66, 0.11, -0.49],
            [-0.71, 0.91, 0.74]
        ]),
        distributionType: .uniform,
        maxDistance: 0.65,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 10,
        worldSize: 1.25,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 0
    )

    static let moreCells = SimulationPreset(
        name: "Chloroplast",
        speciesCount: 6,
        particleCount: .k20,
        matrixType: .custom([
            [-1.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.25, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.25],
            [0.00, 0.00, 0.25, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, -1.00, 0.00],
            [0.00, 0.69, 0.00, 0.34, 0.00, -0.75]
        ]),
        distributionType: .uniform,
        maxDistance: 0.65,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 3,
        worldSize: 0.50,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 1
    )

    static let lava = SimulationPreset(
        name: "Lava",
        speciesCount: 3,
        particleCount: .k40,
        matrixType: .custom([
            [0.00, 0.00, 0.65],
            [0.00, -0.70, 0.70],
            [-0.65, 0.00, 0.00]
        ]),
        distributionType: .uniformCircle,
        maxDistance: 0.65,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 11,
        worldSize: 1.00,
        isBuiltIn: true,
        shouldResetSpeciesCount: true,
        speciesColorOffset: 0
    )
}
