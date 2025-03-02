//
//  MatrixGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//  Adapted from https://github.com/tom-mohr/particle-life-app
//

import Foundation

enum MatrixType: Codable, Hashable, CaseIterable {
    case random
    case randomSymmetry
    case randomWeak
    case chains
    case chains2
    case chains3
    case snakes
    case attractRepelBands
    case custom([[Float]])
    
    var isRandom: Bool {
        switch self {
        case .random, .randomSymmetry, .randomWeak:
            return true
        default:
            return false
        }
    }
    
    static var allCases: [MatrixType] {
        return [.random, .randomSymmetry, .randomWeak, .chains, .chains2, .chains3, .snakes, .attractRepelBands, .custom([[Float]]())]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: MatrixType, rhs: MatrixType) -> Bool {
        return lhs.name == rhs.name
    }
    
    var name: String {
        switch self {
        case .random: return "Random"
        case .randomSymmetry: return "Random Symmetry"
        case .randomWeak: return "Random Weak"
        case .chains: return "Chains"
        case .chains2: return "Chains 2"
        case .chains3: return "Chains 3"
        case .snakes: return "Snakes"
        case .attractRepelBands: return "Bands"
        case .custom: return "Custom"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    /// Returns `true` if the matrix is `.custom` and contains only zeros.
    var isEmptyCustomMatrix: Bool {
        if case let .custom(matrix) = self {
            return matrix.allSatisfy { row in row.allSatisfy { $0 == 0 } }
        }
        return false
    }
}

enum MatrixGenerator {
    
    static func generateMatrix(speciesCount: Int, type: MatrixType) -> [[Float]] {
        Logger.log("Generating matrix: speciesCount: \(speciesCount), type: \(type)", level: .debug)
        
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
                        matrix[i][j] = Float.random(in: -0.2...0.2)
                    } else {
                        matrix[i][j] = 0.0
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


extension MatrixType {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .random:
            try container.encode("random", forKey: .type)
        case .randomWeak:
            try container.encode("randomWeak", forKey: .type)
        case .randomSymmetry:
            try container.encode("symmetry", forKey: .type)
        case .chains:
            try container.encode("chains", forKey: .type)
        case .chains2:
            try container.encode("chains2", forKey: .type)
        case .chains3:
            try container.encode("chains3", forKey: .type)
        case .snakes:
            try container.encode("snakes", forKey: .type)
        case .attractRepelBands:
            try container.encode("attractionRepulsionBands", forKey: .type)
        case .custom(let matrix):
            try container.encode("custom", forKey: .type)
            try container.encode(matrix, forKey: .data)
            
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "random":
            self = .random
        case "randomWeak":
            self = .randomWeak
        case "symmetry":
            self = .randomSymmetry
        case "chains":
            self = .chains
        case "chains2":
            self = .chains2
        case "chains3":
            self = .chains3
        case "snakes":
            self = .snakes
        case "attractionRepulsionBands":
            self = .attractRepelBands
        case "custom":
            let matrix = try container.decode([[Float]].self, forKey: .data)
            self = .custom(matrix)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid MatrixType value")
        }
    }
}
