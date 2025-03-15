//
//  SimulationPreset.swift
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
    let speciesDistribution: SpeciesDistribution
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
    let preservesUISettings: Bool
    let speciesColorOffset: Int
    let paletteIndex: Int
    let colorEffect: ColorEffect

    init(
        id: UUID = UUID(),
        name: String,
        speciesCount: Int,
        particleCount: ParticleCount,
        speciesDistribution: SpeciesDistribution,
        matrixType: MatrixType,
        distributionType: DistributionType,
        maxDistance: Float,
        minDistance: Float,
        beta: Float,
        friction: Float,
        repulsion: Float,
        pointSize: Float,
        worldSize: Float,
        isBuiltIn: Bool = true,
        preservesUISettings: Bool,
        speciesColorOffset: Int,
        paletteIndex: Int,
        colorEffect: ColorEffect
    ) {
        self.id = id
        self.name = name
        self.speciesCount = speciesCount
        self.particleCount = particleCount
        self.speciesDistribution = speciesDistribution
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
        self.preservesUISettings = preservesUISettings
        self.speciesColorOffset = speciesColorOffset
        self.paletteIndex = paletteIndex
        self.colorEffect = colorEffect
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
        lhs.speciesDistribution == rhs.speciesDistribution &&
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
        lhs.preservesUISettings == rhs.preservesUISettings &&
        lhs.speciesColorOffset == rhs.speciesColorOffset &&
        lhs.paletteIndex == rhs.paletteIndex &&
        lhs.colorEffect == rhs.colorEffect
    }
}

extension SimulationPreset: Codable {
    /// Coding keys (needed for custom decoding)
    enum CodingKeys: String, CodingKey {
        case id, name, speciesCount, speciesDistribution, particleCount, matrixType, distributionType
        case maxDistance, minDistance, beta, friction, repulsion
        case pointSize, worldSize, isBuiltIn, preservesUISettings
        case speciesColorOffset, paletteIndex, colorEffect
    }

    /// Custom decoding to handle missing fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // **Ensure UUID is decoded properly, otherwise generate one**
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        speciesCount = try container.decode(Int.self, forKey: .speciesCount)
        particleCount = try container.decode(ParticleCount.self, forKey: .particleCount)

        // Decode species distribution and let `SpeciesDistribution` handle any issues
        let decodedValues = try? container.decode([Float].self, forKey: .speciesDistribution)
        speciesDistribution = SpeciesDistribution(count: speciesCount, initialValues: decodedValues)

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
        preservesUISettings = try container.decode(Bool.self, forKey: .preservesUISettings)
        speciesColorOffset = try container.decode(Int.self, forKey: .speciesColorOffset)
        paletteIndex = try container.decode(Int.self, forKey: .paletteIndex)
        colorEffect = try container.decode(ColorEffect.self, forKey: .colorEffect)
    }
    
    /// Custom encoding (ensures all fields are saved)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)  // **Ensure UUID is saved**
        try container.encode(name, forKey: .name)
        try container.encode(speciesCount, forKey: .speciesCount)
        try container.encode(particleCount, forKey: .particleCount)
        try container.encode(speciesDistribution, forKey: .speciesDistribution)
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
        try container.encode(preservesUISettings, forKey: .preservesUISettings)
        try container.encode(speciesColorOffset, forKey: .speciesColorOffset)
        try container.encode(paletteIndex, forKey: .paletteIndex)
        try container.encode(colorEffect, forKey: .colorEffect)
    }
}

extension SimulationPreset {
        
    var description: String {
            """
            Preset: \(name) (\(id))
            ├─ Species Count: \(speciesCount)
            ├─ Particle Count: \(particleCount)
            ├─ Species Distribution: \(speciesDistribution)
            ├─ Distribution: \(distributionType)
            ├─ Matrix Type: \(matrixType)
            ├─ Max Distance: \(maxDistance), Min Distance: \(minDistance)
            ├─ Beta: \(beta), Friction: \(friction), Repulsion: \(repulsion)
            ├─ Point Size: \(pointSize), World Size: \(worldSize)
            ├─ Built-in: \(isBuiltIn)
            ├─ Preserve UI Settings: \(preservesUISettings)
            ├─ Species Color Offset: \(speciesColorOffset)
            ├─ Palette Index: \(paletteIndex)
            └─ Color Effect: \(colorEffect)
            """
    }
}

extension SimulationPreset {
    
    /// Returns an optimized version of the preset based on GPU capabilities.
    func optimized(for gpuCoreCount: Int) -> SimulationPreset {
        let newParticleCount = particleCount.optimizedParticleCount(for: gpuCoreCount, gpuType: SystemCapabilities.shared.gpuType)
        Logger.log("optimizing: preset \(name), particleCount: \(particleCount) -> newParticleCount: \(newParticleCount)", level: .debug)
        return copy(newParticleCount: newParticleCount)
    }
    
    /// Creates a modified copy of the preset, with special handling for custom matrices
    func copy(
        id: UUID? = nil,
        withName newName: String? = nil,
        newSpeciesCount: Int? = nil,
        newParticleCount: ParticleCount? = nil,
        newSpeciesDistribution: SpeciesDistribution? = nil,
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
        newPreservesUISettings: Bool? = nil,
        newSpeciesColorOffset: Int? = nil,
        newPaletteIndex: Int? = nil,
        newColorEffect: ColorEffect? = nil
    ) -> SimulationPreset {
        
        let updatedId = id ?? self.id
        let updatedName = newName ?? self.name
        let updatedSpeciesCount = newSpeciesCount ?? self.speciesCount
        let updatedParticleCount = newParticleCount ?? self.particleCount
        let updatedSpeciesDistribution = SpeciesDistribution(count: updatedSpeciesCount, initialValues: newSpeciesDistribution?.toArray() ?? self.speciesDistribution.toArray())
        let updatedMatrixType = newMatrixType ?? self.matrixType
        let updatedDistributionType = newDistributionType ?? self.distributionType
        let updatedMaxDistance = newMaxDistance ?? self.maxDistance
        let updatedMinDistance = newMinDistance ?? self.minDistance
        let updatedBeta = newBeta ?? self.beta
        let updatedFriction = newFriction ?? self.friction
        let updatedRepulsion = newRepulsion ?? self.repulsion
        let updatedPointSize = newPointSize ?? self.pointSize
        let updatedWorldSize = newWorldSize ?? self.worldSize
        let updatedIsBuiltIn = newIsBuiltIn ?? self.isBuiltIn
        let updatedPreservesUISettings = newPreservesUISettings ?? self.preservesUISettings
        let updatedSpeciesColorOffset = newSpeciesColorOffset ?? self.speciesColorOffset
        let updatedPaletteIndex = newPaletteIndex ?? self.paletteIndex
        let updatedColorEffect = newColorEffect ?? self.colorEffect
        
        var copiedMatrixType = updatedMatrixType
        if case .custom(let matrix) = copiedMatrixType {
            copiedMatrixType = .custom(matrix.map { $0.map { $0 } })  // Deep copy
        }
        
        return SimulationPreset(
            id: updatedId,
            name: updatedName,
            speciesCount: updatedSpeciesCount,
            particleCount: updatedParticleCount,
            speciesDistribution: updatedSpeciesDistribution,
            matrixType: copiedMatrixType,
            distributionType: updatedDistributionType,
            maxDistance: updatedMaxDistance,
            minDistance: updatedMinDistance,
            beta: updatedBeta,
            friction: updatedFriction,
            repulsion: updatedRepulsion,
            pointSize: updatedPointSize,
            worldSize: updatedWorldSize,
            isBuiltIn: updatedIsBuiltIn,
            preservesUISettings: updatedPreservesUISettings,
            speciesColorOffset: updatedSpeciesColorOffset,
            paletteIndex: updatedPaletteIndex,
            colorEffect: updatedColorEffect
        )
    }
}
