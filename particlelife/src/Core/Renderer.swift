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

    @Published var isPaused: Bool = false
    
    var cameraPosition: simd_float2 = .zero
    var zoomLevel: Float = 1.0
    
    private var frameCount: UInt32 = 0
    private var clickPersistenceFrames: Int = 0
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var particleSystem: ParticleSystem!
    
    private var pipelineState: MTLRenderPipelineState?
    private var computePipeline: MTLComputePipelineState?
    
    private var cancellables = Set<AnyCancellable>()
    private var worldSizeObserver: AnyCancellable?
            
    init(metalView: MTKView? = nil, fpsMonitor: FPSMonitor) {
        self.fpsMonitor = fpsMonitor

        #if arch(arm64)
        Logger.log("Running on  Silicon")
        #else
        Logger.log("Running on Intel")
        #endif

        super.init()
        
        if SystemCapabilities.isRunningOnProperGPU {
            Logger.log("Running on a dedicated GPU", level: .debug)
        } else {
            Logger.log("Running on CPU fallback – performance may be severely impacted.", level: .warning)
            // Alert user this will not be fun (delay 1 second)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: .lowPerformanceWarning, object: nil)
            }
        }

        if let metalView = metalView {
            self.device = metalView.device
            metalView.delegate = self
            metalView.enableSetNeedsDisplay = false
            metalView.preferredFramesPerSecond = 60
            Logger.log("Metal device initialized successfully", level: .debug)
        } else {
            Logger.log("Running in Preview Mode - Metal Rendering Disabled", level: .warning)
        }
        
        self.commandQueue = device?.makeCommandQueue()
        self.particleSystem = ParticleSystem.shared
        setupPipelines()
        
        // listeners
        // NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        
        worldSizeObserver = SimulationSettings.shared.$worldSize.sink { [weak self] newWorldSize in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self?.adjustZoomAndCameraForWorldSize(newWorldSize.value)
            }
        }
        
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
    private func setupPipelines() {
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
            pipelineState = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
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
        
        frameCount &+= 1 // will wrap when hits UInt32.max
        BufferManager.shared.updateFrameCountBuffer(frameCount: frameCount)
        
        runComputePass(commandBuffer: commandBuffer)
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
        
        computeEncoder.setComputePipelineState(computePipeline)
        
        let bufferManager: BufferManager = BufferManager.shared
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
        renderEncoder.setVertexBuffer(bufferManager.frameCountBuffer, offset: 0, index: 7)
        renderEncoder.setVertexBuffer(bufferManager.colorEffectIndexBuffer, offset: 0, index: 8)
        renderEncoder.setVertexBuffer(bufferManager.speciesCountBuffer, offset: 0, index: 9)

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
        guard size.width > 0 && size.height > 0 else { return }

        let expectedAspectRatio: CGFloat = Constants.ASPECT_RATIO
        var correctedSize = size
        
        if abs((size.width / size.height) - expectedAspectRatio) > 0.01 {
            correctedSize = size.width > size.height * expectedAspectRatio
            ? CGSize(width: size.height * expectedAspectRatio, height: size.height)
            : CGSize(width: size.width, height: size.width / expectedAspectRatio)
            
//            Logger.log("Drawable size corrected: "
//                       + "Original: \(size.width)x\(size.height), "
//                       + "View Bounds: \(view.bounds.size), "
//                       + "Corrected: \(correctedSize.width)x\(correctedSize.height), "
//                       + "Computed Aspect Ratio: \(correctedSize.width / correctedSize.height), "
//                       + "FPS Check: \(view.preferredFramesPerSecond)",
//                       level: .debug)
        }
        BufferManager.shared.updateWindowSizeBuffer(width: Float(correctedSize.width), height: Float(correctedSize.height))
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
