//
//  Particle.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import Foundation
import simd

struct Particle {
    var position: simd_float2
    var velocity: simd_float2
    var species: Int16
    
    static func create(numSpecies: Int) -> Particle {
        var particle = Particle(position: .zero, velocity: .zero, species: 0)
        particle.randomize(numSpecies: numSpecies)
        return particle
    }
    
    mutating func randomize(numSpecies: Int) {
        position = SIMD2<Float>(Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0))
        velocity = SIMD2<Float>(Float.random(in: -0.01...0.01), Float.random(in: -0.01...0.01))
        species = Int16.random(in: 0..<Int16(numSpecies))
    }
}

func generateInteractionMatrix(numSpecies: Int) -> [[Float]] {
    var matrix = [[Float]](repeating: [Float](repeating: 0.0, count: numSpecies), count: numSpecies)

    var attractionTotal: Float = 0.0
    var repulsionTotal: Float = 0.0

    for i in 0..<numSpecies {
        for j in 0..<numSpecies {
            if i == j {
                matrix[i][j] = Float.random(in: 0.3...0.7)  // Self-interaction varies
            } else if j < i {
                matrix[i][j] = matrix[j][i]  // Mirror for symmetry
            } else {
                // Balance attraction and repulsion
                if attractionTotal > abs(repulsionTotal) {
                    matrix[i][j] = Float.random(in: -0.75...0.0)  // Bias toward repulsion
                    repulsionTotal += matrix[i][j]
                } else {
                    matrix[i][j] = Float.random(in: 0.0...0.75)  // Bias toward attraction
                    attractionTotal += matrix[i][j]
                }
            }
        }
    }

    print("🔬 Balanced Matrix - Total Attraction: \(attractionTotal), Total Repulsion: \(repulsionTotal)")
    return matrix
}
