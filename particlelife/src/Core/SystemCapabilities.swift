//
//  SystemCapabilities.swift
//  particlelife
//
//  Created by Rob Silverman on 3/4/25.
//

import Metal

class SystemCapabilities {
    enum GPUType {
        case dedicatedGPU   // High-performance GPU
        case integratedGPU  // Low-power GPU (e.g., Intel/Apple integrated)
        case cpuOnly        // No Metal-compatible GPU, CPU fallback
    }

    static let shared = SystemCapabilities() // Singleton instance
    
    let device: MTLDevice?
    let gpuType: GPUType
    let baseSmoothingFactor: Float = 0.05

    // Debug override for testing (set to nil for real detection)
    private let debugOverride: GPUType? = nil
    // Set this to `.cpuOnly` or `.integratedGPU` to force that mode for testing

    private init() {
        self.device = MTLCreateSystemDefaultDevice() // Ensure `device` is always initialized
        
        if let debugGPU = debugOverride {
            self.gpuType = debugGPU
        } else if let device = self.device {
            if device.isLowPower {
                self.gpuType = device.isHeadless ? .cpuOnly : .integratedGPU
            } else {
                self.gpuType = .dedicatedGPU
            }
        } else {
            self.gpuType = .cpuOnly
        }

        Logger.log("SystemCapabilities initialized: \(gpuType), smoothing factor: \(smoothingFactor)", level: .debug)
    }
    
    var isRunningOnProperGPU: Bool {
        return gpuType == .dedicatedGPU
    }

    var isCPUOnly: Bool {
        return gpuType == .cpuOnly
    }
    
    var smoothingFactor: Float {
        return baseSmoothingFactor * (60.0 / Float(preferredFramesPerSecond))
    }

    /// Returns an appropriate warning title and message based on GPU capabilities
    func performanceWarning() -> (title: String, message: String)? {
        switch gpuType {
        case .dedicatedGPU:
            return nil // No warning needed

        case .integratedGPU:
            return (
                "Performance Warning",
                "Your system has a low-power GPU. Performance may be reduced."
            )

        case .cpuOnly:
            return (
                "Severe Performance Warning",
                "No compatible GPU found. The app is running on CPU fallback, which may cause extreme slowdowns."
            )
        }
    }
}

extension SystemCapabilities {
    
    var dtFactor: Float {
        return 60.0 / Float(preferredFramesPerSecond) // Normalizes physics to match 60 FPS baseline
    }
    
    var preferredFramesPerSecond: Int {
        switch gpuType {
        case .dedicatedGPU:
            return 60
        case .integratedGPU:
            return 30
        case .cpuOnly:
            return 20
        }
    }
}
