//
//  MetalPerformanceTester.swift
//  particlelife
//
//  Created by Rob Silverman on 3/6/25.
//

import Foundation
import Metal

class MetalPerformanceTester {
    private let device: MTLDevice
    private var computePipelineState: MTLComputePipelineState?
    private var dummyBuffer: MTLBuffer?
    
    init?(device: MTLDevice) {
        self.device = device
        guard setupComputePipeline(), createDummyBuffer() else { return nil }
    }
    
    /// Sets up a minimal compute pipeline for performance testing.
    private func setupComputePipeline() -> Bool {
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "simpleComputeKernel") else {
            Logger.log("Failed to load simpleComputeKernel.", level: .error)
            return false
        }
        
        do {
            computePipelineState = try device.makeComputePipelineState(function: function)
            //Logger.log("Compute pipeline created successfully.", level: .debug)
            return true
        } catch {
            Logger.logWithError("Failed to create compute pipeline", error: error)
            return false
        }
    }
    
    /// Creates a reusable buffer for GPU workload.
    private func createDummyBuffer() -> Bool {
        let bufferSize = 1024 * MemoryLayout<Float>.size
        dummyBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)
        
        if dummyBuffer != nil {
            //Logger.log("Dummy buffer created.", level: .debug)
            return true
        } else {
            Logger.log("Failed to create dummy buffer.", level: .error)
            return false
        }
    }
    
    /// Encodes a minimal compute workload to prevent optimizations.
    private func encodeDummyComputeWorkload(encoder: MTLComputeCommandEncoder) {
        guard let pipelineState = computePipelineState else {
            Logger.log("No valid compute pipeline state.", level: .error)
            return
        }
        
        encoder.setComputePipelineState(pipelineState)
        
        guard let validBuffer = dummyBuffer else {
            Logger.log("No dummyBuffer available.", level: .error)
            return
        }
        
        // Optionally, modify the buffer to prevent excessive optimization
        let pointer = validBuffer.contents().assumingMemoryBound(to: Float.self)
        for i in 0..<1024 {
            pointer[i] = Float(i) * 1.00001 // Small change to force computation
        }
        
        encoder.setBuffer(validBuffer, offset: 0, index: 0)
        
        // Dispatch 1024 threads in groups of 32
        let threadCount = 1024
        let threadsPerGroup = MTLSize(width: 32, height: 1, depth: 1)
        let threadGroups = MTLSize(width: (threadCount + 31) / 32, height: 1, depth: 1)
        
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
    }
    
    /// Runs a performance test to estimate GPU core count.
    func measurePerformance(iterations: Int) -> Double {
        
        guard let commandQueue = device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            Logger.log("Could not create command queue or encoder. Returning large elapsed time.", level: .debug)
            return Double.greatestFiniteMagnitude
        }

        let start = CFAbsoluteTimeGetCurrent()

        // Encode all iterations in a **single** command buffer
        for _ in 0..<iterations {
            encodeDummyComputeWorkload(encoder: computeEncoder)
        }

        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let end = CFAbsoluteTimeGetCurrent()
        let elapsed = end - start

        //Logger.log("Performance test completed in \(String(format: "%.4f", elapsed)) seconds.", level: .debug)
        return elapsed
    }
}
