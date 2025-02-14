//
//  ParticleSystem.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Metal
import simd

var interactionBuffer: MTLBuffer!

struct Particle {
    var position: simd_float2
    var velocity: simd_float2
    var species: Int16  // New: Species type (0, 1, 2, etc.)
}

let numSpecies = 3  // Example: 3 different particle types
var interactionMatrix: [[Float]] = [
    [ 0.1, -0.2,  0.3],  // How Species 0 interacts with 0, 1, 2
    [-0.2,  0.1, -0.1],  // How Species 1 interacts with 0, 1, 2
    [ 0.3, -0.1,  0.1]   // How Species 2 interacts with 0, 1, 2
]

class ParticleSystem {
    var particles: [Particle]
    var particleBuffer: MTLBuffer?
    var device: MTLDevice!
    var computePipeline: MTLComputePipelineState!
    var commandQueue: MTLCommandQueue!
    
    init(device: MTLDevice, count: Int = 10000) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()

        particles = (0..<count).map { i in
            let x = Float.random(in: -1.5...1.5)
            let y = Float.random(in: -1.5...1.5)
            let vx = Float.random(in: -0.02...0.02)
            let vy = Float.random(in: -0.02...0.02)
            let species = Int16.random(in: 0...Int16(numSpecies - 1))

            return Particle(position: simd_float2(x, y), velocity: simd_float2(vx, vy), species: species)
        }

        particleBuffer = device.makeBuffer(bytes: particles,
                                           length: MemoryLayout<Particle>.stride * particles.count,
                                           options: .storageModeShared)

        setupComputePipeline()
    }
    
    func setupComputePipeline() {
        let library = device.makeDefaultLibrary()
        let computeFunction = library?.makeFunction(name: "compute_particle_movement")
        
        do {
            computePipeline = try device.makeComputePipelineState(function: computeFunction!)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
        
        interactionBuffer = device.makeBuffer(bytes: interactionMatrix.flatMap { $0 },
                                              length: MemoryLayout<Float>.stride * numSpecies * numSpecies,
                                              options: .storageModeShared)
    }
    
    func update() {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(interactionBuffer, offset: 0, index: 1)  // Pass interaction matrix
        
        let threadGroupSize = 256
        let threadGroups = (particles.count + threadGroupSize - 1) / threadGroupSize
        
        computeEncoder.dispatchThreadgroups(MTLSize(width: threadGroups, height: 1, depth: 1),
                                            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1))
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        
//        // ✅ Debug: Print first particle velocity & position
//        let pointer = particleBuffer?.contents().assumingMemoryBound(to: Particle.self)
//        if let firstParticle = pointer?[0] {
//            print("First Particle Velocity: \(firstParticle.velocity)")
//            print("First Particle Position: \(firstParticle.position)")
//        }
    }
}
