import simd

struct ParticleGenerator {
    
    static func centered(count: Int, numSpecies: Int) -> [Particle] {
        let scale: Float = 0.3
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0) * scale * 0.5 + 0.5,
                Float.random(in: -1.0...1.0) * scale * 0.5 + 0.5
            )
            return Particle(position: position, velocity: .zero, species: Int16.random(in: 0..<Int16(numSpecies)))
        }
    }

    static func uniform(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0),
                Float.random(in: -1.0...1.0)
            )
            return Particle(position: position, velocity: .zero, species: Int16.random(in: 0..<Int16(numSpecies)))
        }
    }

    static func uniformCircle(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = sqrt(Float.random(in: 0...1)) * 0.5
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int16.random(in: 0..<Int16(numSpecies)))
        }
    }

    static func centeredCircle(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = Float.random(in: 0...0.5)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int16.random(in: 0..<Int16(numSpecies)))
        }
    }

    static func ring(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = 0.7 + Float.random(in: -0.02...0.02)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int16.random(in: 0..<Int16(numSpecies)))
        }
    }

    static func rainbowRing(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { i in
            let angle = (0.3 * Float.random(in: -1...1) + Float(i % numSpecies)) / Float(numSpecies) * 2 * .pi
            let radius = 0.7 + Float.random(in: -0.02...0.02)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int16(i % numSpecies))
        }
    }

    static func colorBattle(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { i in
            let species = Int16(i % numSpecies)
            let centerAngle = Float(species) / Float(numSpecies) * 2 * .pi
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

    static func colorWheel(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { i in
            let species = Int16(i % numSpecies)
            let centerAngle = Float(species) / Float(numSpecies) * 2 * .pi
            let centerRadius: Float = 0.3
            let individualRadius: Float = 0.2
            let position = SIMD2<Float>(
                centerRadius * cos(centerAngle) + Float.random(in: -individualRadius...individualRadius),
                centerRadius * sin(centerAngle) + Float.random(in: -individualRadius...individualRadius)
            )
            return Particle(position: position, velocity: .zero, species: species)
        }
    }
    
    static func colorBands(count: Int, numSpecies: Int) -> [Particle] {
        var particles: [Particle] = []

        let bandHeight: Float = 0.4  // Controls vertical compression
        let spacing = 2.0 / Float(numSpecies)  // Divide evenly across [-1,1]

        for _ in 0..<count {
            let species = Int16.random(in: 0..<Int16(numSpecies))
            
            // Ensure particles are well-separated and don't wrap
            let xMin = -1.0 + Float(species) * spacing
            let xMax = xMin + spacing
            let x = Float.random(in: xMin...xMax)  // Constrain within correct species band

            let y = Float.random(in: -bandHeight...bandHeight)  // Keep within middle region

            let position = SIMD2<Float>(x, y)
            let velocity = SIMD2<Float>.zero
            
            particles.append(Particle(position: position, velocity: velocity, species: species))
        }

        return particles
    }
    
    static func line(count: Int, numSpecies: Int) -> [Particle] {
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0),
                Float.random(in: -0.15...0.15)
            )
            return Particle(position: position, velocity: .zero, species: Int16.random(in: 0..<Int16(numSpecies)))
        }
    }

    static func spiral(count: Int, numSpecies: Int) -> [Particle] {
        let maxRotations: Float = 2
        return (0..<count).map { _ in
            let f = Float.random(in: 0...1)
            let angle = maxRotations * 2 * .pi * f
            let spread = 0.5 * min(f, 0.2)
            let radius = 0.9 * f + spread * Float.random(in: -1...1)
            let position = SIMD2<Float>(radius * cos(angle), radius * sin(angle))
            return Particle(position: position, velocity: .zero, species: Int16.random(in: 0..<Int16(numSpecies)))
        }
    }

    static func rainbowSpiral(count: Int, numSpecies: Int) -> [Particle] {
        let maxRotations: Float = 2
        return (0..<count).map { i in
            let typeSpread = 0.3 / Float(numSpecies)
            var f = (Float(i % numSpecies) + 1) / Float(numSpecies + 2) + typeSpread * Float.random(in: -1...1)
            f = max(0, min(1, f))  // Clamp between 0 and 1
            let angle = maxRotations * 2 * .pi * f
            let spread = 0.5 * min(f, 0.2)
            let radius = 0.9 * f + spread * Float.random(in: -1...1)
            let position = SIMD2<Float>(radius * cos(angle), radius * sin(angle))
            return Particle(position: position, velocity: .zero, species: Int16(i % numSpecies))
        }
    }
}
