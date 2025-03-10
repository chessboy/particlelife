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
    case k25 = 24576
    case k30 = 30720
    case k35 = 35840
    case k40 = 40960
    
    static var maxParticleCount: ParticleCount = .k40
    
    var id: Int { self.rawValue }
    
    var displayString: String {
        switch self {
        case .k1: return "1K"
        case .k2: return "2K"
        case .k5: return "5K"
        case .k10: return "10K"
        case .k20: return "20K"
        case .k25: return "25K"
        case .k30: return "30K"
        case .k35: return "35K"
        case .k40: return "40K"
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
        return [.k1, .k2, .k5, .k10, .k20, .k25, .k30, .k35, .k40]
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
            6: .k25,
            7: .k25,
            8: .k30,
            9: .k30
        ]
        
        let baseCount = baseMapping[speciesCount] ?? .k10
        return baseCount.optimizedParticleCount(for: gpuCoreCount, gpuType: gpuType)
    }
    
    func optimizedParticleCount(for gpuCoreCount: Int, gpuType: GPUType) -> ParticleCount {
        let maxAllowed: ParticleCount
        
        if gpuType == .cpuOnly {
            maxAllowed = .k10  // CPU-only capped at `k10`
        } else if gpuType == .dedicatedGPU {
            if gpuCoreCount >= 30 {
                maxAllowed = .k40  // M2 Max (30-38 cores)
            } else if gpuCoreCount >= 16 {
                maxAllowed = .k35  // M2 Pro-like chips
            } else if gpuCoreCount >= 10 {
                maxAllowed = .k25  // Mid-tier dedicated GPUs (e.g., base M2 with better thermals)
            } else if gpuCoreCount >= 8 {
                maxAllowed = .k20  // Base M2 (10-core)
            } else {
                maxAllowed = .k10  // Catch-all for anything weaker
            }
        } else { // Integrated GPUs
            if gpuCoreCount >= 30 {
                maxAllowed = .k35
            } else if gpuCoreCount >= 16 {
                maxAllowed = .k30
            } else if gpuCoreCount >= 10 {
                maxAllowed = .k25
            } else if gpuCoreCount >= 8 {
                maxAllowed = .k20
            } else {
                maxAllowed = .k10
            }
        }
        
        let optimizedCount = min(self, maxAllowed)
        //Logger.log("Optimizing \(self) ➝ \(optimizedCount)", level: .debug)
        return optimizedCount
    }
    
    /// Returns the next higher ParticleCount, clamping at `.k40`
    var next: ParticleCount {
        let allCases = ParticleCount.allCases

        if let currentIndex = ParticleCount.allCases.firstIndex(of: self), currentIndex + 1 < allCases.count {
            return allCases[currentIndex + 1]
        }

        return .maxParticleCount // Clamp at max
    }

    static func maxAllowedParticleCount(for gpuCoreCount: Int, gpuType: GPUType, allowExtra: Bool = false) -> ParticleCount {
        let baseMax = ParticleCount.maxParticleCount.optimizedParticleCount(for: gpuCoreCount, gpuType: gpuType)
        return allowExtra ? baseMax.next : baseMax
    }
}
