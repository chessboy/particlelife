//
//  String+Extensions.swift
//  particlelife
//
//  Created by Rob Silverman on 2/23/25.
//

import Foundation

extension String {
    /// Converts a string to camelCase, removing spaces.
    func camelCase() -> String {
        let components = self.split(separator: " ")
        guard let first = components.first?.lowercased() else { return "" }

        let rest = components.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }
}
