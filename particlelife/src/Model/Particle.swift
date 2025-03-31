//
//  Particle.swift
//  particlelife
//
//  Created by Rob Silverman on 3/2/25.
//

import Foundation
import simd

struct Particle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var species: UInt32
    var _padding: UInt32 = 0
}
