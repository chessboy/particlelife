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
    func copy(withName newName: String? = nil, newForceMatrixType: MatrixType? = nil) -> SimulationPreset {
        var copiedForceMatrixType = newForceMatrixType ?? forceMatrixType  // Use new matrix if provided

        // Ensure deep copy of custom matrices
        if case .custom(let matrix) = copiedForceMatrixType {
            copiedForceMatrixType = .custom(matrix.map { $0.map { $0 } })  // Deep copy to avoid mutation issues
        }

        return SimulationPreset(
            name: newName ?? name,  // Use new name if provided, else keep original
            numSpecies: numSpecies,
            numParticles: numParticles,
            forceMatrixType: copiedForceMatrixType,  // Use copied or new version
            distributionType: distributionType,
            maxDistance: maxDistance,
            minDistance: minDistance,
            beta: beta,
            friction: friction,
            repulsion: repulsion,
            pointSize: pointSize,
            worldSize: worldSize,
            isBuiltIn: false
        )
    }
}
