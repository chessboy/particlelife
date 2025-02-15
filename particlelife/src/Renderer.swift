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
    var lastMousePosition: simd_float2?  // ✅ Store last position for smooth movement

    init(mtkView: MTKView) {
        super.init()
        self.device = mtkView.device
        self.commandQueue = device.makeCommandQueue()
        self.particleSystem = ParticleSystem.shared
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

        // ✅ Enable Blending for Smooth Rendering (Remove Duplicates)
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        // ✅ Define Vertex Descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<simd_float2>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.inputPrimitiveTopology = .point
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }
    
    func draw(in view: MTKView) {
        if isPaused { return }

        particleSystem.update()  // ✅ Update simulation step

        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let passDescriptor = view.currentRenderPassDescriptor else { return }

        // ✅ Ensure buffers are always fresh
        particleSystem.updatePhysicsBuffers()

        // ✅ Fix: Restore full-screen clearing but use subtle alpha
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
        particleSystem.reset(count: 36000)
        NotificationCenter.default.post(name: .resetSimulation, object: nil)  // ✅ Notify UI
        print("resetParticles")
    }

    func handleMouseDrag(location: CGPoint, viewSize: CGSize) {
        let normalizedPosition = simd_float2(
            Float((location.x / viewSize.width) * 2.0 - 1.0),
            Float((location.y / viewSize.height) * 2.0 - 1.0)
        )

        var velocity = lastMousePosition.map { normalizedPosition - $0 } ?? simd_float2(0, 0)

        // ✅ Limit velocity to avoid excessive force
        let maxVelocity: Float = 0.025
        velocity = clamp(velocity, min: simd_float2(-maxVelocity, -maxVelocity), max: simd_float2(maxVelocity, maxVelocity))

        lastMousePosition = normalizedPosition

        particleSystem.currentMousePosition = normalizedPosition
        particleSystem.currentMouseVelocity = velocity

        // ✅ Update Metal buffers with clamped values
        particleSystem.mousePositionBuffer?.contents().copyMemory(from: &particleSystem.currentMousePosition, byteCount: MemoryLayout<simd_float2>.stride)
        particleSystem.mouseVelocityBuffer?.contents().copyMemory(from: &particleSystem.currentMouseVelocity, byteCount: MemoryLayout<simd_float2>.stride)

        // ✅ Schedule reset after 100ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.particleSystem.clearMouseInfluence()
        }
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
