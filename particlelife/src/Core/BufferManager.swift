//
//  BufferManager.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import Metal
import simd

class BufferManager {
    static let shared = BufferManager()
    
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    
    // Particle & Matrix Buffers
    private(set) var particleBuffer: MTLBuffer?
    private(set) var matrixBuffer: MTLBuffer?
    private var particleBuffers: [MTLBuffer?] = [nil, nil]  // Double buffering for particles
    private var matrixBuffers: [MTLBuffer?] = [nil, nil]  // Double buffering for the matrix
    private var activeBufferIndex = 0  // Tracks which buffer is in use

    // UI Buffers
    private(set) var deltaTimeBuffer: MTLBuffer?
    private(set) var frameCountBuffer: MTLBuffer?
    private(set) var speciesCountBuffer: MTLBuffer?
    private(set) var clickBuffer: MTLBuffer?
    private(set) var settingsBuffer: MTLBuffer?
    private(set) var renderSettingsBuffer: MTLBuffer?

    // Settings Model
    private var lastSettings: PhysicsSettings? // Prevent unecessary buffer copy if nothing's changed
    private var renderSettings: RenderSettings = RenderSettings()

    var areBuffersInitialized: Bool {
        let requiredBuffers: [MTLBuffer?] = [
            frameCountBuffer, particleBuffer, matrixBuffer, speciesCountBuffer, deltaTimeBuffer,
            settingsBuffer, renderSettingsBuffer, clickBuffer
        ]
        return requiredBuffers.allSatisfy { $0 != nil }
    }
    
    private init() {
        guard let metalDevice = MTLCreateSystemDefaultDevice(),
              let queue = metalDevice.makeCommandQueue() else {
            fatalError("ERROR: Failed to initialize Metal device or command queue.")
        }
        self.device = metalDevice
        self.commandQueue = queue
        
        initializeBuffers()
    }
    
}

// Initialize all buffers
extension BufferManager {
    private func createBuffer<T>(type: T.Type, count: Int = 1) -> MTLBuffer? {
        return device.makeBuffer(length: MemoryLayout<T>.stride * count, options: [])
    }

    private func initializeBuffers() {
        speciesCountBuffer = createBuffer(type: UInt32.self)
        frameCountBuffer = createBuffer(type: UInt32.self)
        deltaTimeBuffer = createBuffer(type: Float.self)
        renderSettingsBuffer = createBuffer(type: RenderSettings.self)
        settingsBuffer = createBuffer(type: PhysicsSettings.self)
        
        clickBuffer = createBuffer(type: ClickData.self)
        clearClickBuffer()
    }
}

// Buffer Updates
extension BufferManager {
    
    func updateSpeciesCountBuffer(speciesCount: Int) {
        updateBuffer(speciesCountBuffer, with: speciesCount)
    }
        
    func updateDeltaTimeBuffer(dt: inout Float) {
        updateBuffer(deltaTimeBuffer, with: dt)
    }
        
    func updateFrameCountBuffer(frameCount: UInt32) {
        updateBuffer(frameCountBuffer, with: frameCount)
    }

    func clearClickBuffer() {
        updateClickBuffer(clickPosition: .zero, force: .zero)
    }
    
    func updateClickBuffer(clickPosition: SIMD2<Float>, force: Float) {
        updateBuffer(clickBuffer, with: ClickData(position: clickPosition, force: force))
    }
    
    func updateCameraBuffer(cameraPosition: SIMD2<Float>) {
        renderSettings.cameraPosition = cameraPosition
        updateBuffer(renderSettingsBuffer, with: renderSettings)
    }
    
    func updateZoomBuffer(zoomLevel: Float) {
        renderSettings.zoomLevel = zoomLevel
        updateBuffer(renderSettingsBuffer, with: renderSettings)
    }
    
    func updateWindowSizeBuffer(width: Float, height: Float) {
        renderSettings.windowSize = SIMD2<Float>(width, height)
        updateBuffer(renderSettingsBuffer, with: renderSettings)
    }
    
    func updatePointSize(pointSize: Float) {
        renderSettings.pointSize = pointSize
        updateBuffer(renderSettingsBuffer, with: renderSettings)
    }

    func updateColorOffset(colorOffset: Int) {
        renderSettings.colorOffset = UInt32(colorOffset)
        updateBuffer(renderSettingsBuffer, with: renderSettings)
    }
    
    func updatePaletteIndex(paletteIndex: Int) {
        renderSettings.paletteIndex = UInt32(paletteIndex)
        updateBuffer(renderSettingsBuffer, with: renderSettings)
    }

    func updateColorEffect(colorEffect: ColorEffect) {
        renderSettings.colorEffect = colorEffect.rawValue
        updateBuffer(renderSettingsBuffer, with: renderSettings)
    }
    
    func updatePhysicsBuffers() {
        let settings = SimulationSettings.shared
        let currentSettings = PhysicsSettings(
            maxDistance: settings.maxDistance.value,
            minDistance: settings.minDistance.value,
            beta: settings.beta.value,
            friction: settings.friction.value,
            repulsion: settings.repulsion.value,
            worldSize: settings.worldSize.value
        )
        
        if let last = lastSettings, last == currentSettings {
            return // No change, skip update
        }
        
        lastSettings = currentSettings
        //Logger.log("Updated settings", level: .debug, showCaller: true)
        updateBuffer(settingsBuffer, with: currentSettings)
    }
    
    func updateMatrixBuffer(matrix: [[Float]]) {
        guard let matrixBuffer = matrixBuffer else { return }
        let flatMatrix = flattenMatrix(matrix)
        matrixBuffer.contents().copyMemory(from: flatMatrix, byteCount: flatMatrix.count * MemoryLayout<Float>.stride)
    }

    func updateParticleBuffers(particles: [Particle], matrix: [[Float]], speciesCount: Int) {
        let particleSize = MemoryLayout<Particle>.stride * particles.count
        let flatMatrix = flattenMatrix(matrix)
        let matrixSize = MemoryLayout<Float>.stride * flatMatrix.count

        // Ensure both particle buffers exist or are resized
        if particleBuffers[0] == nil || particleBuffers[0]!.length != particleSize {
            particleBuffers[0] = device.makeBuffer(length: particleSize, options: .storageModeShared)
            particleBuffers[1] = device.makeBuffer(length: particleSize, options: .storageModeShared)
        }

        // Ensure both matrix buffers exist or are resized
        if matrixBuffers[0] == nil || matrixBuffers[0]!.length != matrixSize {
            matrixBuffers[0] = device.makeBuffer(length: matrixSize, options: .storageModeShared)
            matrixBuffers[1] = device.makeBuffer(length: matrixSize, options: .storageModeShared)
        }

        // Write to the inactive buffers
        let inactiveParticleBuffer = particleBuffers[1 - activeBufferIndex]!
        inactiveParticleBuffer.contents().copyMemory(from: particles, byteCount: particleSize)

        let inactiveMatrixBuffer = matrixBuffers[1 - activeBufferIndex]!
        inactiveMatrixBuffer.contents().copyMemory(from: flatMatrix, byteCount: matrixSize)

        // Swap buffers
        activeBufferIndex = 1 - activeBufferIndex

        // Update the active buffers
        particleBuffer = particleBuffers[activeBufferIndex]
        matrixBuffer = matrixBuffers[activeBufferIndex]

        // No need to recreate species count buffer
        updateSpeciesCountBuffer(speciesCount: speciesCount)
    }
}

extension BufferManager {
    
    private func flattenMatrix(_ matrix: [[Float]]) -> [Float] {
        return matrix.flatMap { $0 }
    }

    private func updateBuffer<T>(_ buffer: MTLBuffer?, with value: T) {
        guard let buffer = buffer else { return }
        withUnsafeBytes(of: value) { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            memcpy(buffer.contents(), baseAddress, MemoryLayout<T>.stride)
        }
    }
}
