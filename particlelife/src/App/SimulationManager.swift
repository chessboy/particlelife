//
//  SimulationManager.swift
//  particlelife
//
//  Created by Rob Silverman on 3/21/25.
//

import Foundation
import simd
import CoreGraphics
import Combine

class SimulationManager: ObservableObject {
    @Published var isPaused: Bool = false
    
    private var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970
    private var lastDT: Float = 0.001

    // Camera and zoom state.
    var cameraPosition: SIMD2<Float> = .zero {
        didSet {
            BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
        }
    }
    var zoomLevel: Float = 1.0 {
        didSet {
            BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        }
    }
    
    private var clickPersistenceFrames: Int = -1
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to changes in worldSize.
        SimulationSettings.shared.$worldSize
            .sink { [weak self] newWorldSize in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self?.adjustZoomAndCameraForWorldSize(newWorldSize.value)
                }
            }
            .store(in: &cancellables)
        
        checkSystemCapabilities()
    }
    
    func togglePaused() {
        isPaused.toggle()
    }
    
    /// Updates delta time for particle movement
    func update() {
        let currentTime = Date().timeIntervalSince1970
        var dt = Float(currentTime - lastUpdateTime)
        dt = max(0.0001, min(dt, 0.0105)) // Clamp dt was 0.01
        
        let smoothingFactor = SystemCapabilities.shared.smoothingFactor
        
        dt = (1.0 - smoothingFactor) * lastDT + smoothingFactor * dt
        
        // Quantize dt to avoid micro jitter
        let quantizationStep: Float = 0.0004 // was 0.0005
        dt = round(dt / quantizationStep) * quantizationStep
        
        if abs(dt - lastDT) > 0.00005 {
            BufferManager.shared.updateDeltaTimeBuffer(dt: &dt)
            lastDT = dt
        }
        lastUpdateTime = currentTime

        monitorClickBuffer()
    }
    
    private func monitorClickBuffer() {
        if clickPersistenceFrames > 0 {
            clickPersistenceFrames -= 1
        } else if clickPersistenceFrames == 0 {
            BufferManager.shared.clearClickBuffer()
            clickPersistenceFrames = -1
        }
    }
    
    func handleMouseClick(at worldPosition: SIMD2<Float>, effectRadius: Float) {
        BufferManager.shared.updateClickBuffer(clickPosition: worldPosition, force: effectRadius)
        clickPersistenceFrames = 3
    }
    
    func screenToWorld(screenPosition: CGPoint, drawableSize: CGSize, viewSize: CGSize) -> SIMD2<Float> {
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
        return SIMD2<Float>(worldX, worldY) / zoomLevel + cameraPosition
    }
    
    // MARK: - World Size & Camera Adjustment
    
    /// Adjusts zoom level and resets camera position based on the new world size.
    func adjustZoomAndCameraForWorldSize(_ newWorldSize: Float) {
        //Logger.log("adjusting zoom and camera: \(newWorldSize)", level: .debug)
        
        let baseSize: Float = 1.0
        let minZoom: Float = 0.1
        let maxZoom: Float = 4.5
        
        zoomLevel = min(max(baseSize / newWorldSize, minZoom), maxZoom)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        
        cameraPosition = .zero
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    /// Resets pan and zoom. (Called e.g., from a key event.)
    func resetPanAndZoom() {
        guard !isPaused else { return }
        zoomLevel = 1.0
        cameraPosition = .zero
        adjustZoomAndCameraForWorldSize(SimulationSettings.shared.worldSize.value)
        BufferManager.shared.updateZoomBuffer(zoomLevel: zoomLevel)
        BufferManager.shared.updateCameraBuffer(cameraPosition: cameraPosition)
    }
    
    // MARK: - Camera & Zoom Manipulation
    
    func pan(by delta: SIMD2<Float>) {
        cameraPosition += delta
    }
    
    func zoomIn(step: Float) {
        zoomLevel *= step
    }
    
    func zoomOut(step: Float) {
        zoomLevel /= step
    }
}

extension SimulationManager {
    
    func checkSystemCapabilities() {
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
    }
}
