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
        computeEncoder.setBuffer(bufferManager.maxDistanceBuffer, offset: 0, index: 4)
        computeEncoder.setBuffer(bufferManager.minDistanceBuffer, offset: 0, index: 5)
        computeEncoder.setBuffer(bufferManager.betaBuffer, offset: 0, index: 6)
        computeEncoder.setBuffer(bufferManager.frictionBuffer, offset: 0, index: 7)
        computeEncoder.setBuffer(bufferManager.repulsionBuffer, offset: 0, index: 8)
        computeEncoder.setBuffer(bufferManager.cameraBuffer, offset: 0, index: 9)
        computeEncoder.setBuffer(bufferManager.zoomBuffer, offset: 0, index: 10)
        computeEncoder.setBuffer(bufferManager.worldSizeBuffer, offset: 0, index: 11)
        computeEncoder.setBuffer(bufferManager.clickBuffer, offset: 0, index: 12)
        computeEncoder.setBuffer(bufferManager.frameCountBuffer, offset: 0, index: 13)
        
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
