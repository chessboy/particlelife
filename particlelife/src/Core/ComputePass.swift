//
//  ComputePass.swift
//  particlelife
//
//  Created by Rob Silverman on 3/21/25.
//

import Foundation
import Metal

class ComputePass {
    let device: MTLDevice
    let computePipelineState: MTLComputePipelineState
    var commandQueue: MTLCommandQueue

    init(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!

        guard let computeFunction = library.makeFunction(name: "compute_particle_movement") else {
            fatalError("Failed to load compute_particle_movement function")
        }
        do {
            self.computePipelineState = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
    }

    func encode(commandBuffer: MTLCommandBuffer, bufferManager: BufferManager) {
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        computeEncoder.setComputePipelineState(computePipelineState)
        
        // Set buffers for particle movement.
        computeEncoder.setBuffer(bufferManager.particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(bufferManager.matrixBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(bufferManager.speciesCountBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(bufferManager.deltaTimeBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(bufferManager.clickBuffer, offset: 0, index: 4)
        computeEncoder.setBuffer(bufferManager.frameCountBuffer, offset: 0, index: 5)
        computeEncoder.setBuffer(bufferManager.settingsBuffer, offset: 0, index: 6)

        let threadGroupSize = 256
        let particleCount = SimulationSettings.shared.selectedPreset.particleCount.rawValue
        let threadGroups = (particleCount + threadGroupSize - 1) / threadGroupSize
        
        computeEncoder.dispatchThreadgroups(
            MTLSize(width: threadGroups, height: 1, depth: 1),
            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1)
        )
        
        computeEncoder.endEncoding()
    }
}
