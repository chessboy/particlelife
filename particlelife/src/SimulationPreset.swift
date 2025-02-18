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
    
    static let inchwormPreset = SimulationPreset(
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
        
    static let chaoticWalkers = SimulationPreset(
        name: "Chaotic Walkers",
        numSpecies: 4,
        numParticles: .k40,
        forceMatrixType: .custom([
            [  0.2, -1.0,  0.6, -0.4 ],  // More negative interactions to break up clumps
            [ -1.0,  0.2, -0.5,  0.7 ],  // Species 2 is drawn to 4, but repulses 3
            [  0.6, -0.5,  0.2, -1.0 ],  // Species 3 avoids 4 but slightly clumps itself
            [ -0.4,  0.7, -1.0,  0.2 ]
        ]),
        distributionType: .uniform,
        maxDistance: 1.0,   // Larger = more cross-species interactions before attraction stops
        minDistance: 0.02,  // Low = avoids clumping
        beta: 0.35,         // Higher = extends peak interaction force before it tapers off
        friction: 0.05,     // Lower friction = longer sustained movement (but not infinite sliding)
        repulsion: 0.015,   // Gentle repulsion to stop extreme clumping without pushing too hard
        pointSize: 9,       // Keeps a balanced visual density
        worldSize: 1.5      // Bigger = prevents the sim from stabilizing into static blobs
    )
    
    static let testPreset = SimulationPreset(
        name: "Test",
        numSpecies: 2,
        numParticles: .k30,
        forceMatrixType: .custom([
            [0, 1],
            [0, 0],
        ]),
        distributionType: .uniform,
        maxDistance: 0.7,
        minDistance: 0.08,
        beta: 0.12,
        friction: 0.4,
        repulsion: 0.03,
        pointSize: 21,
        worldSize: 1.0
    )
    
    static let defaultPreset: SimulationPreset = random6Preset
    
    static let allPresets: [SimulationPreset] = [
        //testPreset,
        random3Preset,
        random6Preset,
        random9Preset,
        inchwormPreset,
        chaoticWalkers
    ]
}
