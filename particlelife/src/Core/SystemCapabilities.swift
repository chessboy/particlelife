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
            // If we do have a Metal-compatible GPU, estimate its core count
            self.gpuCoreCount = estimateCoreCountOnDevice()
        }
        
        Logger.log("SystemCapabilities: deviceName: \(deviceName) | gpuType: \(gpuType) | GPU Cores: \(gpuCoreCount) | ThreadsPerGroup: \(maxThreadsPerGroup)", level: .debug)
        Logger.log("SystemCapabilities: preferredFramesPerSecond: \(preferredFramesPerSecond) | smoothingFactor: \(smoothingFactor)", level: .debug)
        Logger.log("SystemCapabilities: max particle count: \(ParticleCount.maxAllowedParticleCount(for: gpuCoreCount, gpuType: gpuType))", level: .debug)
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
        return 60.0 / Float(preferredFramesPerSecond) // Normalizes physics steps to 60 FPS baseline
    }
}

// MARK: - Performance-Based Core Count Estimation

extension SystemCapabilities {
    
    /// Estimates GPU core count purely via performance testing with a simple compute kernel.
    private func estimateCoreCountOnDevice(iterations: Int = 500, numSamples: Int = 3) -> Int {
        Logger.log("Estimating GPU core count via performance test: iterations: \(iterations) | samples: \(numSamples)", level: .debug)
        
        guard let device = self.device,
              let tester = MetalPerformanceTester(device: device) else {
            Logger.log("No Metal device found. Falling back to 8 cores.", level: .debug)
            return 8
        }

        var totalTime = 0.0

        for _ in 0..<numSamples {
            totalTime += tester.measurePerformance(iterations: iterations)
        }

        let avgTimePerIteration = totalTime / Double(iterations * numSamples)

        Logger.log("ave time: \(String(format: "%.3f", avgTimePerIteration * 1000))ms | total time: \(String(format: "%.3f", totalTime * 1000))ms", level: .debug)

        // Adjust thresholds as you gather real data on each chip
        switch avgTimePerIteration {
        case ..<0.0002:
            Logger.log("elapsed < 0.2ms => Assuming Ultra-level performance. Returning ~60 cores.", level: .debug)
            return 60
        case ..<0.0003:
            Logger.log("elapsed < 0.3ms => Assuming Max-level performance (38-core). Returning ~38 cores.", level: .debug)
            return 38
        case ..<0.0004:
            Logger.log("elapsed < 0.4ms => Assuming Max-level performance (30-core). Returning ~30 cores.", level: .debug)
            return 30
        case ..<0.0007:
            Logger.log("elapsed < 0.7ms => Assuming Pro-level performance. Returning ~16 cores.", level: .debug)
            return 16
        default:
            Logger.log("elapsed ≥ 0.7ms => Assuming base or lower performance. Returning ~10 cores.", level: .debug)
            return 10
        }
    }
}
