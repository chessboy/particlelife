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
    
    // Expose simulationManager so SwiftUI views can observe it directly.
    private let simulationManager: SimulationManager
    private var frameCount: UInt32 = 0
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    
    private var computePass: ComputePass?
    private var renderPass: RenderPass?
    
    private var cancellables = Set<AnyCancellable>()
    private weak var fpsMonitor: FPSMonitor?
    
    init(metalView: MTKView, fpsMonitor: FPSMonitor, simulationManager: SimulationManager) {
        self.fpsMonitor = fpsMonitor
        self.simulationManager = simulationManager
        super.init()
        
        metalView.delegate = self
        metalView.enableSetNeedsDisplay = false
        metalView.preferredFramesPerSecond = SystemCapabilities.shared.preferredFramesPerSecond
        
        self.device = metalView.device
        self.commandQueue = device?.makeCommandQueue()
        
        if let device = self.device, let library = device.makeDefaultLibrary() {
            self.computePass = ComputePass(device: device, library: library)
            self.renderPass = RenderPass(device: device, library: library)
        } else {
            Logger.log("Failed to initialize Metal resources.", level: .error)
        }
        
        // Forward changes from simulationManager so Renderer emits its own change notifications.
        simulationManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    func resetFrameCount() {
        frameCount = 0
        BufferManager.shared.updateFrameCountBuffer(frameCount: frameCount)
    }
    
    func draw(in view: MTKView) {
        let bufferManager = BufferManager.shared
        
        guard !simulationManager.isPaused,
              bufferManager.areBuffersInitialized,
              let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        updateSimulationState()
        
        frameCount &+= 1
        bufferManager.updateFrameCountBuffer(frameCount: frameCount)
        
        computePass?.encode(commandBuffer: commandBuffer, bufferManager: bufferManager)
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor,
           let drawable = view.currentDrawable {
            renderPass?.encode(commandBuffer: commandBuffer,
                               renderPassDescriptor: renderPassDescriptor,
                               drawable: drawable,
                               bufferManager: bufferManager)
        }
        
        commandBuffer.commit()
    }
    
    private func updateSimulationState() {
        DispatchQueue.main.async {
            self.fpsMonitor?.frameRendered()
        }
        simulationManager.update()
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
