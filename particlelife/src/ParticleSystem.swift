//
//  ParticleSystem.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Metal
import simd

var interactionBuffer: MTLBuffer!
var numSpeciesBuffer: MTLBuffer!

struct Particle {
    var position: simd_float2
    var velocity: simd_float2
    var species: Int16  // New: Species type (0, 1, 2, etc.)
}

var numSpecies = 6
//var interactionMatrix: [[Float]] = [
//    [ 0.3, -0.4,  0.2, -0.1,  0.1, -0.3],
//    [-0.4,  0.3, -0.2,  0.2, -0.3,  0.1],
//    [ 0.2, -0.2,  0.3, -0.4,  0.2, -0.1],
//    [-0.1,  0.2, -0.4,  0.3, -0.2,  0.4],
//    [ 0.1, -0.3,  0.2, -0.2,  0.3, -0.4],
//    [-0.3,  0.1, -0.1,  0.4, -0.4,  0.3]
//]


var interactionMatrix: [[Float]] = [
    [  0.5, -0.3,  0.4, -0.2,  0.3, -0.4],
    [ -0.3,  0.5, -0.2,  0.4, -0.4,  0.2],
    [  0.4, -0.2,  0.5, -0.3,  0.2, -0.1],
    [ -0.2,  0.4, -0.3,  0.5, -0.1,  0.3],
    [  0.3, -0.4,  0.2, -0.1,  0.5, -0.3],
    [ -0.4,  0.2, -0.1,  0.3, -0.3,  0.5]
]

class ParticleSystem {
    var particles: [Particle]
    var particleBuffer: MTLBuffer?
    var device: MTLDevice!
    var computePipeline: MTLComputePipelineState!
    var commandQueue: MTLCommandQueue!
    
    init(device: MTLDevice, count: Int = 50000) {
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
        
        numSpeciesBuffer = device.makeBuffer(bytes: &numSpecies,
                                             length: MemoryLayout<Int32>.stride,
                                             options: .storageModeShared)
        
        setupComputePipeline()
    }
    
    func setupComputePipeline() {
        let library = device.makeDefaultLibrary()
        let computeFunction = library?.makeFunction(name: "compute_particle_movement")
        
        if numSpeciesBuffer == nil {
            fatalError("Failed to create numSpeciesBuffer")
        }
        do {
            computePipeline = try device.makeComputePipelineState(function: computeFunction!)
        } catch {
            fatalError("Failed to create compute pipeline state: \(error)")
        }
        
        interactionBuffer = device.makeBuffer(bytes: interactionMatrix.flatMap { $0 },
                                              length: MemoryLayout<Float>.stride * numSpecies * numSpecies,
                                              options: .storageModeShared)
    }
    
    var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970
    
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

        computeEncoder.setBytes(&dt, length: MemoryLayout<Float>.stride, index: 3)  // ✅ Now dt is mutable

        let threadGroupSize = 256
        let threadGroups = (particles.count + threadGroupSize - 1) / threadGroupSize

        computeEncoder.dispatchThreadgroups(MTLSize(width: threadGroups, height: 1, depth: 1),
                                            threadsPerThreadgroup: MTLSize(width: threadGroupSize, height: 1, depth: 1))

        computeEncoder.endEncoding()
        commandBuffer.commit()
    }}
