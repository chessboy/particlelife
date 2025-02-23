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
    
    var description: String {
            """
            Preset: \(name)
            ├─ Species Count: \(speciesCount)
            ├─ Particle Count: \(particleCount)
            ├─ Distribution: \(distributionType)
            ├─ Matrix Type: \(matrixType)
            ├─ Max Distance: \(maxDistance), Min Distance: \(minDistance)
            ├─ Beta: \(beta), Friction: \(friction), Repulsion: \(repulsion)
            ├─ Point Size: \(pointSize), World Size: \(worldSize)
            └─ Built-in: \(isBuiltIn)
            """
    }

    /// Extracts the matrix from `MatrixType` if it's `.custom`
    private var interactionMatrixString: String {
        guard case .custom(let matrix) = matrixType else { return "[]" }

        return "[\n" + matrix
            .map { "        [" + $0.map { String(format: "%.2f", $0) }.joined(separator: ", ") + "]" }
            .joined(separator: ",\n") + "\n    ]"
    }

    /// Returns a string representation of `MatrixType`, handling `.custom` separately
    private var matrixTypeString: String {
        if case .custom = matrixType {
            return ".custom(\(interactionMatrixString))"
        }
        return ".\(matrixType)" // Converts the enum case to a string automatically
    }

    /// Returns a string representation of the preset in Swift code format
    var asCode: String {
        return """
        static let \(name.replacingOccurrences(of: " ", with: "_")) = SimulationPreset(
            name: "\(name)",
            speciesCount: \(speciesCount),
            particleCount: .\(particleCount),
            matrixType: \(matrixTypeString),
            distributionType: .\(distributionType),
            maxDistance: \(String(format: "%.2f", maxDistance)),
            minDistance: \(String(format: "%.2f", minDistance)),
            beta: \(String(format: "%.2f", beta)),
            friction: \(String(format: "%.2f", friction)),
            repulsion: \(String(format: "%.2f", repulsion)),
            pointSize: \(Int(pointSize)),
            worldSize: \(String(format: "%.2f", worldSize)),
            isBuiltIn: \(isBuiltIn)
        )
        """
    }
}

extension SimulationPreset {
    /// Creates a modified copy of the preset, with special handling for custom matrices
    func copy(
        withName newName: String? = nil,
        newSpeciesCount: Int? = nil,
        newParticleCount: ParticleCount? = nil,
        newMatrixType: MatrixType? = nil,
        newDistributionType: DistributionType? = nil,
        newMaxDistance: Float? = nil,
        newMinDistance: Float? = nil,
        newBeta: Float? = nil,
        newFriction: Float? = nil,
        newRepulsion: Float? = nil,
        newPointSize: Float? = nil,
        newWorldSize: Float? = nil,
        newIsBuiltIn: Bool? = nil
    ) -> SimulationPreset {
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
            maxDistance: newMaxDistance ?? maxDistance,
            minDistance: newMinDistance ?? minDistance,
            beta: newBeta ?? beta,
            friction: newFriction ?? friction,
            repulsion: newRepulsion ?? repulsion,
            pointSize: newPointSize ?? pointSize,
            worldSize: newWorldSize ?? worldSize,
            isBuiltIn: newIsBuiltIn ?? isBuiltIn
        )
    }
}
