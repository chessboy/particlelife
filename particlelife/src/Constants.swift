//
//  Contants.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import Foundation

struct Constants {
    static let particleCounts: [Int] = [20480, 30720, 40960, 49152]  // Stable values near 20K, 30K, 40K, 50K
    static let defaultParticleCount = particleCounts[1]  // Default to a stable 40K equivalent
    
    struct Controls {
        static let zoomStep: Float = 1.1
        static let panStep: Float = 0.05
    }
}
