//
//  CGFloat+Extensions.swift
//  particlelife
//
//  Created by Rob Silverman on 3/7/25.
//

import Foundation
import CoreGraphics

extension CGFloat {
    var formattedNoDecimal: String {
        return Float(self).formattedNoDecimal
    }
    
    var formatted: String {
        return Float(self).formatted
    }
    
    var formattedTo2Places: String {
        return Float(self).formattedTo2Places
    }
    
    var formattedTo3Places: String {
        return Float(self).formattedTo3Places
    }
    
    var formattedToPercent: String {
        return Float(self).formattedTo3Places
    }
    
    var formattedToPercentNoDecimal: String {
        return Float(self).formattedToPercentNoDecimal
    }
    
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        let floatRange = Float(range.lowerBound)...Float(range.upperBound)
        return CGFloat(Float(self).clamped(to: floatRange))
    }
}

extension CGSize {
    
    var formattedTo2Places: String {
        return "(\(self.width.formattedTo2Places), \(self.height.formattedTo2Places))"
    }
    
    var aspectRatioFormattedTo2Places: String {
        guard self.height > 0 else { return "nan" }
        return "\((self.width/self.height).formattedTo3Places)"
    }
}

extension Double {
    var formattedNoDecimal: String {
        return Float(self).formattedNoDecimal
    }
    
    var formatted: String {
        return Float(self).formatted
    }
    
    var formattedTo2Places: String {
        return Float(self).formattedTo2Places
    }
    
    var formattedTo3Places: String {
        return Float(self).formattedTo3Places
    }
    
    var formattedToPercent: String {
        return Float(self).formattedTo3Places
    }
    
    var formattedToPercentNoDecimal: String {
        return Float(self).formattedToPercentNoDecimal
    }
    
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}


extension Float {
    
    var formattedNoDecimal: String { return
        String(format: "%.0f", locale: Locale.current, self)
    }

    var formatted: String { return
        String(format: "%.1f", locale: Locale.current, self)
    }

    var formattedTo2Places: String { return
        String(format: "%.2f", locale: Locale.current, self)
    }

    var formattedTo3Places: String { return
        String(format: "%.3f", locale: Locale.current, self)
    }

    var formattedToPercent: String { return
        String(format: "%.1f", locale: Locale.current, self.clamped(to: 0...1) * 100) + "%"
    }

    var formattedToPercentNoDecimal: String { return
        String(format: "%.0f", locale: Locale.current, self.clamped(to: 0...1) * 100) + "%"
    }

    func clamped(to range: ClosedRange<Float>) -> Float {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
