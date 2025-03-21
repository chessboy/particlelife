//
//  RenderPass.swift
//  particlelife
//
//  Created by Rob Silverman on 3/21/25.
//

import Foundation
import MetalKit

class RenderPass {
    let device: MTLDevice
    let renderPipelineState: MTLRenderPipelineState

    init(device: MTLDevice, library: MTLLibrary) {
        self.device = device
        
        // Setup the render pipeline.
        guard let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            fatalError("Failed to load vertex_main or fragment_main functions")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Enable blending for smooth particle rendering.
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
    }

    func encode(commandBuffer: MTLCommandBuffer,
                renderPassDescriptor: MTLRenderPassDescriptor,
                drawable: MTLDrawable,
                bufferManager: BufferManager) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(bufferManager.particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(bufferManager.cameraBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(bufferManager.zoomBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(bufferManager.pointSizeBuffer, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(bufferManager.speciesColorOffsetBuffer, offset: 0, index: 4)
        renderEncoder.setVertexBuffer(bufferManager.paletteIndexBuffer, offset: 0, index: 5)
        renderEncoder.setVertexBuffer(bufferManager.windowSizeBuffer, offset: 0, index: 6)
        renderEncoder.setVertexBuffer(bufferManager.frameCountBuffer, offset: 0, index: 7)
        renderEncoder.setVertexBuffer(bufferManager.colorEffectIndexBuffer, offset: 0, index: 8)
        renderEncoder.setVertexBuffer(bufferManager.speciesCountBuffer, offset: 0, index: 9)
        
        renderEncoder.setFragmentBuffer(bufferManager.colorEffectIndexBuffer, offset: 0, index: 0)
        
        let particleCount = SimulationSettings.shared.selectedPreset.particleCount.rawValue
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
    }
}
