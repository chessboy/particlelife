//
//  Particle.swift
//  particlelife
//
//  Created by Rob Silverman on 3/2/25.
//

import Foundation
import simd

struct Particle {
    var position: simd_float2
    var velocity: simd_float2
    var species: Int32
}
