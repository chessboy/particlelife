//
//  ParticleType.swift
//  particlelife
//
//  Created by Rob Silverman on 3/2/25.
//

import Foundation

enum ParticleCount: Int, CaseIterable, Identifiable, Codable {
    case k1 = 1024
    case k2 = 2048
    case k5 = 5120
    case k10 = 10240
    case k20 = 20480
    case k30 = 30720
    case k35 = 35840
    case k40 = 40960
    case k45 = 46080
    case k50 = 51200
    
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
        case .k50: return "50K"
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    static var allCases: [ParticleCount] {
        return [.k1, .k2, .k5, .k10, .k20, .k30, .k35, .k40, .k45, .k50]
    }

    /// Returns the particle count for a given species count (1-9).
    static func particles(for speciesCount: Int) -> ParticleCount {
        guard (1...9).contains(speciesCount) else { return k1 }

        // Map species count to an increasing particle count
        let mapping: [Int: ParticleCount] = [
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

        return mapping[speciesCount] ?? .k10
    }
}
