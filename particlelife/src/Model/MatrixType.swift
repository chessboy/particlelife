//
//  MatrixType.swift
//  particlelife
//
//  Created by Rob Silverman on 3/2/25.
//

enum MatrixType: Codable, Hashable, CaseIterable {
    case random
    case randomSymmetry
    case randomWeak
    case randomStrong
    case chains
    case chains2
    case chains3
    case snakes
    case attractRepelBands
    case custom([[Float]])
    
    var isRandom: Bool {
        switch self {
        case .random, .randomSymmetry, .randomWeak, .randomStrong:
            return true
        default:
            return false
        }
    }
    
    static var allCases: [MatrixType] {
        return [.random, .randomSymmetry, .randomWeak, .randomStrong, .chains, .chains2, .chains3, .snakes, .attractRepelBands, .custom([[Float]]())]
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
        case .randomSymmetry: return "Random Symmetrical"
        case .randomWeak: return "Random Weak"
        case .randomStrong: return "Random Strong"
        case .chains: return "Chains"
        case .chains2: return "Chains 2"
        case .chains3: return "Chains 3"
        case .snakes: return "Snakes"
        case .attractRepelBands: return "Bands"
        case .custom: return "Custom"
        }
    }
    
    /// Returns `true` if the matrix is `.custom` and contains only zeros.
    var isEmptyCustomMatrix: Bool {
        if case let .custom(matrix) = self {
            return matrix.allSatisfy { row in row.allSatisfy { $0 == 0 } }
        }
        return false
    }
    
    var shortString: String {
        switch self {
        case .custom(let matrix):
            let size = "\(matrix.count)x\(matrix.first?.count ?? 0)"
            if matrix.count == 1, let singleValue = matrix.first?.first {
                return "custom(\(size), \(String(format: "%.2f", singleValue)))"  // 1x1 case
            } else if let first = matrix.first?.first, let last = matrix.last?.last {
                return "custom(\(size), \(String(format: "%.2f", first)), ..., \(String(format: "%.2f", last)))"
            }
            return "custom(\(size), empty)"  // Empty matrix
        default:
            return "\(self)"  // Default case returns the enum case name
        }
    }
}

extension MatrixType {
    
    private enum CodingKeys: String, CodingKey {
        case type, data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .random:
            try container.encode("random", forKey: .type)
        case .randomWeak:
            try container.encode("randomWeak", forKey: .type)
        case .randomStrong:
            try container.encode("randomStrong", forKey: .type)
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
        case "randomStrong":
            self = .randomStrong
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
