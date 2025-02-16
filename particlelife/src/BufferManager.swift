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
    
    // Core Buffers
    private(set) var cameraBuffer: MTLBuffer?
    private(set) var zoomBuffer: MTLBuffer?

    // Physics Settings Buffers
    private(set) var deltaTimeBuffer: MTLBuffer?
    private(set) var maxDistanceBuffer: MTLBuffer?
    private(set) var minDistanceBuffer: MTLBuffer?
    private(set) var betaBuffer: MTLBuffer?
    private(set) var frictionBuffer: MTLBuffer?
    private(set) var repulsionStrengthBuffer: MTLBuffer?

    // Particle Buffers
    private(set) var particleBuffer: MTLBuffer?
    private(set) var interactionBuffer: MTLBuffer?
    private(set) var numSpeciesBuffer: MTLBuffer?

    var areBuffersInitialized: Bool {
        return particleBuffer != nil &&
               interactionBuffer != nil &&
               numSpeciesBuffer != nil &&
               deltaTimeBuffer != nil &&
               maxDistanceBuffer != nil &&
               minDistanceBuffer != nil &&
               betaBuffer != nil &&
               frictionBuffer != nil &&
               repulsionStrengthBuffer != nil &&
               cameraBuffer != nil &&
               zoomBuffer != nil
    }

    private init() {
        guard let metalDevice = MTLCreateSystemDefaultDevice(),
              let queue = metalDevice.makeCommandQueue() else {
            fatalError("❌ Failed to initialize Metal device or command queue.")
        }
        self.device = metalDevice
        self.commandQueue = queue

        initializeBuffers()
    }

    // Initialize all buffers at creation
    private func initializeBuffers() {
        deltaTimeBuffer = createBuffer(type: Float.self)
        maxDistanceBuffer = createBuffer(type: Float.self)
        minDistanceBuffer = createBuffer(type: Float.self)
        betaBuffer = createBuffer(type: Float.self)
        frictionBuffer = createBuffer(type: Float.self)
        repulsionStrengthBuffer = createBuffer(type: Float.self)
        cameraBuffer = createBuffer(type: SIMD2<Float>.self)
        zoomBuffer = createBuffer(type: Float.self)
        
        updatePhysicsBuffers()  // Ensure physics values are set
    }

    // Handles creating buffers dynamically
    private func createBuffer<T>(type: T.Type, count: Int = 1) -> MTLBuffer? {
        return device.makeBuffer(length: MemoryLayout<T>.stride * count, options: [])
    }

    // Particle buffer setup (used when resetting particles)
    func initializeParticleBuffers(particles: [Particle], interactionMatrix: [[Float]], numSpecies: Int) {
        let particleSize = MemoryLayout<Particle>.stride * particles.count
        particleBuffer = device.makeBuffer(bytes: particles, length: particleSize, options: .storageModeShared)
        
        let flatMatrix = flattenInteractionMatrix(interactionMatrix)
        let matrixSize = MemoryLayout<Float>.stride * flatMatrix.count
        interactionBuffer = device.makeBuffer(bytes: flatMatrix, length: matrixSize, options: .storageModeShared)

        numSpeciesBuffer = createBuffer(type: Int.self)
        updateNumSpeciesBuffer(numSpecies: numSpecies)
    }

    // Flattens 2D interaction matrix into 1D
    private func flattenInteractionMatrix(_ matrix: [[Float]]) -> [Float] {
        return matrix.flatMap { $0 }
    }
}

// Buffer Updates
extension BufferManager {
    
    func updateCameraBuffer(position: SIMD2<Float>) {
        updateBuffer(cameraBuffer, with: position)
    }
    
    func updateZoomBuffer(zoom: Float) {
        updateBuffer(zoomBuffer, with: zoom)
    }
    
    func updatePhysicsBuffers() {
        let settings = SimulationSettings.shared
        
        updateBuffer(maxDistanceBuffer, with: settings.maxDistance)
        updateBuffer(minDistanceBuffer, with: settings.minDistance)
        updateBuffer(betaBuffer, with: settings.beta)
        updateBuffer(frictionBuffer, with: settings.friction)
        updateBuffer(repulsionStrengthBuffer, with: settings.repulsionStrength)
    }
    
    func updateParticleBuffer(particles: [Particle]) {
        guard let particleBuffer = particleBuffer else { return }
        let size = particles.count * MemoryLayout<Particle>.stride
        particleBuffer.contents().copyMemory(from: particles, byteCount: size)
    }
    
    func updateInteractionBuffer(interactionMatrix: [[Float]]) {
        guard let interactionBuffer = interactionBuffer else { return }
        let flatMatrix = flattenInteractionMatrix(interactionMatrix)
        interactionBuffer.contents().copyMemory(from: flatMatrix, byteCount: flatMatrix.count * MemoryLayout<Float>.stride)
    }
    
    func updateNumSpeciesBuffer(numSpecies: Int) {
        updateBuffer(numSpeciesBuffer, with: numSpecies)
    }
    
    func updateDeltaTimeBuffer(dt: inout Float) {
        updateBuffer(deltaTimeBuffer, with: dt)
    }
    
    func updateInteractionMatrix(matrix: [[Float]], numSpecies: Int) {
        let flatMatrix = flattenInteractionMatrix(matrix)
        let matrixSize = flatMatrix.count * MemoryLayout<Float>.stride
        
        if interactionBuffer == nil || interactionBuffer!.length != matrixSize {
            interactionBuffer = device.makeBuffer(length: matrixSize, options: [])
        }
        interactionBuffer?.contents().copyMemory(from: flatMatrix, byteCount: matrixSize)
        
        updateNumSpeciesBuffer(numSpecies: numSpecies)
    }
    
    private func updateBuffer<T>(_ buffer: MTLBuffer?, with value: T) {
        guard let buffer = buffer else { return }
        withUnsafeBytes(of: value) { rawBuffer in
            buffer.contents().copyMemory(from: rawBuffer.baseAddress!, byteCount: MemoryLayout<T>.stride)
        }
    }
    
    // Overload for SIMD types (SIMD2<Float>, SIMD3<Float>, etc.)
    private func updateBuffer<T: SIMD>(_ buffer: MTLBuffer?, with value: T) {
        guard let buffer = buffer else { return }
        withUnsafeBytes(of: value) { rawBuffer in
            buffer.contents().copyMemory(from: rawBuffer.baseAddress!, byteCount: MemoryLayout<T>.stride)
        }
    }
}
