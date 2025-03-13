//
//  ColorEffect.swift
//  particlelife
//
//  Created by Rob Silverman on 3/12/25.
//

import Foundation

enum ColorEffect: UInt32, Codable, CaseIterable, Identifiable {
    case none = 0
    case textured = 1
    case highlights = 2
    case grayHighlights = 3

    var id: UInt32 { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .textured: return "Textured"
        case .highlights: return "Highlights"
        case .grayHighlights: return "Gray Highlights"
        }
    }

    func nextColorEffect(direction: Int = 1) -> ColorEffect {
        let allCases = Self.allCases
        guard let currentIndex = allCases.firstIndex(of: self) else { return self }

        // Wrap around correctly in both directions
        let newIndex = (currentIndex + direction + allCases.count) % allCases.count
        return allCases[newIndex]
    }
}

extension ColorEffect {
    
    var stringValue: String {
        switch self {
        case .none: return "none"
        case .textured: return "textured"
        case .highlights: return "highlights"
        case .grayHighlights: return "grayHighlights"
        }
    }

    init?(stringValue: String) {
        switch stringValue {
        case "none": self = .none
        case "textured": self = .textured
        case "highlights": self = .highlights
        case "grayHighlights": self = .grayHighlights
        default: return nil
        }
    }

    // Custom Encoding: Store as a String in JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }

    // Custom Decoding: Read as String
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        
        if let effect = ColorEffect(stringValue: stringValue) {
            self = effect
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ColorEffect value: \(stringValue)")
        }
    }

}
