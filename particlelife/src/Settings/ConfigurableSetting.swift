//
//  ConfigurableSetting.swift
//  particlelife
//
//  Created by Rob Silverman on 4/1/25.
//

import Foundation

struct ConfigurableSetting {
    var value: Float {
        didSet {
            value = snapped(value)
            onChange?(value)
        }
    }
    
    let defaultValue: Float
    let minValue: Float
    let maxValue: Float
    let step: Float
    let format: String
    var onChange: ((Float) -> Void)?
    
    mutating func returnToDefault() {
        value = defaultValue
    }
    
    private func snapped(_ newValue: Float) -> Float {
        let clamped = max(minValue, min(maxValue, newValue))
        if clamped < (minValue + step) / 2 {
            return minValue
        }
        return round(clamped / step) * step
    }
}
