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
        } else if gpuType != .cpuOnly {
            self.gpuCoreCount = estimateCoreCount()
        }
        
        Logger.log("SystemCapabilities: Running on \(isAppleSilicon ? " Silicon" : "Intel")", level: .debug)
        Logger.log("SystemCapabilities: deviceName: \(deviceName) | gpuType: \(gpuType) | Estimated GPU Cores: \(gpuCoreCount) | ThreadsPerGroup: \(maxThreadsPerGroup)", level: .debug)
        Logger.log("SystemCapabilities: preferredFramesPerSecond: \(preferredFramesPerSecond) | smoothingFactor: \(smoothingFactor)", level: .debug)
        Logger.log("SystemCapabilities: max particle count for optimization: \(ParticleCount.maxAllowedParticleCount(for: gpuCoreCount, gpuType: gpuType))", level: .debug)
        Logger.log("SystemCapabilities: max particle count for menu: \(ParticleCount.maxAllowedParticleCount(for: gpuCoreCount, gpuType: gpuType, allowExtra: true))", level: .debug)
    }
    
    /// Estimates GPU core count based on known Apple GPUs.
    private func estimateCoreCount() -> Int {
        // M2 Series
        if deviceName.contains("M2 Ultra") { return 60 }  // M2 Ultra: 60-core (lower tier) | 76-core (higher tier)
        if deviceName.contains("M2 Max") { return 30 }    // M2 Max: 30-core (lower tier) | 38-core (higher tier)
        if deviceName.contains("M2 Pro") { return 16 }    // M2 Pro: 16-core (lower tier) | 19-core (higher tier)
        if deviceName.contains("M2") { return 10 }        // M2 Base: 10-core GPU
        
        // M1 Series
        if deviceName.contains("M1 Ultra") { return 48 }  // M1 Ultra: 48-core (lower tier) | 64-core (higher tier)
        if deviceName.contains("M1 Max") { return 24 }    // M1 Max: 24-core (lower tier) | 32-core (higher tier)
        if deviceName.contains("M1 Pro") { return 14 }    // M1 Pro: 14-core (lower tier) | 16-core (higher tier)
        if deviceName.contains("M1") { return 8 }         // M1 Base: 8-core GPU
        
        // Future-proofing for M3 series (based on trends)
        if deviceName.contains("M3 Ultra") { return 76 }  // Placeholder: M3 Ultra
        if deviceName.contains("M3 Max") { return 40 }    // Placeholder: M3 Max (likely 30/40)
        if deviceName.contains("M3 Pro") { return 20 }    // Placeholder: M3 Pro (likely 18/20)
        if deviceName.contains("M3") { return 12 }        // Placeholder: M3 Base (likely 10/12)
        
        Logger.log("Unknown GPU model '\(deviceName)', falling back to default core count.", level: .warning)
        return 8 // Default fallback for unknown/Intel GPUs
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
        // Normalizes smoothing to 60 FPS baseline
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
