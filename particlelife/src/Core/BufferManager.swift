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
    private(set) var boundaryVertexBuffer: MTLBuffer?
    private(set) var clickBuffer: MTLBuffer?

    // Particle Buffers
    private(set) var particleCountBuffer: MTLBuffer?
    private(set) var interactionBuffer: MTLBuffer?
    private(set) var speciesCountBuffer: MTLBuffer?
    private(set) var speciesColorOffsetBuffer: MTLBuffer?
    
    var areBuffersInitialized: Bool {
        return particleCountBuffer != nil &&
        interactionBuffer != nil &&
        speciesCountBuffer != nil &&
        deltaTimeBuffer != nil &&
        maxDistanceBuffer != nil &&
        minDistanceBuffer != nil &&
        betaBuffer != nil &&
        frictionBuffer != nil &&
        repulsionBuffer != nil &&
        pointSizeBuffer != nil &&
        worldSizeBuffer != nil &&
        cameraBuffer != nil &&
        zoomBuffer != nil &&
        clickBuffer != nil &&
        speciesColorOffsetBuffer != nil
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
        initializeBoundaryBuffer()
        updateClickBuffer(clickPosition: SIMD2<Float>(0, 0), force: 0.0)

        updatePhysicsBuffers()
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
    
    func readClickBuffer() -> ClickData? {
        guard let buffer = clickBuffer else { return nil } // Ensure buffer exists
        let pointer = buffer.contents().bindMemory(to: ClickData.self, capacity: 1)
        return pointer.pointee // Return the struct stored in the buffer
    }
}

// Buffer Updates
extension BufferManager {
    
    func updateClickBuffer(clickPosition: SIMD2<Float>, force: Float, clear: Bool = false) {
        var clickData = clear ? ClickData(position: SIMD2<Float>(0, 0), force: 0.0) :
                                ClickData(position: clickPosition, force: force)

        if clickBuffer == nil {
            clickBuffer = device.makeBuffer(length: MemoryLayout<ClickData>.stride, options: [])
        }

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
            buffer.contents().copyMemory(from: rawBuffer.baseAddress!, byteCount: MemoryLayout<T>.stride)
        }
    }
    
    // Overload for SIMD types (SIMD2<Float>, etc.)
    private func updateBuffer<T: SIMD>(_ buffer: MTLBuffer?, with value: T) {
        guard let buffer = buffer else { return }
        withUnsafeBytes(of: value) { rawBuffer in
            buffer.contents().copyMemory(from: rawBuffer.baseAddress!, byteCount: MemoryLayout<T>.stride)
        }
    }
}
