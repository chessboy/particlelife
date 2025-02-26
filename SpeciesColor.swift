//
//  SpeciesColor.swift
//  particlelife
//
//  Created by Rob Silverman on 2/26/25.
//

import SwiftUI

struct SpeciesColor {
    
    static let speciesColors: [Color] = [
        Color(red: 1.0, green: 0.2, blue: 0.2),    // 🔴 Soft Red
        Color(red: 1.0, green: 0.6, blue: 0.0),    // 🟠 Orange
        Color(red: 0.95, green: 0.95, blue: 0.0),  // 🟡 Warm Yellow
        Color(red: 0.0, green: 0.8, blue: 0.2),    // 🟢 Green
        Color(red: 0.0, green: 0.4, blue: 1.0),    // 🔵 Bright Blue
        Color(red: 0.6, green: 0.2, blue: 1.0),    // 🟣 Purple
        Color(red: 0.0, green: 1.0, blue: 1.0),    // 🔵 Cyan
        Color(red: 1.0, green: 0.0, blue: 0.6),    // 💖 Hot Pink
        Color(red: 0.2, green: 0.8, blue: 0.6)     // 🌊 Teal
    ]
    
    static func speciesColor(for species: Int, offset: Int = 0) -> Color {
        let adjustedSpecies = (species + offset) % speciesColors.count
        return speciesColors[adjustedSpecies]
    }
    
    static func speciesColorsWithOffset(_ offset: Int = 0) -> [Color] {
        let count = speciesColors.count
        return (0..<count).map { speciesColors[($0 + offset) % count] }
    }
}
