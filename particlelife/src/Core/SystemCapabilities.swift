//
//  SystemCapabilities.swift
//  particlelife
//
//  Created by Rob Silverman on 3/4/25.
//

import Metal

enum GPUType {
    case dedicatedGPU   // High-performance GPU
    case integratedGPU  // Low-power GPU (e.g., Intel/Apple integrated)
    case cpuOnly        // No Metal-compatible GPU, CPU fallback
}

class SystemCapabilities {
    static let shared = SystemCapabilities()
    let baseSmoothingFactor: Float = 0.05
    
    // Debug overrides (set to `nil` for real detection)
    private let debugGPUType: GPUType? = nil // Set to `.cpuOnly`, `.integratedGPU`, or `.dedicatedGPU`
    private let debugGPUCoreCount: Int? = nil // Set to a custom core count (e.g., 10, 16, 30)
    
    let device: MTLDevice?
    var deviceName: String
    var gpuType: GPUType
    var maxThreadsPerGroup: Int
    var isAppleSilicon: Bool
    var gpuCoreCount: Int
    
    private init() {
        self.device = MTLCreateSystemDefaultDevice()
        
        // Default values before checking real hardware
        self.deviceName = self.device?.name ?? "undetermined"
        self.isAppleSilicon = false
        self.maxThreadsPerGroup = 0
        self.gpuCoreCount = 0
        self.gpuType = .cpuOnly  // Default before checking device
        
        if let debugGPUType = debugGPUType {
            self.gpuType = debugGPUType
        } else if let device = self.device {
            self.isAppleSilicon = device.name.contains("Apple")
            self.maxThreadsPerGroup = device.maxThreadsPerThreadgroup.width * device.maxThreadsPerThreadgroup.height
            self.gpuType = device.isLowPower ? (device.isHeadless ? .cpuOnly : .integratedGPU) : .dedicatedGPU
        }
        
        if let debugGPUCoreCount = debugGPUCoreCount {
            self.gpuCoreCount = debugGPUCoreCount
        } else {
            self.gpuCoreCount = estimateCoreCount()
        }

        Logger.log("SystemCapabilities: deviceName: \(deviceName) | gpuType: \(gpuType) | GPU Cores: \(gpuCoreCount) | ThreadsPerGroup: \(maxThreadsPerGroup)", level: .debug)
        Logger.log("SystemCapabilities: preferredFramesPerSecond: \(preferredFramesPerSecond) | smoothingFactor: \(smoothingFactor)", level: .debug)
        Logger.log("SystemCapabilities: max particle count: \(ParticleCount.maxAllowedParticleCount(for: gpuCoreCount, gpuType: gpuType))", level: .debug)
    }
    
    /// Estimates GPU core count based on known Apple GPUs.
    private func estimateCoreCount() -> Int {
        if deviceName.contains("M2 Ultra") { return 60 }  // M2 Ultra: 60/76 cores
        if deviceName.contains("M2 Max") { return 38 }    // Default to 38
        if deviceName.contains("M2 Pro") { return 16 }    // M2 Pro: 16/19 cores
        if deviceName.contains("M2") { return 10 }        // M2: 10-core GPU
        
        if deviceName.contains("M1 Ultra") { return 48 }  // M1 Ultra: 48/64 cores
        if deviceName.contains("M1 Max") { return 32 }    // Default to 32
        if deviceName.contains("M1 Pro") { return 14 }    // M1 Pro: 14/16 cores
        if deviceName.contains("M1") { return 8 }         // M1: 8-core GPU
        
        return 8 // Fallback (default)
    }
}

extension SystemCapabilities {
    
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
    
    var dtFactor: Float {
        return 60.0 / Float(preferredFramesPerSecond) // Normalizes physics to match 60 FPS baseline
    }    
}
