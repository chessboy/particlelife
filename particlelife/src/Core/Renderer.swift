//
//  Renderer.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Foundation
import MetalKit
import Combine

class Renderer: NSObject, MTKViewDelegate, ObservableObject {
    
    private let drawWorldBoundary = true
    
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
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var particleSystem: ParticleSystem!
    
    private var pipelineState: MTLRenderPipelineState?
    private var boundaryPipelineState: MTLRenderPipelineState?
    private var computePipeline: MTLComputePipelineState?
    
    private var cancellables = Set<AnyCancellable>()
    private var worldSizeObserver: AnyCancellable?
    
    var mtkView: MTKView?
    
    init(mtkView: MTKView? = nil) {
        super.init()
        
        if let mtkView = mtkView {
            self.device = mtkView.device
            mtkView.delegate = self
        } else {
            print("⚠️ Running in Preview Mode - Metal Rendering Disabled")
        }
        
        self.commandQueue = device?.makeCommandQueue()
        self.particleSystem = ParticleSystem.shared
        setupPipelines()
        
        // listeners
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        
        worldSizeObserver = SimulationSettings.shared.$worldSize.sink { [weak self] newWorldSize in
            self?.adjustZoomAndCameraForWorldSize(newWorldSize.value)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(presetApplied), name: Notification.Name.presetSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presetApplied), name: Notification.Name.presetSelectedNoRespawn, object: nil)
    }
    
    /// Called when a preset is applied
    @objc private func presetApplied() {
        if isPaused {
            isPaused.toggle()
        }
    }
    
    private func adjustZoomAndCameraForWorldSize(_ newWorldSize: Float) {
        let baseSize: Float = 1.0
        let minZoom: Float = 0.1
        let maxZoom: Float = 4.5
        
        zoomLevel = min(max(baseSize / newWorldSize, minZoom), maxZoom)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        
        cameraPosition = .zero
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    @objc private func handleAppWillResignActive() {
        isPaused = true
    }
    
    // Combine compute + render pipeline setup into a single function
    private func setupPipelines() {
        guard let library = device?.makeDefaultLibrary() else {
            print("⚠️ Warning: Failed to load Metal shader library")
            return
        }
        
        do {
            guard let computeFunction = library.makeFunction(name: "compute_particle_movement") else {
                fatalError("❌ Failed to load compute function")
            }
            computePipeline = try device?.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("❌ Failed to create compute pipeline state: \(error)")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main") // For particles
        let fragmentFunction = library.makeFunction(name: "fragment_main") // Shared fragment shader
        
        // Setup Particle Pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable blending for smooth rendering
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("❌ Failed to create render pipeline state: \(error)")
        }
    }
    
    /// Lazy setup for boundary pipeline
    private func setupBoundaryPipeline() {
        guard let device = device, let library = device.makeDefaultLibrary() else { return }
        
        let boundaryVertexFunction = library.makeFunction(name: "vertex_boundary")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let boundaryPipelineDescriptor = MTLRenderPipelineDescriptor()
        boundaryPipelineDescriptor.vertexFunction = boundaryVertexFunction
        boundaryPipelineDescriptor.fragmentFunction = fragmentFunction
        boundaryPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            boundaryPipelineState = try device.makeRenderPipelineState(descriptor: boundaryPipelineDescriptor)
        } catch {
            print("❌ Failed to create boundary pipeline state: \(error)")
        }
    }
    
    func draw(in view: MTKView) {
        if isPaused || !BufferManager.shared.areBuffersInitialized {
            return
        }
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        
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
        
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
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
        computeEncoder.setBuffer(BufferManager.shared.repulsionBuffer, offset: 0, index: 8)
        computeEncoder.setBuffer(BufferManager.shared.cameraBuffer, offset: 0, index: 9)
        computeEncoder.setBuffer(BufferManager.shared.zoomBuffer, offset: 0, index: 10)
        computeEncoder.setBuffer(BufferManager.shared.worldSizeBuffer, offset: 0, index: 11)
        computeEncoder.setBuffer(BufferManager.shared.clickBuffer, offset: 0, index: 12)
                
        let threadGroupSize = 512
        let particleCount = SimulationSettings.shared.selectedPreset.numParticles.rawValue
        let threadGroups = (particleCount + threadGroupSize - 1) / threadGroupSize
        computeEncoder.dispatchThreadgroups(MTLSize(width: threadGroups, height: 1, depth: 1),
                                            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1))
        computeEncoder.endEncoding()
    }
    
    private func runRenderPass(commandBuffer: MTLCommandBuffer?, view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipelineState = pipelineState,
              let passDescriptor = view.currentRenderPassDescriptor else { return }
        
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
        
        guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor) else { return }
        
        // Draw World Boundary (Only if enabled)
        if drawWorldBoundary {
            if boundaryPipelineState == nil {
                setupBoundaryPipeline() // Create only when needed
            }
            if let boundaryPipelineState = boundaryPipelineState {
                renderEncoder.setRenderPipelineState(boundaryPipelineState)
                renderEncoder.setVertexBuffer(BufferManager.shared.cameraBuffer, offset: 0, index: 1)
                renderEncoder.setVertexBuffer(BufferManager.shared.zoomBuffer, offset: 0, index: 2)
                renderEncoder.setVertexBuffer(BufferManager.shared.worldSizeBuffer, offset: 0, index: 3)
                renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: 5)
            }
        }
        
        // Draw Particles
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(BufferManager.shared.particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(BufferManager.shared.cameraBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(BufferManager.shared.zoomBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(BufferManager.shared.pointSizeBuffer, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(BufferManager.shared.worldSizeBuffer, offset: 0, index: 4)
        let particleCount = SimulationSettings.shared.selectedPreset.numParticles.rawValue
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        
        // wrap up
        renderEncoder.endEncoding()
        commandBuffer?.present(drawable)
    }
    
    // Zoom Controls
    
    func resetPanAndZoom() {
        guard !isPaused else { return }
        zoomLevel = 1.0
        cameraPosition = .zero
        adjustZoomAndCameraForWorldSize(SimulationSettings.shared.worldSize.value)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func zoomIn() {
        guard !isPaused else { return }
        zoomLevel *= Constants.Controls.zoomStep
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
    }
    
    func zoomOut() {
        guard !isPaused else { return }
        zoomLevel /= Constants.Controls.zoomStep
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
    }
    
    // Pan Controls
    func panLeft() {
        guard !isPaused else { return }
        cameraPosition.x -= Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func panRight() {
        guard !isPaused else { return }
        cameraPosition.x += Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func panUp() {
        guard !isPaused else { return }
        cameraPosition.y += Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func panDown() {
        guard !isPaused else { return }
        cameraPosition.y -= Constants.Controls.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    private func updateCamera() {
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func respawnParticles() {
        if isPaused {
            isPaused.toggle()
        }
        particleSystem.respawn(shouldGenerateNewMatrix: false)
        //NotificationCenter.default.post(name: .respawn, object: nil)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

extension Renderer {
    
    /// Handles mouse clicks and perturbs nearby particles
    func handleMouseClick(at location: CGPoint, in view: MTKView, isRightClick: Bool) {
        guard !isPaused else { return }
        
        let worldPosition = screenToWorld(location, drawableSize: view.drawableSize, viewSize: view.frame.size)
        let effectRadius: Float = isRightClick ? 3.0 : 1.0
        
        //print("Clicked: \(isRightClick ? "Right" : "Left") at \(worldPosition)")
        
        // Send click data to Metal
        BufferManager.shared.updateClickBuffer(clickPosition: worldPosition, force: effectRadius)
        
        // Clear click buffer after 1 frame (~16ms delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
            BufferManager.shared.updateClickBuffer(clickPosition: SIMD2<Float>(0, 0), force: 0.0, clear: true)
        }
    }
    
    func screenToWorld(_ screenPosition: CGPoint, drawableSize: CGSize, viewSize: CGSize) -> SIMD2<Float> {
        let retinaScale = Float(drawableSize.width) / Float(viewSize.width) // Convert CGFloat to Float
        
        let scaledWidth = Float(drawableSize.width) / retinaScale
        let scaledHeight = Float(drawableSize.height) / retinaScale
        
        let aspectRatio = scaledWidth / scaledHeight // Compute aspect ratio
        
        let normalizedX = Float(screenPosition.x) / scaledWidth
        let normalizedY = Float(screenPosition.y) / scaledHeight
        
        let ndcX = (2.0 * normalizedX) - 1.0
        let ndcY = (2.0 * normalizedY) - 1.0
        
        //  Apply aspect ratio correction
        let worldX = ndcX * aspectRatio  // Scale X to match screen proportions
        let worldY = ndcY
        
        let worldPos = SIMD2<Float>(worldX, worldY) / zoomLevel + cameraPosition
        
        return worldPos
    }
}
