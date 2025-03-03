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
    
    private weak var fpsMonitor: FPSMonitor?
    
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
    private var clickPersistenceFrames: Int = 0
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var particleSystem: ParticleSystem!
    
    private var renderPipelineState: MTLRenderPipelineState?
    private var computePipeline: MTLComputePipelineState?
    
    private var cancellables = Set<AnyCancellable>()
    private var worldSizeObserver: AnyCancellable?
    
    var mtkView: MTKView?
    private var trailTexture: MTLTexture?
    
    init(mtkView: MTKView? = nil, fpsMonitor: FPSMonitor) {
        self.fpsMonitor = fpsMonitor
        super.init()
        
        if let mtkView = mtkView {
            self.device = mtkView.device
            mtkView.delegate = self
            Logger.log("Running on Metal device")
        } else {
            Logger.log("Running in Preview Mode - Metal Rendering Disabled", level: .warning)
        }
        
        self.commandQueue = device?.makeCommandQueue()
        self.particleSystem = ParticleSystem.shared
        
        // Setup Metal Pipelines (Rendering + Trails)
        setupRenderPipeline()
        setupTrailPipeline()
        createQuadBuffer()  // Full-screen quad for blending trails
        
        // Listen for World Size Changes
        worldSizeObserver = SimulationSettings.shared.$worldSize.sink { [weak self] newWorldSize in
            self?.adjustZoomAndCameraForWorldSize(newWorldSize.value)
        }
        
        // Listen for Preset Selection Events
        NotificationCenter.default.addObserver(self, selector: #selector(presetApplied), name: Notification.Name.presetSelected, object: nil)
    }
    
    /// Called when a preset is applied
    @objc private func presetApplied() {
        if isPaused {
            isPaused.toggle()
        }
    }
    
    @objc private func handleAppWillResignActive() {
        isPaused = true
    }
    
    // Combine compute + render pipeline setup into a single function
    private func setupRenderPipeline() {
        guard let library = device?.makeDefaultLibrary() else {
            Logger.log("Failed to load Metal shader library", level: .error)
            return
        }
        
        do {
            guard let computeFunction = library.makeFunction(name: "compute_particle_movement") else {
                fatalError("ERROR: Failed to load compute function")
            }
            computePipeline = try device?.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("ERROR: Failed to create compute pipeline state: \(error)")
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
            renderPipelineState = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("ERROR: Failed to create render pipeline state: \(error)")
        }
    }
    
    func draw(in view: MTKView) {
        if isPaused || !BufferManager.shared.areBuffersInitialized {
            return
        }
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        
        updateSimulationState()
        runComputePass(commandBuffer: commandBuffer)
        
        renderTrails(commandBuffer: commandBuffer, view: view) // Render particles onto the trail texture
        blendTrails(commandBuffer: commandBuffer, view: view)  // Blend it with the current frame
        
        runRenderPass(commandBuffer: commandBuffer, view: view)
        
        commandBuffer?.commit()
    }
    
    // Handles FPS updates & buffer syncing
    private func updateSimulationState() {
        DispatchQueue.main.async {
            self.fpsMonitor?.frameRendered()
        }
        particleSystem.update()
        
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        
        monitorClickBuffer()
    }
    
    func monitorClickBuffer() {
        if clickPersistenceFrames > 0 {
            clickPersistenceFrames -= 1
        } else if clickPersistenceFrames == 0 {
            BufferManager.shared.updateClickBuffer(clickPosition: SIMD2<Float>(0, 0), force: 0.0, clear: true)
            clickPersistenceFrames = -1  // Ensure we don't keep clearing needlessly
            //Logger.log("Cleared click buffer", level: .debug)
        }
    }
    
    // Runs the Metal Compute Pass
    private func runComputePass(commandBuffer: MTLCommandBuffer?) {
        guard let computeEncoder = commandBuffer?.makeComputeCommandEncoder(),
              let computePipeline = computePipeline else { return }
        
        let bufferManager = BufferManager.shared
        
        // 🔥 Step 1: Copy latest GPU positions to prevPositionsBuffer using a separate command buffer
        if let prevPositionsBuffer = bufferManager.prevPositionsBuffer,
           let particleBuffer = bufferManager.particleBuffer,
           let blitCommandBuffer = commandQueue?.makeCommandBuffer(),
           let blitEncoder = blitCommandBuffer.makeBlitCommandEncoder() {
            
            let particleCount = SimulationSettings.shared.selectedPreset.particleCount.rawValue
            let expectedSize = particleCount * MemoryLayout<SIMD2<Float>>.size
            if prevPositionsBuffer.length != expectedSize {
                Logger.log("❌ Mismatch! PrevPositionsBuffer size: \(prevPositionsBuffer.length), Expected: \(expectedSize)", level: .error)
            }
            
            blitEncoder.copy(from: particleBuffer, sourceOffset: 0,
                             to: prevPositionsBuffer, destinationOffset: 0,
                             size: prevPositionsBuffer.length)
            blitEncoder.endEncoding()
            blitCommandBuffer.commit()
            
            let prevPointer = prevPositionsBuffer.contents().assumingMemoryBound(to: SIMD2<Float>.self)
            if prevPositionsBuffer.length > 0 {
                Logger.log("🔍 First 3 Prev Positions: \(prevPointer[0]), \(prevPointer[1]), \(prevPointer[2])", level: .debug)
            }
        }
        
        // 🔥 Step 2: Run Compute Shader (Moves Particles)
        computeEncoder.setComputePipelineState(computePipeline)
        
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
        
        let threadGroupSize = 256
        let particleCount = SimulationSettings.shared.selectedPreset.particleCount.rawValue
        let threadGroups = (particleCount + threadGroupSize - 1) / threadGroupSize
        computeEncoder.dispatchThreadgroups(MTLSize(width: threadGroups, height: 1, depth: 1),
                                            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1))
        computeEncoder.endEncoding()
    }
    
    private func runRenderPass(commandBuffer: MTLCommandBuffer?, view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipelineState = renderPipelineState,
              let passDescriptor = view.currentRenderPassDescriptor else { return }
        
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
        
        guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor) else { return }
        let bufferManager: BufferManager = BufferManager.shared
        
        // Draw Particles
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(bufferManager.particleBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(bufferManager.cameraBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(bufferManager.zoomBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(bufferManager.pointSizeBuffer, offset: 0, index: 3)
        renderEncoder.setVertexBuffer(bufferManager.speciesColorOffsetBuffer, offset: 0, index: 4)
        renderEncoder.setVertexBuffer(bufferManager.paletteIndexBuffer, offset: 0, index: 5)
        renderEncoder.setVertexBuffer(bufferManager.windowSizeBuffer, offset: 0, index: 6)
        
        let particleCount = SimulationSettings.shared.selectedPreset.particleCount.rawValue
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        
        // wrap up
        renderEncoder.endEncoding()
        commandBuffer?.present(drawable)
    }
    
    func respawnParticles() {
        if isPaused {
            isPaused.toggle()
        }
        particleSystem.respawn(shouldGenerateNewMatrix: false)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        Logger.log("🔍 drawableSizeWillChange fired with size: \(size.width)x\(size.height), current: \(view.drawableSize.width)x\(view.drawableSize.height)", level: .debug)
        let newWidth = Int(size.width)
        let newHeight = Int(size.height)
        
        // ✅ Only resize if the size actually changed
        if trailTexture?.width != newWidth || trailTexture?.height != newHeight {
            Logger.log("🔍 Resizing trail texture due to drawable size change", level: .debug)
            resizeTrailTextureIfNeeded(to: size)
        } else {
            Logger.log("🚫 Skipping resize - size unchanged", level: .debug)
        }
    }
}

private var trailPipelineState: MTLRenderPipelineState?
private var blendPipelineState: MTLRenderPipelineState?
private var quadVertexBuffer: MTLBuffer?
private var trailTexture: MTLTexture?

// rendering trails
extension Renderer {

    private func createQuadBuffer() {
        let quadVertices: [Float] = [
            -1.0, -1.0,  0.0, 1.0, // Bottom-left
             1.0, -1.0,  1.0, 1.0, // Bottom-right
            -1.0,  1.0,  0.0, 0.0, // Top-left
             1.0,  1.0,  1.0, 0.0  // Top-right
        ]

        quadVertexBuffer = device?.makeBuffer(bytes: quadVertices,
                                              length: quadVertices.count * MemoryLayout<Float>.size,
                                              options: [])
    }
    
    private func createTrailTexture(device: MTLDevice, size: CGSize) {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .bgra8Unorm
        descriptor.width = Int(size.width)
        descriptor.height = Int(size.height)
        descriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        trailTexture = device.makeTexture(descriptor: descriptor)
    }

    private func setupTrailPipeline() {
        
        guard let library = device?.makeDefaultLibrary() else {
            Logger.log("❌ Failed to load Metal shader library", level: .error)
            return
        }

        // List all available functions in the Metal library

        
        let availableFunctions = library.functionNames
        Logger.log("🔍 Available Metal Functions: \(availableFunctions)", level: .debug)
        
                
        // --- Trail Pipeline (Particles -> Trail Texture) ---
        let trailDescriptor = MTLRenderPipelineDescriptor()

        if let vertexFunction = library.makeFunction(name: "vertex_trail") {
            Logger.log("✅ Assigning vertexFunction: vertex_trail", level: .debug)
            trailDescriptor.vertexFunction = vertexFunction
        } else {
            Logger.log("❌ vertex_trail is unexpectedly nil", level: .error)
        }

        if let fragmentFunction = library.makeFunction(name: "fragment_trail") {
            Logger.log("✅ Assigning fragmentFunction: fragment_trail", level: .debug)
            trailDescriptor.fragmentFunction = fragmentFunction
        } else {
            Logger.log("❌ fragment_trail is unexpectedly nil", level: .error)
        }
        trailDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        trailDescriptor.colorAttachments[0].isBlendingEnabled = true
        trailDescriptor.colorAttachments[0].rgbBlendOperation = .add
        trailDescriptor.colorAttachments[0].alphaBlendOperation = .add
        trailDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        trailDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        do {
            trailPipelineState = try device?.makeRenderPipelineState(descriptor: trailDescriptor)
        } catch {
            Logger.log("Failed to create trail pipeline state: \(error)", level: .error)
        }
        
        // --- Blend Pipeline (Trail Texture -> Screen) ---
        let blendDescriptor = MTLRenderPipelineDescriptor()

        if let vertexFunction = library.makeFunction(name: "vertex_quad") {
            Logger.log("✅ Assigning vertexFunction: vertex_quad", level: .debug)
            blendDescriptor.vertexFunction = vertexFunction
        } else {
            Logger.log("❌ vertex_quad is unexpectedly nil", level: .error)
        }

        if let fragmentFunction = library.makeFunction(name: "fragment_blend") {
            Logger.log("✅ Assigning fragmentFunction: fragment_blend", level: .debug)
            blendDescriptor.fragmentFunction = fragmentFunction
        } else {
            Logger.log("❌ fragment_blend is unexpectedly nil", level: .error)
        }

        blendDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        blendDescriptor.colorAttachments[0].isBlendingEnabled = true
        blendDescriptor.colorAttachments[0].rgbBlendOperation = .add
        blendDescriptor.colorAttachments[0].alphaBlendOperation = .add
        blendDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        blendDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        do {
            blendPipelineState = try device?.makeRenderPipelineState(descriptor: blendDescriptor)
        } catch {
            Logger.log("Failed to create blend pipeline state: \(error)", level: .error)
        }
    }

    func resizeTrailTextureIfNeeded(to size: CGSize) {
        guard let device = device else {
            Logger.log("❌ No Metal device available", level: .error)
            return
        }

        let newWidth = max(1, Int(size.width))  // Prevent zero or negative values
        let newHeight = max(1, Int(size.height))

        if trailTexture?.width != newWidth || trailTexture?.height != newHeight {
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = .bgra8Unorm
            descriptor.width = newWidth
            descriptor.height = newHeight
            descriptor.usage = [.renderTarget, .shaderRead] // ✅ Ensure renderTarget usage is included
            
            // 🔹 Check available memory (Optional: Only needed if memory is tight)
            let memoryNeeded = newWidth * newHeight * 4 // Approx bytes needed
            Logger.log("🔍 Resizing trail texture: \(newWidth)x\(newHeight), Est. Memory: \(memoryNeeded / (1024 * 1024)) MB", level: .debug)

            if let newTexture = device.makeTexture(descriptor: descriptor) {
                trailTexture = newTexture
                Logger.log("✅ Trail texture resized to: \(newWidth)x\(newHeight)", level: .debug)
            } else {
                Logger.log("❌ Failed to create trail texture! Possible memory issue?", level: .error)
            }
        }
    }
    
    private func renderTrails(commandBuffer: MTLCommandBuffer?, view: MTKView) {
        
        Logger.log("Checking guard in Rendering trails...", level: .debug)

        Logger.log("Trail pipeline state: \(trailPipelineState != nil)", level: .debug)
        Logger.log("Command buffer: \(commandBuffer != nil)", level: .debug)
        Logger.log("Prev positions buffer: \(BufferManager.shared.prevPositionsBuffer != nil)", level: .debug)
        Logger.log("Particle buffer: \(BufferManager.shared.particleBuffer != nil)", level: .debug)
        Logger.log("Trail texture: \(trailTexture != nil)", level: .debug)
        
        guard let pipelineState = trailPipelineState,
              let commandBuffer = commandBuffer,
              let prevPositionsBuffer = BufferManager.shared.prevPositionsBuffer,
              let particleBuffer = BufferManager.shared.particleBuffer,
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: createTrailRenderPassDescriptor()) else {
            Logger.log("guard check in Rendering trails failed", level: .error)
            return
        }

        Logger.log("Rendering trails...", level: .debug)
        let particleCount = SimulationSettings.shared.selectedPreset.particleCount.rawValue

        // No manual position copying needed! BufferManager already maintains it.
        
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(prevPositionsBuffer, offset: 0, index: 1)
        
        Logger.log("✅ Issuing draw call for trails: \(particleCount) particles", level: .debug)
        commandEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        commandEncoder.endEncoding()
    }
    
    private func blendTrails(commandBuffer: MTLCommandBuffer?, view: MTKView) {
                
        guard let pipelineState = blendPipelineState,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandBuffer,
              let trailTexture = trailTexture, // Ensure texture is valid
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        Logger.log("Blending trails...", level: .debug)

        let width = trailTexture.width
        let height = trailTexture.height
        let region = MTLRegionMake2D(0, 0, min(10, width), min(10, height)) // Sample top-left area
        
        var pixelData = [UInt8](repeating: 0, count: 4 * 10 * 10) // BGRA
        trailTexture.getBytes(&pixelData, bytesPerRow: 4 * width, from: region, mipmapLevel: 0)
        
        Logger.log("🔍 Trail Texture First 5 Pixels (BGRA): \(pixelData.prefix(20))", level: .debug)
        Logger.log("🔍 Checking blend trails before encoding end...", level: .debug)
        
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setFragmentTexture(trailTexture, index: 0)
        commandEncoder.setVertexBuffer(quadVertexBuffer, offset: 0, index: 0) // Full-screen quad
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()
        
        Logger.log("trails: ended encoding")
    }
    
    private func createTrailRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = trailTexture
        descriptor.colorAttachments[0].loadAction = .load // Retain previous frame's trails
        descriptor.colorAttachments[0].storeAction = .store // Keep for blending
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0.15)
        return descriptor
    }
}

// Camera Handling
extension Renderer {
    
    private func adjustZoomAndCameraForWorldSize(_ newWorldSize: Float) {
        let baseSize: Float = 1.0
        let minZoom: Float = 0.1
        let maxZoom: Float = 4.5
        
        zoomLevel = min(max(baseSize / newWorldSize, minZoom), maxZoom)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        
        cameraPosition = .zero
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }

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
}

// Mouse Handling
extension Renderer {
    
    /// Handles mouse clicks and perturbs nearby particles
    func handleMouseClick(at location: CGPoint, in view: MTKView, isRightClick: Bool) {
        guard !isPaused else { return }

        let worldPosition = screenToWorld(location, drawableSize: view.drawableSize, viewSize: view.frame.size)
        let effectRadius: Float = isRightClick ? 3.0 : 1.0

        // Send click data to Metal
        BufferManager.shared.updateClickBuffer(clickPosition: worldPosition, force: effectRadius)

        // Reset click persistence timer after 3 frames
        clickPersistenceFrames = 3
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
