//
//  ViewSettings.swift
//  particlelife
//
//  Created by Rob Silverman on 3/31/25.
//

import Foundation
import simd

struct ViewSettings {
    var cameraPosition: SIMD2<Float> = .zero        // 8 bytes
    var zoomLevel: Float = 1.0                      // 4 bytes
    var _padding1: Float = .zero                    // 4 bytes → aligns next vec2

    var windowSize: SIMD2<Float> = .zero            // 8 bytes
    var pointSize: Float = 1.0                      // 4 bytes
    var speciesColorOffset: UInt32 = .zero          // 4 bytes
    var paletteIndex: UInt32 = .zero                // 4 bytes
    var colorEffect: UInt32 = .zero                 // 4 byt    es
    var _padding2: SIMD2<Float> = .zero             // 8 bytes → total = 48 bytes
}

extension ViewSettings: Equatable {
    static func == (lhs: ViewSettings, rhs: ViewSettings) -> Bool {
        return lhs.cameraPosition == rhs.cameraPosition &&
               lhs.zoomLevel == rhs.zoomLevel &&
               lhs.windowSize == rhs.windowSize &&
               lhs.pointSize == rhs.pointSize &&
               lhs.speciesColorOffset == rhs.speciesColorOffset &&
               lhs.paletteIndex == rhs.paletteIndex &&
               lhs.colorEffect == rhs.colorEffect
    }
}

struct ClickData {
    var position: SIMD2<Float>      // 8 bytes
    var force: Float                // 4 bytes
    var _padding: UInt32 = .zero    // 4 bytes
}
