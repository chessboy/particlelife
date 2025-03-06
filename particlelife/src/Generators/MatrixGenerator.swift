//
//  MatrixGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//  Adapted from https://github.com/tom-mohr/particle-life-app
//

import Foundation

enum MatrixGenerator {
    
    static func generateMatrix(speciesCount: Int, type: MatrixType) -> [[Float]] {
        Logger.log("Generating matrix: speciesCount: \(speciesCount), type: \(type.shortString)", level: .debug)
        
        var matrix = [[Float]](repeating: [Float](repeating: 0.0, count: speciesCount), count: speciesCount)
        
        switch type {
            
        case .random:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    matrix[i][j] = Float.random(in: -1.0...1.0)
                }
            }
            
        case .randomSymmetry:
            for i in 0..<speciesCount {
                for j in i..<speciesCount {
                    matrix[i][j] = Float.random(in: -1.0...1.0)
                    matrix[j][i] = matrix[i][j]  // Make it symmetric
                }
            }
            
        case .randomWeak:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    if .oneIn(2) {
                        matrix[i][j] = 0.0
                    } else {
                        matrix[i][j] = Float.random(in: -0.2...0.2)
                    }
                }
            }
            
        case .randomStrong:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    if .oneIn(3) {
                        matrix[i][j] = 0.0
                    } else if .oneIn(2) {
                        matrix[i][j] = Float.random(in: 0.8 ... 1)
                    } else {
                        matrix[i][j] = Float.random(in: -1 ... -0.8)
                    }
                }
            }

        case .chains:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    if j == i || j == (i + 1) % speciesCount || j == (i + speciesCount - 1) % speciesCount {
                        matrix[i][j] = 1.0  // Strong attraction to neighbors
                    } else {
                        matrix[i][j] = -1.0 // Repulsion for non-neighbors
                    }
                }
            }
            
        case .chains2:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    if j == i {
                        matrix[i][j] = 1.0
                    } else if j == (i + 1) % speciesCount || j == (i + speciesCount - 1) % speciesCount {
                        matrix[i][j] = 0.2  // Weak attraction to neighbors
                    } else {
                        matrix[i][j] = -1.0 // Strong repulsion
                    }
                }
            }
            
        case .chains3:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    if j == i {
                        matrix[i][j] = 1.0
                    } else if j == (i + 1) % speciesCount || j == (i + speciesCount - 1) % speciesCount {
                        matrix[i][j] = 0.2  // Slight attraction to neighbors
                    } else {
                        matrix[i][j] = 0.0  // Neutral interaction
                    }
                }
            }
            
        case .snakes:
            for i in 0..<speciesCount {
                matrix[i][i] = 1.0 // Strong self-attraction
                matrix[i][(i + 1) % speciesCount] = 0.2 // Weak attraction to the next species
            }
            
            // new ones
        case .attractRepelBands:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    if i == j {
                        matrix[i][j] = 1.0  // Strong self-attraction
                    } else if j == (i + 1) % speciesCount || j == (i + speciesCount - 1) % speciesCount {
                        matrix[i][j] = 0.5  // Moderate attraction to nearest neighbors
                    } else if j == (i + 2) % speciesCount || j == (i + speciesCount - 2) % speciesCount {
                        matrix[i][j] = 0.2  // Weak attraction to next-nearest neighbors
                    } else {
                        matrix[i][j] = -0.8 // Strong repulsion to everything else
                    }
                }
            }
        case .custom(let matrix):
            let currentSize = matrix.count
            if currentSize != speciesCount {
                Logger.log("Resizing custom matrix from \(currentSize) to \(speciesCount)", level: .debug)
                
                var newMatrix = [[Float]](repeating: [Float](repeating: 0.0, count: speciesCount), count: speciesCount)
                
                // Copy existing values into the new matrix, keeping as much data as possible
                let minSize = min(currentSize, speciesCount)
                for i in 0..<minSize {
                    for j in 0..<minSize {
                        newMatrix[i][j] = matrix[i][j]
                    }
                }
                return newMatrix
            }
            
            return matrix // If speciesCount is unchanged, return as is
        }
        
        return matrix
    }
}
