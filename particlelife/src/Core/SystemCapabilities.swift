//
//  SystemCapabilities.swift
//  particlelife
//
//  Created by Rob Silverman on 3/4/25.
//


import Metal

class SystemCapabilities {
    static var isRunningOnProperGPU: Bool {
        guard let device = MTLCreateSystemDefaultDevice(), !device.isLowPower else {
            return false
        }
        return true
    }
}
