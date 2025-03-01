//
//  BufferManager.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import Metal
import simd

struct ClickData {
    var position: SIMD2<Float>
    var force: Float
}

class BufferManager {
    static let shared = BufferManager()
    
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    
    // UI Buffers
    private(set) var deltaTimeBuffer: MTLBuffer?
    private(set) var cameraBuffer: MTLBuffer?
    private(set) var zoomBuffer: MTLBuffer?
    private(set) var clickBuffer: MTLBuffer?
    private(set) var windowSizeBuffer: MTLBuffer?

    // Physics Settings Buffers
    private(set) var maxDistanceBuffer: MTLBuffer?
    private(set) var minDistanceBuffer: MTLBuffer?
    private(set) var betaBuffer: MTLBuffer?
    private(set) var frictionBuffer: MTLBuffer?
    private(set) var repulsionBuffer: MTLBuffer?
    private(set) var pointSizeBuffer: MTLBuffer?
    private(set) var worldSizeBuffer: MTLBuffer?

    // Particle & Matrix Buffers
    private(set) var particleBuffer: MTLBuffer?
    private(set) var matrixBuffer: MTLBuffer?
    private var particleBuffers: [MTLBuffer?] = [nil, nil]  // Double buffering for particles
    private var matrixBuffers: [MTLBuffer?] = [nil, nil]  // Double buffering for the matrix
    private var activeBufferIndex = 0  // Tracks which buffer is in use

    private(set) var speciesCountBuffer: MTLBuffer?
    private(set) var speciesColorOffsetBuffer: MTLBuffer?
    private(set) var paletteIndexBuffer: MTLBuffer?

    // prevent unecessary buffer copy if nothing's changed
    private var lastPhysicsSettings: PhysicsSettingsSnapshot?

    var areBuffersInitialized: Bool {
        let requiredBuffers: [MTLBuffer?] = [
            particleBuffer, matrixBuffer, speciesCountBuffer, deltaTimeBuffer,
            maxDistanceBuffer, minDistanceBuffer, betaBuffer, frictionBuffer, repulsionBuffer,
            pointSizeBuffer, worldSizeBuffer, windowSizeBuffer, cameraBuffer, zoomBuffer,
            clickBuffer, speciesColorOffsetBuffer, paletteIndexBuffer
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
    
    // Initialize all physics-related buffers
    private func initializeBuffers() {
        deltaTimeBuffer = createBuffer(type: Float.self)
        maxDistanceBuffer = createBuffer(type: Float.self)
        minDistanceBuffer = createBuffer(type: Float.self)
        betaBuffer = createBuffer(type: Float.self)
        frictionBuffer = createBuffer(type: Float.self)
        repulsionBuffer = createBuffer(type: Float.self)
        cameraBuffer = createBuffer(type: SIMD2<Float>.self)
        zoomBuffer = createBuffer(type: Float.self)
        pointSizeBuffer = createBuffer(type: Float.self)
        speciesColorOffsetBuffer = createBuffer(type: Int.self)
        paletteIndexBuffer = createBuffer(type: Int.self)
        worldSizeBuffer = createBuffer(type: Float.self)
        windowSizeBuffer = createBuffer(type: Float.self, count: 2)
        speciesCountBuffer = createBuffer(type: Int.self)
        initializeClickBuffer()
    }
    
    private func createBuffer<T>(type: T.Type, count: Int = 1) -> MTLBuffer? {
        return device.makeBuffer(length: MemoryLayout<T>.stride * count, options: [])
    }

    func initializeClickBuffer() {
        guard clickBuffer == nil else { return }
        clickBuffer = createBuffer(type: ClickData.self)
        var defaultClickData = ClickData(position: SIMD2<Float>(0, 0), force: 0.0)
        clickBuffer?.contents().copyMemory(from: &defaultClickData, byteCount: MemoryLayout<ClickData>.stride)
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

    private func flattenMatrix(_ matrix: [[Float]]) -> [Float] {
        return matrix.flatMap { $0 }
    }
}

// Buffer Updates
extension BufferManager {
    
    func updateClickBuffer(clickPosition: SIMD2<Float>, force: Float, clear: Bool = false) {
        var clickData = clear ? ClickData(position: SIMD2<Float>(0, 0), force: 0.0) :
        ClickData(position: clickPosition, force: force)
        
        guard let buffer = clickBuffer else { return }
        
        memcpy(buffer.contents(), &clickData, MemoryLayout<ClickData>.stride)
    }
    
    func updateCameraBuffer(cameraPosition: SIMD2<Float>) {
        updateBuffer(cameraBuffer, with: cameraPosition)
    }
    
    func updateZoomBuffer(zoomLevel: Float) {
        updateBuffer(zoomBuffer, with: zoomLevel)
    }
    
    func updatePhysicsBuffers() {
        let settings = SimulationSettings.shared
        let currentSettings = PhysicsSettingsSnapshot(
            maxDistance: settings.maxDistance.value,
            minDistance: settings.minDistance.value,
            beta: settings.beta.value,
            friction: settings.friction.value,
            repulsion: settings.repulsion.value,
            pointSize: settings.pointSize.value,
            worldSize: settings.worldSize.value,
            speciesColorOffset: settings.speciesColorOffset,
            paletteIndex: settings.paletteIndex
        )
        
        if let last = lastPhysicsSettings, last.isEqual(to: currentSettings) {
            return // 🚀 No change, skip update
        }
        
        lastPhysicsSettings = currentSettings
        
        Logger.log("Updated physics buffers", level: .debug, showCaller: true)
        
        updateBuffer(maxDistanceBuffer, with: settings.maxDistance)
        updateBuffer(minDistanceBuffer, with: settings.minDistance)
        updateBuffer(betaBuffer, with: settings.beta)
        updateBuffer(frictionBuffer, with: settings.friction)
        updateBuffer(repulsionBuffer, with: settings.repulsion)
        updateBuffer(pointSizeBuffer, with: settings.pointSize)
        updateBuffer(worldSizeBuffer, with: settings.worldSize)
        updateBuffer(speciesColorOffsetBuffer, with: settings.speciesColorOffset)
        updateBuffer(paletteIndexBuffer, with: settings.paletteIndex)
    }
        
    func updateMatrixBuffer(matrix: [[Float]]) {
        guard let matrixBuffer = matrixBuffer else { return }
        let flatMatrix = flattenMatrix(matrix)
        matrixBuffer.contents().copyMemory(from: flatMatrix, byteCount: flatMatrix.count * MemoryLayout<Float>.stride)
    }
    
    func updateSpeciesCountBuffer(speciesCount: Int) {
        updateBuffer(speciesCountBuffer, with: speciesCount)
    }
        
    func updateDeltaTimeBuffer(dt: inout Float) {
        updateBuffer(deltaTimeBuffer, with: dt)
    }
    
    func updateWindowSizeBuffer(width: Float, height: Float) {
        let windowSize = SIMD2<Float>(width, height)
        updateBuffer(windowSizeBuffer, with: windowSize)
    }
    
    func updateMatrixAndSpeciesCount(matrix: [[Float]], speciesCount: Int) {
        let flatMatrix = flattenMatrix(matrix)
        let matrixSize = flatMatrix.count * MemoryLayout<Float>.stride
        
        if matrixBuffer == nil || matrixBuffer!.length != matrixSize {
            matrixBuffer = device.makeBuffer(length: matrixSize, options: [])
        }
        matrixBuffer?.contents().copyMemory(from: flatMatrix, byteCount: matrixSize)
        
        updateSpeciesCountBuffer(speciesCount: speciesCount)
    }
    
    private func updateBuffer<T>(_ buffer: MTLBuffer?, with value: T) {
        guard let buffer = buffer else { return }
        withUnsafeBytes(of: value) { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            buffer.contents().copyMemory(from: baseAddress, byteCount: MemoryLayout<T>.stride)
        }
    }
    
    // Overload for SIMD types (SIMD2<Float>, etc.)
    private func updateBuffer<T: SIMD>(_ buffer: MTLBuffer?, with value: T) {
        guard let buffer = buffer else { return }
        withUnsafeBytes(of: value) { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            buffer.contents().copyMemory(from: baseAddress, byteCount: MemoryLayout<T>.stride)
        }
    }
}

struct PhysicsSettingsSnapshot {
    let maxDistance: Float
    let minDistance: Float
    let beta: Float
    let friction: Float
    let repulsion: Float
    let pointSize: Float
    let worldSize: Float
    let speciesColorOffset: Int
    let paletteIndex: Int
    
    /// Compare two snapshots
    func isEqual(to other: PhysicsSettingsSnapshot) -> Bool {
        return maxDistance == other.maxDistance &&
        minDistance == other.minDistance &&
        beta == other.beta &&
        friction == other.friction &&
        repulsion == other.repulsion &&
        pointSize == other.pointSize &&
        worldSize == other.worldSize &&
        speciesColorOffset == other.speciesColorOffset &&
        paletteIndex == other.paletteIndex
    }
}
