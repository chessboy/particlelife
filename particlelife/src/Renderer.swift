//
//  Renderer.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var particleSystem: ParticleSystem!
    var pipelineState: MTLRenderPipelineState!
    var isPaused = false

    init(mtkView: MTKView) {
        super.init()
        self.device = mtkView.device
        self.commandQueue = device.makeCommandQueue()
        self.particleSystem = ParticleSystem(device: device)
        setupPipelineState()
        mtkView.delegate = self
    }
    
    func setupPipelineState() {
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        if vertexFunction == nil || fragmentFunction == nil {
            fatalError("Error: Failed to load Metal shader functions.")
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // ✅ Enable Blending for Motion Blur Effect
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<simd_float2>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    func draw(in view: MTKView) {
        if isPaused { return }

        particleSystem.update()  // GPU updates particle positions

        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let passDescriptor = view.currentRenderPassDescriptor else { return }

        // ✅ Fix: Restore full screen clearing but use subtle alpha
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)  // Dark gray, fully opaque

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
        commandEncoder?.setRenderPipelineState(pipelineState)
        commandEncoder?.setVertexBuffer(particleSystem.particleBuffer, offset: 0, index: 0)
        commandEncoder?.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleSystem.particles.count)
        commandEncoder?.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func resetParticles() {
        particleSystem = ParticleSystem(device: device, count: 20000)  // ✅ Reinitialize particles
        print("Simulation reset complete.")
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
