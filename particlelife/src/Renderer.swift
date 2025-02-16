//
//  Renderer.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate, ObservableObject {
    
    @Published var fps: Int = 0
    @Published var isPaused: Bool = false {
        didSet {
            if !isPaused {
                lastUpdateTime = Date().timeIntervalSince1970
                frameCount = 0
            }
        }
    }

    var cameraPosition: simd_float2 = .zero
    var zoomLevel: Float = 1.0

    private var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970
    private var frameCount = 0
    
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var particleSystem: ParticleSystem!
    private var pipelineState: MTLRenderPipelineState!
    private var computePipeline: MTLComputePipelineState?
        
    init(mtkView: MTKView) {
        super.init()
        self.device = mtkView.device
        self.commandQueue = device.makeCommandQueue()
        self.particleSystem = ParticleSystem.shared
        setupPipelines()
        mtkView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func handleAppWillResignActive() {
        isPaused = true
    }
    
    // Combine compute + render pipeline setup into a single function
    private func setupPipelines() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load Metal shader library")
        }
        
        do {
            guard let computeFunction = library.makeFunction(name: "compute_particle_movement") else {
                fatalError("Failed to load compute function")
            }
            computePipeline = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable blending for smooth rendering
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Failed to create render pipeline state: \(error)")
        }
    }
    
    func draw(in view: MTKView) {
        if isPaused || !BufferManager.shared.areBuffersInitialized {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        
        updateSimulationState()
        runComputePass(commandBuffer: commandBuffer)
        runRenderPass(commandBuffer: commandBuffer, view: view)

        commandBuffer?.commit()
    }
    
    // Handles FPS updates & buffer syncing
    private func updateSimulationState() {
        let currentTime = Date().timeIntervalSince1970
        frameCount += 1

        if currentTime - lastUpdateTime >= 1.0 {
            let capturedFPS = frameCount

            DispatchQueue.main.async {
                self.fps = capturedFPS
                self.objectWillChange.send()
            }

            frameCount = 0
            lastUpdateTime = currentTime
        }

        particleSystem.update()

        BufferManager.shared.updateCameraBuffer(position: cameraPosition)
        BufferManager.shared.updateZoomBuffer(zoom: zoomLevel)
    }
    
    // Runs the Metal Compute Pass
    private func runComputePass(commandBuffer: MTLCommandBuffer?) {
        guard let computeEncoder = commandBuffer?.makeComputeCommandEncoder(),
              let computePipeline = computePipeline else { return }

        
        computeEncoder.setComputePipelineState(computePipeline)
        
        computeEncoder.setBuffer(BufferManager.shared.particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(BufferManager.shared.interactionBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(BufferManager.shared.numSpeciesBuffer, offset: 0, index: 2)
        computeEncoder.setBuffer(BufferManager.shared.deltaTimeBuffer, offset: 0, index: 3)
        computeEncoder.setBuffer(BufferManager.shared.maxDistanceBuffer, offset: 0, index: 4)
        computeEncoder.setBuffer(BufferManager.shared.minDistanceBuffer, offset: 0, index: 5)
        computeEncoder.setBuffer(BufferManager.shared.betaBuffer, offset: 0, index: 6)
        computeEncoder.setBuffer(BufferManager.shared.frictionBuffer, offset: 0, index: 7)
        computeEncoder.setBuffer(BufferManager.shared.repulsionStrengthBuffer, offset: 0, index: 8)
        computeEncoder.setBuffer(BufferManager.shared.cameraBuffer, offset: 0, index: 9)
        computeEncoder.setBuffer(BufferManager.shared.zoomBuffer, offset: 0, index: 10)


        let threadGroupSize = 512
        let threadGroups = (Constants.defaultParticleCount + threadGroupSize - 1) / threadGroupSize
        computeEncoder.dispatchThreadgroups(MTLSize(width: threadGroups, height: 1, depth: 1),
                                            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1))
        computeEncoder.endEncoding()
    }
    
    // Runs the Metal Render Pass
    private func runRenderPass(commandBuffer: MTLCommandBuffer?, view: MTKView) {
        guard let drawable = view.currentDrawable,
              let passDescriptor = view.currentRenderPassDescriptor else { return }

        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)

        guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor) else { return }
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(BufferManager.shared.particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(BufferManager.shared.cameraBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(BufferManager.shared.zoomBuffer, offset: 0, index: 2)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: Constants.defaultParticleCount)
        renderEncoder.endEncoding()

        commandBuffer?.present(drawable)
    }
    
    // Zoom Controls
    
    func resetPanAndZoom() {
        zoomLevel = 1.0
        cameraPosition = .zero
        BufferManager.shared.updateZoomBuffer(zoom: zoomLevel)
        BufferManager.shared.updateCameraBuffer(position: cameraPosition)
    }
    
    func zoomIn() {
        zoomLevel *= Constants.Controls.zoomStep
        BufferManager.shared.updateZoomBuffer(zoom: zoomLevel)
    }

    func zoomOut() {
        zoomLevel /= Constants.Controls.zoomStep
        BufferManager.shared.updateZoomBuffer(zoom: zoomLevel)
    }

    // Pan Controls
    func panLeft() {
        cameraPosition.x -= Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(position: cameraPosition)
    }

    func panRight() {
        cameraPosition.x += Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(position: cameraPosition)
    }

    func panUp() {
        cameraPosition.y += Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(position: cameraPosition)
    }

    func panDown() {
        cameraPosition.y -= Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(position: cameraPosition)
    }
    
    private func updateCamera() {
        BufferManager.shared.updateCameraBuffer(position: cameraPosition)
    }

    func resetParticles() {
        particleSystem.reset()
        NotificationCenter.default.post(name: .resetSimulation, object: nil)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
