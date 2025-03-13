//
//  ColorEffect.swift
//  particlelife
//
//  Created by Rob Silverman on 3/12/25.
//

import Foundation

enum ColorEffect: Int, CaseIterable, Identifiable {
    case none = 0
    case textured = 1
    case highlight = 2
    case grayscaleSpeed = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .textured: return "Textured"
        case .highlight: return "Highlight"
        case .grayscaleSpeed: return "GraySpeed"
        }
    }
}
