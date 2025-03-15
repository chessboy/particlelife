import simd
import GameplayKit

struct ParticleGenerator {
    
    static func generate(
        distribution: DistributionType,
        particleCount: ParticleCount,
        speciesCount: Int,
        speciesDistribution: SpeciesDistribution
    ) -> [Particle] {
        
        let count = particleCount.rawValue
        
        // Normalize distribution and assign particles
        let speciesCounts = normalizeAndAssignParticles(
            speciesCount: speciesCount,
            particleCount: count,
            speciesDistribution: speciesDistribution
        )
        
        // Flatten species assignments into a shuffled array
        var speciesAssignments: [Int] = []
        for (index, num) in speciesCounts.enumerated() {
            speciesAssignments.append(contentsOf: Array(repeating: index, count: num))
        }
        speciesAssignments.shuffle()
        
        switch distribution {
        case .centered:
            return centered(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .uniform:
            return uniform(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .uniformCircle:
            return uniformCircle(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .centeredCircle:
            return centeredCircle(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .ring:
            return ring(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .rainbowRing:
            return rainbowRing(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .colorBattle:
            return colorBattle(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .colorWheel:
            return colorWheel(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .colorBands:
            return colorBands(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .line:
            return line(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .spiral:
            return spiral(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .rainbowSpiral:
            return rainbowSpiral(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        case .perlinNoise:
            return generatePerlinNoiseParticles(count: count, speciesCount: speciesCount, speciesAssignments: &speciesAssignments)
        }
    }
    
    static func normalizeAndAssignParticles(
        speciesCount: Int,
        particleCount: Int,
        speciesDistribution: SpeciesDistribution
    ) -> [Int] {
        
        // Use the given speciesDistribution as-is (since it's always valid)
        let distribution = speciesDistribution
        
        // Compute initial species counts
        var speciesCounts = distribution.toArray().map { Int(Float(particleCount) * $0) }
        
        // Ensure total particle count is correct
        let totalAssigned = speciesCounts.reduce(0, +)
        let remaining = particleCount - totalAssigned
        
        if remaining > 0 {
            for i in 0..<remaining {
                speciesCounts[i % speciesCount] += 1
            }
        }
        
        // Ensure no active species has 0 particles
        for i in 0..<speciesCount {
            if speciesCounts[i] == 0 && distribution[i] > 0 {
                speciesCounts[i] = 1  // Assign at least 1 particle to active species
            }
        }
        
        // Log the computed values
        let formattedDistribution = distribution.toArray().map { String(format: "%.3f", $0) }.joined(separator: ", ")
        let formattedCounts = speciesCounts.map { String($0) }.joined(separator: ", ")
        
        Logger.log("Particle Assignment: speciesCount: \(speciesCount), totalParticles: \(particleCount)", level: .debug)
        Logger.log("Original Distribution: [\(speciesDistribution.toArray())]", level: .debug)
        Logger.log("Normalized Distribution: [\(formattedDistribution)]", level: .debug)
        Logger.log("Assigned Particles Per Species: [\(formattedCounts)] (Total: \(speciesCounts.reduce(0, +)))", level: .debug)
        
        return speciesCounts
    }
}

extension ParticleGenerator {
    
    static func generatePerlinNoiseParticles(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        let rng = GKRandomSource.sharedRandom()
        
        var particles: [Particle] = []
        let perlin = GKPerlinNoiseSource(frequency: 1.0, octaveCount: 4, persistence: 0.5, lacunarity: 2.0, seed: Int32(Int(rng.nextInt())))
        let noiseMap = GKNoiseMap(GKNoise(perlin), size: vector_double2(2, 2), origin: vector_double2(-1, -1), sampleCount: vector_int2(100, 100), seamless: false)
        
        for _ in 0..<count {
            var position: SIMD2<Float>
            repeat {
                let x = Float(rng.nextUniform()) * 2.0 - 1.0 // Convert [0,1] → [-1,1]
                let y = Float(rng.nextUniform()) * 2.0 - 1.0 // Convert [0,1] → [-1,1]
                
                let noiseValue = noiseMap.value(at: vector_int2(Int32((x + 1) * 50), Int32((y + 1) * 50))) // Scale to noise grid
                let remappedNoise = noiseValue * 2.0 - 1.0 // Convert Perlin output from [0,1] → [-1,1]
                
                if remappedNoise > -0.2 { // Threshold to create voids
                    position = SIMD2<Float>(x, y)
                    break
                }
            } while true
            
            let particle = Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
            particles.append(particle)
        }
        return particles
    }

    static func centered(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        let scale: Float = 0.3
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0) * scale * 0.5 + 0.5,
                Float.random(in: -1.0...1.0) * scale * 0.5 + 0.5
            )
            return Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
        }
    }
    
    static func uniform(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0),
                Float.random(in: -1.0...1.0)
            )
            return Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
        }
    }

    static func uniformCircle(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = sqrt(Float.random(in: 0...1)) * 0.5
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
        }
    }

    static func centeredCircle(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = Float.random(in: 0...0.5)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
        }
    }

    static func ring(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = 0.7 + Float.random(in: -0.02...0.02)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
        }
    }

    static func rainbowRing(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { i in
            let angle = (0.3 * Float.random(in: -1...1) + Float(i % speciesCount)) / Float(speciesCount) * 2 * .pi
            let radius = 0.7 + Float.random(in: -0.02...0.02)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32(i % speciesCount))
        }
    }

    static func colorBattle(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { i in
            let species = Int32(i % speciesCount)
            let centerAngle = Float(species) / Float(speciesCount) * 2 * .pi
            let centerRadius: Float = 0.5
            let angle = Float.random(in: 0...2 * .pi)
            let radius = Float.random(in: 0...0.1)
            let position = SIMD2<Float>(
                centerRadius * cos(centerAngle) + cos(angle) * radius,
                centerRadius * sin(centerAngle) + sin(angle) * radius
            )
            return Particle(position: position, velocity: .zero, species: species)
        }
    }

    static func colorWheel(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { i in
            let species = Int32(i % speciesCount)
            let centerAngle = Float(species) / Float(speciesCount) * 2 * .pi
            let centerRadius: Float = 0.3
            let individualRadius: Float = 0.2
            let position = SIMD2<Float>(
                centerRadius * cos(centerAngle) + Float.random(in: -individualRadius...individualRadius),
                centerRadius * sin(centerAngle) + Float.random(in: -individualRadius...individualRadius)
            )
            return Particle(position: position, velocity: .zero, species: species)
        }
    }
    
    static func colorBands(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        var particles: [Particle] = []

        let bandHeight: Float = 0.4  // Vertical compression
        let horizontalPadding: Float = 0.2  // Use 60% of space
        let spacing = (2.0 - 2.0 * horizontalPadding) / Float(speciesCount)

        for _ in 0..<count {
            let species = Int32(speciesAssignments.popLast() ?? 0)

            let centerX = -1.0 + horizontalPadding + (Float(species) + 0.5) * spacing
            let xOffset = spacing / 2.0

            var x = Float.random(in: centerX - xOffset...centerX + xOffset)
            x = max(centerX - xOffset, min(centerX + xOffset, x))

            let y = Float.random(in: -bandHeight...bandHeight)
            let position = SIMD2<Float>(x, y)
            let velocity = SIMD2<Float>.zero
            
            particles.append(Particle(position: position, velocity: velocity, species: species))
        }

        return particles
    }
    
    static func line(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0),
                Float.random(in: -0.15...0.15)
            )
            return Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
        }
    }

    static func spiral(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        let maxRotations: Float = 2
        return (0..<count).map { _ in
            let f = Float.random(in: 0...1)
            let angle = maxRotations * 2 * .pi * f
            let spread = 0.5 * min(f, 0.2)
            let radius = 0.9 * f + spread * Float.random(in: -1...1)
            let position = SIMD2<Float>(radius * cos(angle), radius * sin(angle))
            return Particle(position: position, velocity: .zero, species: Int32(speciesAssignments.popLast() ?? 0))
        }
    }

    static func rainbowSpiral(count: Int, speciesCount: Int, speciesAssignments: inout [Int]) -> [Particle] {
        let maxRotations: Float = 2
        return (0..<count).map { i in
            let typeSpread = 0.3 / Float(speciesCount)
            var f = (Float(i % speciesCount) + 1) / Float(speciesCount + 2) + typeSpread * Float.random(in: -1...1)
            f = max(0, min(1, f))  // Clamp between 0 and 1
            let angle = maxRotations * 2 * .pi * f
            let spread = 0.5 * min(f, 0.2)
            let radius = 0.9 * f + spread * Float.random(in: -1...1)
            let position = SIMD2<Float>(radius * cos(angle), radius * sin(angle))
            return Particle(position: position, velocity: .zero, species: Int32(i % speciesCount))
        }
    }
}
