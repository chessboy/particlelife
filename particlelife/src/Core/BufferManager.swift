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
    
    // Core Buffers
    private(set) var cameraBuffer: MTLBuffer?
    private(set) var zoomBuffer: MTLBuffer?
    
    // Physics Settings Buffers
    private(set) var deltaTimeBuffer: MTLBuffer?
    private(set) var maxDistanceBuffer: MTLBuffer?
    private(set) var minDistanceBuffer: MTLBuffer?
    private(set) var betaBuffer: MTLBuffer?
    private(set) var frictionBuffer: MTLBuffer?
    private(set) var repulsionBuffer: MTLBuffer?
    private(set) var pointSizeBuffer: MTLBuffer?
    private(set) var worldSizeBuffer: MTLBuffer?
    private(set) var windowSizeBuffer: MTLBuffer?
    private(set) var boundaryVertexBuffer: MTLBuffer?
    private(set) var clickBuffer: MTLBuffer?

    // Particle Buffers
    private(set) var particleCountBuffer: MTLBuffer?
    private(set) var interactionBuffer: MTLBuffer?
    private(set) var speciesCountBuffer: MTLBuffer?
    private(set) var speciesColorOffsetBuffer: MTLBuffer?
    
    private var lastPhysicsSettings: PhysicsSettingsSnapshot?

    var areBuffersInitialized: Bool {
        let requiredBuffers: [MTLBuffer?] = [
            particleCountBuffer, interactionBuffer, speciesCountBuffer, deltaTimeBuffer,
            maxDistanceBuffer, minDistanceBuffer, betaBuffer, frictionBuffer, repulsionBuffer,
            pointSizeBuffer, worldSizeBuffer, windowSizeBuffer, cameraBuffer, zoomBuffer,
            clickBuffer, speciesColorOffsetBuffer
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
        worldSizeBuffer = createBuffer(type: Float.self)
        windowSizeBuffer = createBuffer(type: Float.self, count: 2)
        initializeBoundaryBuffer()
        initializeClickBuffer()
    }
    
    func initializeClickBuffer() {
        guard clickBuffer == nil else { return }
        clickBuffer = createBuffer(type: ClickData.self)

        var defaultClickData = ClickData(position: SIMD2<Float>(0, 0), force: 0.0)
        clickBuffer?.contents().copyMemory(from: &defaultClickData, byteCount: MemoryLayout<ClickData>.stride)
    }
    
    func initializeBoundaryBuffer() {
        let vertexIndices: [UInt32] = [0, 1, 2, 3, 4] // Just indices for 5 vertices
        boundaryVertexBuffer = device.makeBuffer(bytes: vertexIndices, length: MemoryLayout<UInt32>.stride * vertexIndices.count, options: [])
    }

    private func createBuffer<T>(type: T.Type, count: Int = 1) -> MTLBuffer? {
        return device.makeBuffer(length: MemoryLayout<T>.stride * count, options: [])
    }
    
    func initializeParticleBuffers(particles: [Particle], interactionMatrix: [[Float]], speciesCount: Int) {
        // Ensure particle buffer exists
        let particleSize = MemoryLayout<Particle>.stride * particles.count
        if particleCountBuffer == nil || particleCountBuffer!.length != particleSize {
            particleCountBuffer = device.makeBuffer(length: particleSize, options: .storageModeShared)
        }
        particleCountBuffer?.contents().copyMemory(from: particles, byteCount: particleSize)
        
        // Ensure interaction buffer exists
        let flatMatrix = flattenInteractionMatrix(interactionMatrix)
        let matrixSize = MemoryLayout<Float>.stride * flatMatrix.count
        if interactionBuffer == nil || interactionBuffer!.length != matrixSize {
            interactionBuffer = device.makeBuffer(length: matrixSize, options: .storageModeShared)
        }
        interactionBuffer?.contents().copyMemory(from: flatMatrix, byteCount: matrixSize)
        
        // Ensure species count buffer exists
        if speciesCountBuffer == nil {
            speciesCountBuffer = createBuffer(type: Int.self)
        }
        updateSpeciesCountBuffer(speciesCount: speciesCount)
    }
    
    private func flattenInteractionMatrix(_ matrix: [[Float]]) -> [Float] {
        return matrix.flatMap { $0 }
    }
    
    func clearParticleBuffers() {
        particleCountBuffer = nil
        interactionBuffer = nil
        speciesCountBuffer = nil
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
            speciesColorOffset: settings.speciesColorOffset
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
    }
    
    func updateParticleBuffer(particles: [Particle]) {
        let expectedSize = particles.count * MemoryLayout<Particle>.stride
        
        if particleCountBuffer == nil || particleCountBuffer!.length != expectedSize {
            particleCountBuffer = device.makeBuffer(length: expectedSize, options: .storageModeShared)
        }
        
        guard let buffer = particleCountBuffer else { return }
        buffer.contents().copyMemory(from: particles, byteCount: expectedSize)
    }
    
    func updateInteractionBuffer(interactionMatrix: [[Float]]) {
        guard let interactionBuffer = interactionBuffer else { return }
        let flatMatrix = flattenInteractionMatrix(interactionMatrix)
        interactionBuffer.contents().copyMemory(from: flatMatrix, byteCount: flatMatrix.count * MemoryLayout<Float>.stride)
    }
    
    func updateSpeciesCountBuffer(speciesCount: Int) {
        updateBuffer(speciesCountBuffer, with: speciesCount)
    }
    
    func updateSpeciesColorOffsetBuffer(speciesColorOffset: Int) {
        updateBuffer(speciesColorOffsetBuffer, with: speciesColorOffset)
    }
    
    func updateDeltaTimeBuffer(dt: inout Float) {
        updateBuffer(deltaTimeBuffer, with: dt)
    }
    
    func updateWindowSizeBuffer(width: Float, height: Float) {
        let windowSize = SIMD2<Float>(width, height)
        updateBuffer(windowSizeBuffer, with: windowSize)
    }
    
    func updateInteractionMatrix(matrix: [[Float]], speciesCount: Int) {
        let flatMatrix = flattenInteractionMatrix(matrix)
        let matrixSize = flatMatrix.count * MemoryLayout<Float>.stride
        
        if interactionBuffer == nil || interactionBuffer!.length != matrixSize {
            interactionBuffer = device.makeBuffer(length: matrixSize, options: [])
        }
        interactionBuffer?.contents().copyMemory(from: flatMatrix, byteCount: matrixSize)
        
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

    /// Compare two snapshots
    func isEqual(to other: PhysicsSettingsSnapshot) -> Bool {
        return maxDistance == other.maxDistance &&
               minDistance == other.minDistance &&
               beta == other.beta &&
               friction == other.friction &&
               repulsion == other.repulsion &&
               pointSize == other.pointSize &&
               worldSize == other.worldSize &&
               speciesColorOffset == other.speciesColorOffset
    }
}
