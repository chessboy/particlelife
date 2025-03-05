//
//  ParticleType.swift
//  particlelife
//
//  Created by Rob Silverman on 3/2/25.
//

import Foundation

enum ParticleCount: Int, CaseIterable, Identifiable, Codable, Comparable {
    case k1 = 1024
    case k2 = 2048
    case k5 = 5120
    case k10 = 10240
    case k20 = 20480
    case k30 = 30720
    case k35 = 35840
    case k40 = 40960
    case k45 = 46080
    
    var id: Int { self.rawValue }
    
    var displayString: String {
        switch self {
        case .k1: return "1K"
        case .k2: return "2K"
        case .k5: return "5K"
        case .k10: return "10K"
        case .k20: return "20K"
        case .k30: return "30K"
        case .k35: return "35K"
        case .k40: return "40K"
        case .k45: return "45K"
        }
    }
    
    init(rawValue: Int) {
        self = ParticleCount.allCases.first(where: { $0.rawValue == rawValue }) ?? .k1
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let intValue = try container.decode(Int.self)
        self = ParticleCount(rawValue: intValue)
    }
    
    static func < (lhs: ParticleCount, rhs: ParticleCount) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    static var allCases: [ParticleCount] {
        return [.k1, .k2, .k5, .k10, .k20, .k30, .k35, .k40, .k45]
    }
    
    /// Returns the recommended particle count based on species count, **then optimizes it for the user's GPU**.
    static func particles(for speciesCount: Int, gpuCoreCount: Int, gpuType: GPUType) -> ParticleCount {
        guard (1...9).contains(speciesCount) else { return .k1 }
        
        // Initial species-based mapping
        let baseMapping: [Int: ParticleCount] = [
            1: .k10,
            2: .k10,
            3: .k20,
            4: .k20,
            5: .k20,
            6: .k30,
            7: .k35,
            8: .k35,
            9: .k40
        ]
        
        let baseCount = baseMapping[speciesCount] ?? .k10
        return baseCount.optimizedParticleCount(for: gpuCoreCount, gpuType: gpuType)
    }
    
    func optimizedParticleCount(for gpuCoreCount: Int, gpuType: GPUType) -> ParticleCount {
        let maxAllowed: ParticleCount
        
        if gpuType == .dedicatedGPU {
            maxAllowed = .k45  // Always allow full 45K for dedicated GPUs
        } else if gpuCoreCount >= 30 {
            maxAllowed = .k35  // High-end integrated GPUs → 35K
        } else if gpuCoreCount >= 16 {
            maxAllowed = .k30  // Mid-tier GPUs → 30K
        } else if gpuCoreCount >= 10 {
            maxAllowed = .k20  // Lower-end GPUs → 20K
        } else {
            maxAllowed = .k10  // Anything weaker → 10K
        }
        
        return self.capped(at: maxAllowed)
    }
    
    /// Ensures particle count does not exceed `maxAllowed`.
    func capped(at maxAllowed: ParticleCount) -> ParticleCount {
        switch self {
        case .k1, .k2: return self
        case .k5: return .k2
        case .k10: return .k5
        case .k20, .k30: return .k10
        case .k35, .k40, .k45: return maxAllowed  // Apply GPU-based max cap
        }
    }
}
