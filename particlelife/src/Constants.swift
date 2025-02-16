//
//  Contants.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import SwiftUI

struct Constants {
    
    static let numSpecies: Int = 6 // max 9
    
    static let particleCounts: [Int] = [1024, 2048, 5120, 10240, 20480, 30720, 40960, 49152]  // Stable values near 20K, 30K, 40K, 50K
    static let defaultParticleCount = particleCounts[6]  // Default to a stable equivalent
    
    static let speciesColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple,
        Color(red: 0.0, green: 1.0, blue: 1.0), // Cyan
        Color(red: 1.0, green: 0.0, blue: 1.0), // Magenta
        .white // White
    ]
    
    struct Controls {
        static let zoomStep: Float = 1.1
        static let panStep: Float = 0.05
    }
}
