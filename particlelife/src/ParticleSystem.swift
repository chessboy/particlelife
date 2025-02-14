//
//  ParticleSystem.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Metal
import simd

struct Particle {
    var position: simd_float2
    var velocity: simd_float2
}

class ParticleSystem {
    var particles: [Particle]
    var particleBuffer: MTLBuffer?
    var device: MTLDevice!
    var computePipeline: MTLComputePipelineState!
    var commandQueue: MTLCommandQueue!
    
    init(device: MTLDevice, count: Int = 20000) {  // Set default to 20,000
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        particles = (0..<count).map { _ in
            let x = Float.random(in: -1.5...1.5)
            let y = Float.random(in: -1.5...1.5)
            
            let vx = Float.random(in: -0.03...0.03)
            let vy = Float.random(in: -0.03...0.03)
            
            return Particle(position: simd_float2(x, y), velocity: simd_float2(vx, vy))
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
    }
    
    func update() {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        
        // ✅ Optimized Thread Dispatch for 20K Particles
        let threadGroupSize = 256  // Groups of 256 threads
        let threadGroups = (particles.count + threadGroupSize - 1) / threadGroupSize
        
        computeEncoder.dispatchThreadgroups(MTLSize(width: threadGroups, height: 1, depth: 1),
                                            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1))
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
    }
}
