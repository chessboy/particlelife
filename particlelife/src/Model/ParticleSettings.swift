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
    var pointSize: Float             // 4 bytes
    var worldSize: Float             // 4 bytes
    var _padding1: Float = 0         // 4 bytes → align next group

    var speciesColorOffset: UInt32   // 4 bytes
    var paletteIndex: UInt32         // 4 bytes
    var colorEffect: UInt32          // 4 bytes
    var _padding2: UInt32 = 0        // 4 bytes → total = 48 bytes
}

extension ParticleSettings: Equatable {
    static func == (lhs: ParticleSettings, rhs: ParticleSettings) -> Bool {
        return lhs.maxDistance == rhs.maxDistance &&
               lhs.minDistance == rhs.minDistance &&
               lhs.beta == rhs.beta &&
               lhs.friction == rhs.friction &&
               lhs.repulsion == rhs.repulsion &&
               lhs.pointSize == rhs.pointSize &&
               lhs.worldSize == rhs.worldSize &&
               lhs.speciesColorOffset == rhs.speciesColorOffset &&
               lhs.paletteIndex == rhs.paletteIndex &&
               lhs.colorEffect == rhs.colorEffect
    }
}
