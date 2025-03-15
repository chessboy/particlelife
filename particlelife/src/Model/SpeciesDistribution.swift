//
//  SpeciesDistribution.swift
//  particlelife
//
//  Created by Rob Silverman on 3/15/25.
//

import Foundation

struct SpeciesDistribution: Equatable, Codable {
    private var values: [Float] = []

    init(count: Int, initialValues: [Float]? = nil) {
        resize(to: count, with: initialValues)
    }

    /// Returns `true` if the distribution is not even
    var isCustom: Bool {
        guard values.count > 1 else { return false } // Single species is always even
        let evenValue = 1.0 / Float(values.count)
        return values.contains { abs($0 - evenValue) > 0.01 } // Allow minor floating-point variance
    }

    /// Ensures the distribution array has the correct count and sums to 1.0
    mutating func resize(to newCount: Int, with newValues: [Float]? = nil) {
        if let newValues = newValues, newValues.count == newCount {
            let sum = newValues.reduce(0, +)
            values = (sum > 0) ? newValues.map { $0 / sum } : Array(repeating: 1.0 / Float(newCount), count: newCount)
        } else {
            values = Array(repeating: 1.0 / Float(newCount), count: newCount)
        }
    }

    /// Updates a specific species percentage and adjusts others accordingly
    mutating func update(index: Int, newValue: Float) {
        guard values.indices.contains(index) else { return }

        let sumWithoutCurrent = values.enumerated()
            .filter { $0.offset != index }
            .map { $0.element }
            .reduce(0, +)

        let remaining = max(0.0, 1.0 - newValue)
        values[index] = newValue

        if sumWithoutCurrent > 0 {
            for i in 0..<values.count where i != index {
                values[i] = (values[i] / sumWithoutCurrent) * remaining
            }
        } else {
            let evenSplit = remaining / Float(values.count - 1)
            for i in 0..<values.count where i != index {
                values[i] = evenSplit
            }
        }
    }

    /// Returns the distribution array
    func toArray() -> [Float] {
        return values
    }

    /// Allows direct array-like access
    subscript(index: Int) -> Float {
        get { values[index] }
        set { update(index: index, newValue: newValue) }
    }

    /// Custom Decoding: Decode directly as an array
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValues = try container.decode([Float].self)
        resize(to: decodedValues.count, with: decodedValues)
    }

    /// Custom Encoding: Encode directly as an array
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}
