//
//  SpeciesColor.swift
//  particlelife
//
//  Created by Rob Silverman on 2/26/25.
//

import SwiftUI

enum SpeciesPalette: Int, CaseIterable {
    case classic = 0
    case muted
    case dark
    case alt
    case vivid

    static let colorCount = 9

    var colors: [Color] {
        switch self {
        case .classic:
            return [
                Color(red: 1.0, green: 0.2, blue: 0.2),   // 🔴 Soft Red
                Color(red: 1.0, green: 0.6, blue: 0.0),   // 🟠 Orange
                Color(red: 0.95, green: 0.95, blue: 0.0), // 🟡 Warm Yellow
                Color(red: 0.0, green: 0.8, blue: 0.2),   // 🟢 Green
                Color(red: 0.0, green: 0.4, blue: 1.0),   // 🔵 Bright Blue
                Color(red: 0.6, green: 0.2, blue: 1.0),   // 🟣 Purple
                Color(red: 0.0, green: 1.0, blue: 1.0),   // 🔵 Cyan
                Color(red: 1.0, green: 0.0, blue: 0.6),   // 💖 Hot Pink
                Color(red: 0.2, green: 0.8, blue: 0.6)    // 🌊 Teal
            ]
        case .muted:
            return [
                Color(red: 0.9, green: 0.5, blue: 0.4),   // 🍂 Rust
                Color(red: 0.8, green: 0.7, blue: 0.5),   // 🌾 Wheat
                Color(red: 0.4, green: 0.6, blue: 0.3),   // 🌲 Forest Green
                Color(red: 0.2, green: 0.5, blue: 0.7),   // 🌊 Deep Teal
                Color(red: 0.8, green: 0.3, blue: 0.4),   // 🍓 Soft Berry
                Color(red: 0.6, green: 0.4, blue: 0.2),   // 🪵 Walnut Brown
                Color(red: 0.7, green: 0.7, blue: 0.5),   // 🌰 Olive
                Color(red: 0.4, green: 0.3, blue: 0.6),   // 🍇 Plum
                Color(red: 0.3, green: 0.4, blue: 0.5)    // ⛈ Stormy Blue
            ]
        case .dark:
            return [
                Color(red: 0.2, green: 0.5, blue: 0.3),   // 🍞 Moldy Green-Blue
                Color(red: 0.25, green: 0.05, blue: 0.5), // 🔮 Dark Purple
                Color(red: 0.4, green: 0.05, blue: 0.75), // 🟣 Electric Violet
                Color(red: 0.0, green: 0.4, blue: 0.8),   // 🔵 Deep Ocean Blue
                Color(red: 0.1, green: 0.6, blue: 0.3),   // 🌿 Muted Teal Green
                Color(red: 0.6, green: 0.8, blue: 0.2),   // 💛 Vibrant Chartreuse
                Color(red: 0.9, green: 0.9, blue: 0.2),   // ⚡ Soft Glow Yellow
                Color(red: 0.6, green: 0.3, blue: 0.7),   // 🔮 Dim Lavender
                Color(red: 0.2, green: 0.2, blue: 0.2)    // ⚫ Charcoal Grey
            ]
        case .alt:
            return [
                Color(red: 0.95, green: 0.35, blue: 0.35), // 🍓 Soft Strawberry
                Color(red: 1.0, green: 0.55, blue: 0.15),  // 🍊 Sunset Orange
                Color(red: 1.0, green: 0.85, blue: 0.3),   // 🍋 Lemon Gold
                Color(red: 0.3, green: 0.8, blue: 0.4),    // 🌿 Leaf Green
                Color(red: 0.3, green: 0.6, blue: 1.0),    // 🌊 Sky Blue
                Color(red: 0.7, green: 0.4, blue: 1.0),    // 🎆 Soft Lavender
                Color(red: 0.2, green: 0.9, blue: 0.9),    // 🌴 Aqua Green
                Color(red: 1.0, green: 0.3, blue: 0.7),    // 🌸 Cherry Blossom
                Color(red: 0.3, green: 0.85, blue: 0.7)    // 🦜 Mint Teal
            ]
        case .vivid:
            return [
                Color(red: 1.0, green: 0.0, blue: 0.0),   // 🔥 Pure Red
                Color(red: 1.0, green: 0.5, blue: 0.0),   // 🧡 Neon Orange
                Color(red: 1.0, green: 1.0, blue: 0.0),   // ⚡ Electric Yellow
                Color(red: 0.0, green: 1.0, blue: 0.0),   // 🍀 Vivid Green
                Color(red: 0.0, green: 1.0, blue: 1.0),   // 💎 Neon Cyan
                Color(red: 0.0, green: 0.0, blue: 1.0),   // 🔵 Ultra Blue
                Color(red: 0.6, green: 0.0, blue: 1.0),   // 🔮 Deep Violet
                Color(red: 1.0, green: 0.0, blue: 1.0),   // 💜 Hyper Magenta
                Color(red: 1.0, green: 0.0, blue: 0.5)    // 💖 Hot Raspberry
            ]
        }
    }

    var name: String {
        switch self {
        case .classic: return "Classic"
        case .muted: return "Muted"
        case .dark: return "Dark"
        case .alt: return "Alt"
        case .vivid: return "Vivid"
        }
    }
}
