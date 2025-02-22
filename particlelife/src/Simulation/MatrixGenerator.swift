//
//  MatrixGenerator.swift
//  particlelife
//
//  Created by Rob Silverman on 2/16/25.
//  Adapted from https://github.com/tom-mohr/particle-life-app
//

import Foundation

enum MatrixType: Codable {
    case random
    case symmetry
    case chains
    case chains2
    case chains3
    case snakes
    case zero
    case custom([[Float]])
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }
}

enum MatrixGenerator {
    
    static func generateInteractionMatrix(speciesCount: Int, type: MatrixType) -> [[Float]] {
        var matrix = [[Float]](repeating: [Float](repeating: 0.0, count: speciesCount), count: speciesCount)
        
        switch type {
            
        case .random:
            for i in 0..<speciesCount {
                for j in 0..<speciesCount {
                    matrix[i][j] = Float.random(in: -1.0...1.0)
                }
            }
            
        case .symmetry:
            for i in 0..<speciesCount {
                for j in i..<speciesCount {
                    matrix[i][j] = Float.random(in: -1.0...1.0)
                    matrix[j][i] = matrix[i][j]  // Make it symmetric
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
            
        case .zero:
            // Already initialized with all zeros.
            break
            
        case .custom(let matrix):
            return matrix
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
        case .symmetry:
            try container.encode("symmetry", forKey: .type)
        case .chains:
            try container.encode("chains", forKey: .type)
        case .chains2:
            try container.encode("chains2", forKey: .type)
        case .chains3:
            try container.encode("chains3", forKey: .type)
        case .snakes:
            try container.encode("snakes", forKey: .type)
        case .zero:
            try container.encode("zero", forKey: .type)
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
        case "symmetry":
            self = .symmetry
        case "chains":
            self = .chains
        case "chains2":
            self = .chains2
        case "chains3":
            self = .chains3
        case "snakes":
            self = .snakes
        case "zero":
            self = .zero
        case "custom":
            let matrix = try container.decode([[Float]].self, forKey: .data)
            self = .custom(matrix)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid MatrixType value")
        }
    }
}
