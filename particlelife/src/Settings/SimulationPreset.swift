//
//  SettingsGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//

import Foundation

struct SimulationPreset: Hashable, Codable {
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
    
    func copy(withName newName: String) -> SimulationPreset {
        var copiedForceMatrixType = forceMatrixType

        // Ensure deep copy of custom matrices
        if case .custom(let matrix) = forceMatrixType {
            copiedForceMatrixType = .custom(matrix.map { $0.map { $0 } }) // Deep copy
        }

        return SimulationPreset(
            name: newName,
            numSpecies: numSpecies,
            numParticles: numParticles,
            forceMatrixType: copiedForceMatrixType, // Use copied version
            distributionType: distributionType,
            maxDistance: maxDistance,
            minDistance: minDistance,
            beta: beta,
            friction: friction,
            repulsion: repulsion,
            pointSize: pointSize,
            worldSize: worldSize
        )
    }
}
