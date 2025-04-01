//
//  Settings.swift
//  particlelife
//
//  Created by Rob Silverman on 3/31/25.
//

import Foundation
import simd

struct ParticleSettings {
    var maxDistance: Float           // 4 bytes
    var minDistance: Float           // 4 bytes
    var beta: Float                  // 4 bytes
    var friction: Float              // 4 bytes
    var repulsion: Float             // 4 bytes
    var worldSize: Float             // 4 bytes
    var _padding1: SIMD2<Float> = .zero // 8 bytes → total = 32 bytes
}

extension ParticleSettings: Equatable {
    static func == (lhs: ParticleSettings, rhs: ParticleSettings) -> Bool {
        return lhs.maxDistance == rhs.maxDistance &&
               lhs.minDistance == rhs.minDistance &&
               lhs.beta == rhs.beta &&
               lhs.friction == rhs.friction &&
               lhs.repulsion == rhs.repulsion &&
               lhs.worldSize == rhs.worldSize
    }
}
