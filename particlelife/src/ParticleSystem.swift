//
//  ParticleSystem.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Metal
import simd
import SwiftUI

struct Particle {
    var position: simd_float2
    var velocity: simd_float2
    var species: Int16
    
    static func create(numSpecies: Int) -> Particle {
        var particle = Particle(position: .zero, velocity: .zero, species: 0)
        particle.randomize(numSpecies: numSpecies)
        return particle
    }
    
    mutating func randomize(numSpecies: Int) {
        position = SIMD2<Float>(Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0))
        velocity = SIMD2<Float>(Float.random(in: -0.01...0.01), Float.random(in: -0.01...0.01))
        species = Int16.random(in: 0..<Int16(numSpecies))
    }
}

func generateInteractionMatrix(numSpecies: Int) -> [[Float]] {
    var matrix = [[Float]](repeating: [Float](repeating: 0.0, count: numSpecies), count: numSpecies)

    for i in 0..<numSpecies {
        for j in 0..<numSpecies {
            if i == j {
                matrix[i][j] = Float.random(in: 0.3...0.7)  // ✅ Self-interaction varies
            } else if j < i {
                matrix[i][j] = matrix[j][i]  // ✅ Mirror for symmetry
            } else {
                matrix[i][j] = Float.random(in: -0.75...0.75)  // ✅ Generate only upper triangle
            }
        }
    }

    return matrix
}

class ParticleSystem: ObservableObject {
    static let shared = ParticleSystem(device: MTLCreateSystemDefaultDevice()!)
    @Published var interactionMatrix: [[Float]] = []
    @Published var speciesColors: [Color] = []  // ✅ Ensure this is @Published
    
    var numSpecies: Int
    var particles: [Particle]

    var particleBuffer: MTLBuffer?
    var interactionBuffer: MTLBuffer!
    var numSpeciesBuffer: MTLBuffer!

    var maxDistanceBuffer: MTLBuffer?
    var minDistanceBuffer: MTLBuffer?
    var betaBuffer: MTLBuffer?
    var frictionBuffer: MTLBuffer?
    var repulsionStrengthBuffer: MTLBuffer?

    var mousePositionBuffer: MTLBuffer?
    var mouseVelocityBuffer: MTLBuffer?
    var currentMousePosition: simd_float2 = simd_float2(0, 0)
    var currentMouseVelocity: simd_float2 = simd_float2(0, 0)

    var device: MTLDevice!
    var computePipeline: MTLComputePipelineState!
    var commandQueue: MTLCommandQueue!
        
    var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970

    init(device: MTLDevice, count: Int = 50000, numSpecies: Int = 6) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.numSpecies = numSpecies

        self.particles = (0..<count).map { _ in
            return Particle.create(numSpecies: numSpecies)
        }

        generateNewMatrix()
        updatePhysicsBuffers()
        updateBuffers()
        setupComputePipeline()
    }
    
    func reset(count: Int) {
        print("🔄 Resetting simulation...")

        generateNewMatrix()  // ✅ Update interaction matrix first

        for i in 0..<particles.count {
            particles[i].randomize(numSpecies: numSpecies)
        }

        updatePhysicsBuffers()
        updateBuffers()  // ✅ Now update GPU buffers with the modified particles
    }
    
    func generateNewMatrix() {
        interactionMatrix = generateInteractionMatrix(numSpecies: numSpecies)
        generateSpeciesColors(numSpecies: numSpecies)
    }
    
    func generateSpeciesColors(numSpecies: Int) {
        let predefinedColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
        
        DispatchQueue.main.async {
            if numSpecies > predefinedColors.count {
                self.speciesColors = (0..<numSpecies).map { _ in
                    Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 0.9)
                }
            } else {
                self.speciesColors = Array(predefinedColors.prefix(numSpecies))
            }
            self.objectWillChange.send()  // ✅ Force UI refresh
            print("✅ Species Colors Updated:", self.speciesColors)  // ✅ Debugging
        }
    }
    
    func getInteractionMatrixString() -> String {
        var result = ""
        for row in interactionMatrix {
            let rowString = row.map { String(format: "%.2f", $0) }.joined(separator: "  ")
            result += rowString + "\n"
        }
        return result
    }
    
    func updatePhysicsBuffers() {
        let settings = SimulationSettings.shared

        var maxDistance = settings.maxDistance
        var minDistance = settings.minDistance
        var beta = settings.beta
        var friction = settings.friction
        var repulsionStrength = settings.repulsionStrength

        // ✅ Only update the physics-related buffers
        maxDistanceBuffer?.contents().copyMemory(from: &maxDistance, byteCount: MemoryLayout<Float>.stride)
        minDistanceBuffer?.contents().copyMemory(from: &minDistance, byteCount: MemoryLayout<Float>.stride)
        betaBuffer?.contents().copyMemory(from: &beta, byteCount: MemoryLayout<Float>.stride)
        frictionBuffer?.contents().copyMemory(from: &friction, byteCount: MemoryLayout<Float>.stride)
        repulsionStrengthBuffer?.contents().copyMemory(from: &repulsionStrength, byteCount: MemoryLayout<Float>.stride)
    }
    
    func updateBuffers() {
        print("Full buffer update triggered.")

        let settings = SimulationSettings.shared
        var maxDistance = settings.maxDistance
        var minDistance = settings.minDistance
        var beta = settings.beta
        var friction = settings.friction
        var repulsionStrength = settings.repulsionStrength

        particleBuffer = device.makeBuffer(bytes: particles, length: MemoryLayout<Particle>.stride * particles.count, options: .storageModeShared)
        numSpeciesBuffer = device.makeBuffer(bytes: &numSpecies, length: MemoryLayout<Int32>.stride, options: .storageModeShared)
        interactionBuffer = device.makeBuffer(bytes: interactionMatrix.flatMap { $0 }, length: MemoryLayout<Float>.stride * numSpecies * numSpecies, options: .storageModeShared)

        maxDistanceBuffer = device.makeBuffer(bytes: &maxDistance, length: MemoryLayout<Float>.stride, options: [])
        minDistanceBuffer = device.makeBuffer(bytes: &minDistance, length: MemoryLayout<Float>.stride, options: [])
        betaBuffer = device.makeBuffer(bytes: &beta, length: MemoryLayout<Float>.stride, options: [])
        frictionBuffer = device.makeBuffer(bytes: &friction, length: MemoryLayout<Float>.stride, options: [])
        repulsionStrengthBuffer = device.makeBuffer(bytes: &repulsionStrength, length: MemoryLayout<Float>.stride, options: [])
        
        var neutralPosition = simd_float2(Float.nan, Float.nan)
        var neutralVelocity = simd_float2(0, 0)

        mousePositionBuffer = device.makeBuffer(bytes: &neutralPosition, length: MemoryLayout<simd_float2>.stride, options: [])
        mouseVelocityBuffer = device.makeBuffer(bytes: &neutralVelocity, length: MemoryLayout<simd_float2>.stride, options: [])
        
        clearMouseInfluence()
    }
        
    func clearMouseInfluence() {
        var neutralPosition = simd_float2(Float.nan, Float.nan)
        var neutralVelocity = simd_float2(0, 0)

        mousePositionBuffer?.contents().copyMemory(from: &neutralPosition, byteCount: MemoryLayout<simd_float2>.stride)
        mouseVelocityBuffer?.contents().copyMemory(from: &neutralVelocity, byteCount: MemoryLayout<simd_float2>.stride)

        currentMousePosition = neutralPosition
        currentMouseVelocity = neutralVelocity
    }
    
    func setupComputePipeline() {
        guard let library = device.makeDefaultLibrary(),
              let computeFunction = library.makeFunction(name: "compute_particle_movement") else {
            fatalError("Failed to load compute function")
        }

        guard numSpeciesBuffer != nil else {
            fatalError("numSpeciesBuffer was not created before setting up the pipeline!")
        }

        do {
            computePipeline = try device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
    }
    
    func update() {
        let currentTime = Date().timeIntervalSince1970
        var dt = Float(currentTime - lastUpdateTime)
        dt = max(0.0001, min(dt, 0.01))
        lastUpdateTime = currentTime
                        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(interactionBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(numSpeciesBuffer, offset: 0, index: 2)
        
        computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.stride, index: 3)  // ✅ Pass dt to Metal
        
        if let maxDistanceBuffer = maxDistanceBuffer { computeEncoder.setBuffer(maxDistanceBuffer, offset: 0, index: 4) }
        if let minDistanceBuffer = minDistanceBuffer { computeEncoder.setBuffer(minDistanceBuffer, offset: 0, index: 5) }
        if let betaBuffer = betaBuffer { computeEncoder.setBuffer(betaBuffer, offset: 0, index: 6) }
        if let frictionBuffer = frictionBuffer { computeEncoder.setBuffer(frictionBuffer, offset: 0, index: 7) }
        if let repulsionStrengthBuffer = repulsionStrengthBuffer { computeEncoder.setBuffer(repulsionStrengthBuffer, offset: 0, index: 8) }

        var mousePos = currentMousePosition
        var mouseVel = currentMouseVelocity

        mousePositionBuffer?.contents().copyMemory(from: &mousePos, byteCount: MemoryLayout<simd_float2>.stride)
        mouseVelocityBuffer?.contents().copyMemory(from: &mouseVel, byteCount: MemoryLayout<simd_float2>.stride)
        
        if let mousePositionBuffer = mousePositionBuffer {
            computeEncoder.setBuffer(mousePositionBuffer, offset: 0, index: 9)  // ✅ Ensure this is set
        } else {
            print("❌ mousePositionBuffer is nil! Compute shader will fail.")
        }

        if let mouseVelocityBuffer = mouseVelocityBuffer {
            computeEncoder.setBuffer(mouseVelocityBuffer, offset: 0, index: 10)  // ✅ Ensure this is set
        } else {
            print("❌ mouseVelocityBuffer is nil! Compute shader will fail.")
        }
        
        let threadGroupSize = 256
        let threadGroups = (particles.count + threadGroupSize - 1) / threadGroupSize
        
        computeEncoder.dispatchThreadgroups(MTLSize(width: threadGroups, height: 1, depth: 1),
                                            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1))
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
    }
}
