//
//  SettingsGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//

import Foundation

struct SimulationPreset: Identifiable {
    let id: UUID
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
    let shouldResetEverything: Bool
    let speciesColorOffset: Int

    init(
        id: UUID = UUID(),
        name: String,
        speciesCount: Int,
        particleCount: ParticleCount,
        matrixType: MatrixType,
        distributionType: DistributionType,
        maxDistance: Float,
        minDistance: Float,
        beta: Float,
        friction: Float,
        repulsion: Float,
        pointSize: Float,
        worldSize: Float,
        isBuiltIn: Bool,
        shouldResetEverything: Bool,
        speciesColorOffset: Int
    ) {
        self.id = id
        self.name = name
        self.speciesCount = speciesCount
        self.particleCount = particleCount
        self.matrixType = matrixType
        self.distributionType = distributionType
        self.maxDistance = maxDistance
        self.minDistance = minDistance
        self.beta = beta
        self.friction = friction
        self.repulsion = repulsion
        self.pointSize = pointSize
        self.worldSize = worldSize
        self.isBuiltIn = isBuiltIn
        self.shouldResetEverything = shouldResetEverything
        self.speciesColorOffset = speciesColorOffset
    }
}

extension SimulationPreset: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: SimulationPreset, rhs: SimulationPreset) -> Bool {
        return lhs.name == rhs.name &&
        lhs.speciesCount == rhs.speciesCount &&
        lhs.particleCount == rhs.particleCount &&
        lhs.matrixType == rhs.matrixType &&
        lhs.distributionType == rhs.distributionType &&
        lhs.maxDistance == rhs.maxDistance &&
        lhs.minDistance == rhs.minDistance &&
        lhs.beta == rhs.beta &&
        lhs.friction == rhs.friction &&
        lhs.repulsion == rhs.repulsion &&
        lhs.pointSize == rhs.pointSize &&
        lhs.worldSize == rhs.worldSize &&
        lhs.isBuiltIn == rhs.isBuiltIn &&
        lhs.shouldResetEverything == rhs.shouldResetEverything &&
        lhs.speciesColorOffset == rhs.speciesColorOffset
    }
}

extension SimulationPreset: Codable {
    /// Coding keys (needed for custom decoding)
    enum CodingKeys: String, CodingKey {
        case id, name, speciesCount, particleCount, matrixType, distributionType
        case maxDistance, minDistance, beta, friction, repulsion
        case pointSize, worldSize, isBuiltIn, shouldResetEverything, speciesColorOffset
    }

    /// Custom decoding to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // **Ensure UUID is decoded properly, otherwise generate one**
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        speciesCount = try container.decode(Int.self, forKey: .speciesCount)
        particleCount = try container.decode(ParticleCount.self, forKey: .particleCount)
        matrixType = try container.decode(MatrixType.self, forKey: .matrixType)
        distributionType = try container.decode(DistributionType.self, forKey: .distributionType)
        maxDistance = try container.decode(Float.self, forKey: .maxDistance)
        minDistance = try container.decode(Float.self, forKey: .minDistance)
        beta = try container.decode(Float.self, forKey: .beta)
        friction = try container.decode(Float.self, forKey: .friction)
        repulsion = try container.decode(Float.self, forKey: .repulsion)
        pointSize = try container.decode(Float.self, forKey: .pointSize)
        worldSize = try container.decode(Float.self, forKey: .worldSize)
        isBuiltIn = try container.decode(Bool.self, forKey: .isBuiltIn)
        shouldResetEverything = try container.decode(Bool.self, forKey: .shouldResetEverything)
        speciesColorOffset = try container.decode(Int.self, forKey: .speciesColorOffset)
    }

    /// Custom encoding (ensures all fields are saved)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)  // **Ensure UUID is saved**
        try container.encode(name, forKey: .name)
        try container.encode(speciesCount, forKey: .speciesCount)
        try container.encode(particleCount, forKey: .particleCount)
        try container.encode(matrixType, forKey: .matrixType)
        try container.encode(distributionType, forKey: .distributionType)
        try container.encode(maxDistance, forKey: .maxDistance)
        try container.encode(minDistance, forKey: .minDistance)
        try container.encode(beta, forKey: .beta)
        try container.encode(friction, forKey: .friction)
        try container.encode(repulsion, forKey: .repulsion)
        try container.encode(pointSize, forKey: .pointSize)
        try container.encode(worldSize, forKey: .worldSize)
        try container.encode(isBuiltIn, forKey: .isBuiltIn)
        try container.encode(shouldResetEverything, forKey: .shouldResetEverything)
        try container.encode(speciesColorOffset, forKey: .speciesColorOffset)
    }
}

extension SimulationPreset {
    
    var description: String {
            """
            Preset: \(name) (\(id))
            ├─ Species Count: \(speciesCount)
            ├─ Particle Count: \(particleCount)
            ├─ Distribution: \(distributionType)
            ├─ Matrix Type: \(matrixType)
            ├─ Max Distance: \(maxDistance), Min Distance: \(minDistance)
            ├─ Beta: \(beta), Friction: \(friction), Repulsion: \(repulsion)
            ├─ Point Size: \(pointSize), World Size: \(worldSize)
            └─ Built-in: \(isBuiltIn)
            └─ Should Reset SpeciesCount: \(shouldResetEverything)
            └─ Species Color Offset: \(speciesColorOffset)
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
        static let \(name.camelCase()) = SimulationPreset(
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
            isBuiltIn: \(isBuiltIn),
            shouldResetEverything: \(shouldResetEverything),
            speciesColorOffset: \(speciesColorOffset)
        )
        """
    }
}

extension SimulationPreset {
    /// Creates a modified copy of the preset, with special handling for custom matrices
    func copy(
        id: UUID? = nil,  // Allow overriding the UUID (default = keep original)
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
        newIsBuiltIn: Bool? = nil,
        newShouldResetEverything: Bool? = nil,
        newSpeciesColorOffset: Int? = nil
    ) -> SimulationPreset {
        var copiedMatrixType = newMatrixType ?? matrixType  // Use new matrix if provided
        
        // Ensure deep copy of custom matrices
        if case .custom(let matrix) = copiedMatrixType {
            copiedMatrixType = .custom(matrix.map { $0.map { $0 } })  // Deep copy
        }
        
        return SimulationPreset(
            id: id ?? self.id,  // Preserve existing UUID unless explicitly changed
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
            isBuiltIn: newIsBuiltIn ?? isBuiltIn,
            shouldResetEverything: newShouldResetEverything ?? shouldResetEverything,
            speciesColorOffset: newSpeciesColorOffset ?? speciesColorOffset
        )
    }
}
