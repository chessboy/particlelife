//
//  DistributionType.swift
//  particlelife
//
//  Created by Rob Silverman on 3/2/25.
//

import Foundation

enum DistributionType: Codable, CaseIterable {
    case perlinNoise, centered, uniform, uniformCircle,
         centeredCircle, ring, rainbowRing, line,
         colorBattle, colorWheel, colorBands, spiral, rainbowSpiral
    
    /// Determines if the distribution should be recentered after generation
    var shouldRecenter: Bool {
        switch self {
        case .centered, .uniform, .colorBands, .line, .perlinNoise:
            return true
        default:
            return false
        }
    }

    /// Determines if the distribution should scale to maintain aspect ratio
    var shouldScaleToAspectRatio: Bool {
        switch self {
        case .uniform, .line, .colorBands, .perlinNoise:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .centered: return "Centered"
        case .uniform: return "Uniform"
        case .uniformCircle: return "Uniform Circle"
        case .centeredCircle: return "Centered Circle"
        case .ring: return "Ring"
        case .rainbowRing: return "Rainbow Ring"
        case .colorBattle: return "Color Battle"
        case .colorWheel: return "Color Wheel"
        case .colorBands: return "Color Bands"
        case .line: return "Line"
        case .spiral: return "Spiral"
        case .rainbowSpiral: return "Rainbow Spiral"
        case .perlinNoise: return "Perlin Noise"
        }
    }
}

extension DistributionType {
    var rawValue: String {
        switch self {
        case .centered: return "centered"
        case .uniform: return "uniform"
        case .uniformCircle: return "uniformCircle"
        case .centeredCircle: return "centeredCircle"
        case .ring: return "ring"
        case .rainbowRing: return "rainbowRing"
        case .colorBattle: return "colorBattle"
        case .colorWheel: return "colorWheel"
        case .colorBands: return "colorBands"
        case .line: return "line"
        case .spiral: return "spiral"
        case .rainbowSpiral: return "rainbowSpiral"
        case .perlinNoise: return "perlinNoise"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "centered": self = .centered
        case "uniform": self = .uniform
        case "uniformCircle": self = .uniformCircle
        case "centeredCircle": self = .centeredCircle
        case "ring": self = .ring
        case "rainbowRing": self = .rainbowRing
        case "colorBattle": self = .colorBattle
        case "colorWheel": self = .colorWheel
        case "colorBands": self = .colorBands
        case "line": self = .line
        case "spiral": self = .spiral
        case "rainbowSpiral": self = .rainbowSpiral
        case "perlinNoise": self = .perlinNoise
        default: return nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue) // Always encode as a string
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Attempt to decode as a string (correct format)
        if let stringValue = try? container.decode(String.self),
           let value = DistributionType(rawValue: stringValue) {
            self = value
            return
        }

        // If it's a dictionary (legacy format), extract key
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try keyedContainer.decode(String.self, forKey: .type)

        if let value = DistributionType(rawValue: typeString) {
            self = value
        } else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: keyedContainer, debugDescription: "Invalid DistributionType format")
        }
    }
}
