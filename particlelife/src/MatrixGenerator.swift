//
//  MatrixGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//

import Foundation

enum MatrixType {
    case random
    case symmetry
    case chains
    case chains2
    case chains3
    case snakes
    case zero
}

enum MatrixGenerator {
    
    static func generateInteractionMatrix(numSpecies: Int, type: MatrixType) -> [[Float]] {
        var matrix = [[Float]](repeating: [Float](repeating: 0.0, count: numSpecies), count: numSpecies)
        
        switch type {
            
        case .random:
            for i in 0..<numSpecies {
                for j in 0..<numSpecies {
                    matrix[i][j] = Float.random(in: -1.0...1.0)
                }
            }
            
        case .symmetry:
            for i in 0..<numSpecies {
                for j in i..<numSpecies {
                    matrix[i][j] = Float.random(in: -1.0...1.0)
                    matrix[j][i] = matrix[i][j]  // Make it symmetric
                }
            }
            
        case .chains:
            for i in 0..<numSpecies {
                for j in 0..<numSpecies {
                    if j == i || j == (i + 1) % numSpecies || j == (i + numSpecies - 1) % numSpecies {
                        matrix[i][j] = 1.0  // Strong attraction to neighbors
                    } else {
                        matrix[i][j] = -1.0 // Repulsion for non-neighbors
                    }
                }
            }
            
        case .chains2:
            for i in 0..<numSpecies {
                for j in 0..<numSpecies {
                    if j == i {
                        matrix[i][j] = 1.0
                    } else if j == (i + 1) % numSpecies || j == (i + numSpecies - 1) % numSpecies {
                        matrix[i][j] = 0.2  // Weak attraction to neighbors
                    } else {
                        matrix[i][j] = -1.0 // Strong repulsion
                    }
                }
            }
            
        case .chains3:
            for i in 0..<numSpecies {
                for j in 0..<numSpecies {
                    if j == i {
                        matrix[i][j] = 1.0
                    } else if j == (i + 1) % numSpecies || j == (i + numSpecies - 1) % numSpecies {
                        matrix[i][j] = 0.2  // Slight attraction to neighbors
                    } else {
                        matrix[i][j] = 0.0  // Neutral interaction
                    }
                }
            }
            
        case .snakes:
            for i in 0..<numSpecies {
                matrix[i][i] = 1.0 // Strong self-attraction
                matrix[i][(i + 1) % numSpecies] = 0.2 // Weak attraction to the next species
            }
            
        case .zero:
            // Already initialized with all zeros.
            break
        }
        
        return matrix
    }
}
