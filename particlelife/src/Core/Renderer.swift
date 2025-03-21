//
//  Renderer.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Foundation
import MetalKit
import Combine

struct UIControlConstants {
    static let zoomStep: Float = 1.01
    static let panStep: Float = 0.01
}

class Renderer: NSObject, MTKViewDelegate, ObservableObject {
    
    private weak var fpsMonitor: FPSMonitor?
    @Published private(set) var isPaused: Bool = false
    
    var cameraPosition: simd_float2 = .zero
    var zoomLevel: Float = 1.0
    
    private var frameCount: UInt32 = 0
    private var clickPersistenceFrames: Int = 0
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    
    private var computePass: ComputePass?
    private var renderPass: RenderPass?
    
    private var cancellables = Set<AnyCancellable>()
    private var worldSizeObserver: AnyCancellable?
            
    init(metalView: MTKView? = nil, fpsMonitor: FPSMonitor) {
        self.fpsMonitor = fpsMonitor
        super.init()
        
        // System capability logging.
        if SystemCapabilities.shared.gpuType == .dedicatedGPU {
            Logger.log("Running on a dedicated GPU", level: .debug)
        } else if SystemCapabilities.shared.gpuType == .cpuOnly {
            Logger.log("No compatible GPU found – running on CPU fallback. Performance will be severely impacted.", level: .warning)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NotificationCenter.default.post(name: .lowPerformanceWarning, object: nil)
            }
        } else {
            Logger.log("Running on a low-power GPU – expect reduced performance.", level: .warning)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                NotificationCenter.default.post(name: .lowPerformanceWarning, object: nil)
            }
        }
        
        if let metalView = metalView {
            self.device = metalView.device
            metalView.delegate = self
            metalView.enableSetNeedsDisplay = false
            metalView.preferredFramesPerSecond = SystemCapabilities.shared.preferredFramesPerSecond
            Logger.log("Metal device initialized successfully", level: .debug)
        } else {
            Logger.log("Running in Preview Mode - Metal Rendering Disabled", level: .warning)
        }
        
        self.commandQueue = device?.makeCommandQueue()
        
        // Instantiate ComputePass and RenderPass.
        if let device = self.device, let library = device.makeDefaultLibrary() {
            self.computePass = ComputePass(device: device, library: library)
            self.renderPass = RenderPass(device: device, library: library)
        }
        
        worldSizeObserver = SimulationSettings.shared.$worldSize.sink { [weak self] newWorldSize in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self?.adjustZoomAndCameraForWorldSize(newWorldSize.value)
            }
        }
    }
            
    func resetFrameCount() {
        self.frameCount = 0
        BufferManager.shared.updateFrameCountBuffer(frameCount: frameCount)
    }
    
    func togglePaused() {
        fpsMonitor?.togglePaused()
        isPaused.toggle()
    }
    
    func draw(in view: MTKView) {
        guard !isPaused,
              BufferManager.shared.areBuffersInitialized,
              let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        updateSimulationState()
        
        frameCount &+= 1
        BufferManager.shared.updateFrameCountBuffer(frameCount: frameCount)
        
        // Run compute pass.
        computePass?.encode(commandBuffer: commandBuffer, bufferManager: BufferManager.shared)
        
        // Run render pass.
        if let renderPassDescriptor = view.currentRenderPassDescriptor,
           let drawable = view.currentDrawable {
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
            renderPass?.encode(commandBuffer: commandBuffer,
                               renderPassDescriptor: renderPassDescriptor,
                               drawable: drawable,
                               bufferManager: BufferManager.shared)
        }
        
        commandBuffer.commit()
    }
    
    private func updateSimulationState() {
        DispatchQueue.main.async {
            self.fpsMonitor?.frameRendered()
        }
        ParticleSystem.shared.update()
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        monitorClickBuffer()
    }
    
    func monitorClickBuffer() {
        if clickPersistenceFrames > 0 {
            clickPersistenceFrames -= 1
        } else if clickPersistenceFrames == 0 {
            BufferManager.shared.updateClickBuffer(clickPosition: SIMD2<Float>(0, 0), force: 0.0, clear: true)
            clickPersistenceFrames = -1
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        let expectedAspectRatio: CGFloat = ASPECT_RATIO
        var correctedSize = size
        
        if abs((size.width / size.height) - expectedAspectRatio) > 0.01 {
            correctedSize = size.width > size.height * expectedAspectRatio
                ? CGSize(width: size.height * expectedAspectRatio, height: size.height)
                : CGSize(width: size.width, height: size.width / expectedAspectRatio)
        }
        
        BufferManager.shared.updateWindowSizeBuffer(width: Float(correctedSize.width), height: Float(correctedSize.height))
    }
}

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
        zoomLevel *= UIControlConstants.zoomStep
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
    }
    
    func zoomOut() {
        guard !isPaused else { return }
        zoomLevel /= UIControlConstants.zoomStep
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
    }
    
    func panLeft() {
        guard !isPaused else { return }
        cameraPosition.x -= UIControlConstants.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func panRight() {
        guard !isPaused else { return }
        cameraPosition.x += UIControlConstants.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func panUp() {
        guard !isPaused else { return }
        cameraPosition.y += UIControlConstants.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    func panDown() {
        guard !isPaused else { return }
        cameraPosition.y -= UIControlConstants.panStep / zoomLevel
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    private func updateCamera() {
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
}

extension Renderer {
    func handleMouseClick(at location: CGPoint, in view: MTKView, isRightClick: Bool) {
        guard !isPaused else { return }
        let worldPosition = screenToWorld(location, drawableSize: view.drawableSize, viewSize: view.frame.size)
        let effectRadius: Float = isRightClick ? 3.0 : 1.0
        BufferManager.shared.updateClickBuffer(clickPosition: worldPosition, force: effectRadius)
        clickPersistenceFrames = 3
    }
    
    func screenToWorld(_ screenPosition: CGPoint, drawableSize: CGSize, viewSize: CGSize) -> SIMD2<Float> {
        let retinaScale = Float(drawableSize.width) / Float(viewSize.width)
        let scaledWidth = Float(drawableSize.width) / retinaScale
        let scaledHeight = Float(drawableSize.height) / retinaScale
        let aspectRatio = scaledWidth / scaledHeight
        let normalizedX = Float(screenPosition.x) / scaledWidth
        let normalizedY = Float(screenPosition.y) / scaledHeight
        let ndcX = (2.0 * normalizedX) - 1.0
        let ndcY = (2.0 * normalizedY) - 1.0
        let worldX = ndcX * aspectRatio
        let worldY = ndcY
        let worldPos = SIMD2<Float>(worldX, worldY) / zoomLevel + cameraPosition
        return worldPos
    }
}
