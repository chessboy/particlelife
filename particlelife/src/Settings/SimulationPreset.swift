//
//  SettingsGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//

import Foundation

struct SimulationPreset: Hashable, Codable {
    let name: String
    let speciesCount: Int
    let particleCount: ParticleCount
    let matrixType: MatrixType
    let distributionType: DistributionType
    let maxDistance: Float
    let minDistance: Float
    let beta: Float
    let friction: Float
    let repulsion: Float
    let pointSize: Float
    let worldSize: Float
    let isBuiltIn: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: SimulationPreset, rhs: SimulationPreset) -> Bool {
        return lhs.name == rhs.name
    }
}

extension SimulationPreset {
    /// Convenience initializer to modify name and/or forceMatrixType
    func copy(withName newName: String? = nil, newSpeciesCount: Int? = nil, newParticleCount: ParticleCount? = nil, newMatrixType: MatrixType? = nil, newDistributionType: DistributionType? = nil) -> SimulationPreset {
        var copiedMatrixType = newMatrixType ?? matrixType  // Use new matrix if provided

        // Ensure deep copy of custom matrices
        if case .custom(let matrix) = copiedMatrixType {
            copiedMatrixType = .custom(matrix.map { $0.map { $0 } })  // Deep copy
        }

        return SimulationPreset(
            name: newName ?? name,
            speciesCount: newSpeciesCount ?? speciesCount,
            particleCount: newParticleCount ?? particleCount,
            matrixType: copiedMatrixType,
            distributionType: newDistributionType ?? distributionType,
            maxDistance: maxDistance,
            minDistance: minDistance,
            beta: beta,
            friction: friction,
            repulsion: repulsion,
            pointSize: pointSize,
            worldSize: worldSize,
            isBuiltIn: isBuiltIn
        )
    }
}
