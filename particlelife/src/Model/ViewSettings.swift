//
//  ViewSettings.swift
//  particlelife
//
//  Created by Rob Silverman on 3/31/25.
//

import Foundation
import simd

struct ViewSettings {
    var cameraPosition: SIMD2<Float>   // 8 bytes
    var zoomLevel: Float               // 4 bytes
    var _padding1: Float = 0           // 4 bytes → aligns next vec2

    var windowSize: SIMD2<Float>       // 8 bytes
    var _padding2: SIMD2<Float> = .zero // 8 bytes → total = 32 bytes
    
    init() {
        cameraPosition = .zero
        zoomLevel = 1.0
        windowSize = .zero
    }
}

struct ClickData {
    var position: SIMD2<Float>      // 8 bytes
    var force: Float                // 4 bytes
    var _padding: UInt32 = 0        // 4 bytes
}
