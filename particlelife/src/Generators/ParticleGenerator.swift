import simd

struct Particle {
    var position: simd_float2
    var velocity: simd_float2
    var species: Int32
}

enum DistributionType: Codable, CaseIterable {
    case centered, uniform, uniformCircle, centeredCircle, ring, rainbowRing,
         colorBattle, colorWheel, colorBands, line, spiral, rainbowSpiral
    
    /// Determines if the distribution should be recentered after generation
    var shouldRecenter: Bool {
        switch self {
        case .centered, .uniform, .colorBands, .line:
            return true
        default:
            return false
        }
    }

    /// Determines if the distribution should scale to maintain aspect ratio
    var shouldScaleToAspectRatio: Bool {
        switch self {
        case .uniform, .line, .colorBands:
            return true
        default:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .centered: return "Centered"
        case .uniform: return "Uniform"
        case .uniformCircle: return "Uniform Circle"
        case .centeredCircle: return "Centered Circle"
        case .ring: return "Ring"
        case .rainbowRing: return "Rainbow Ring"
        case .colorBattle: return "Color Battle"
        case .colorWheel: return "Color Wheel"
        case .colorBands: return "Color Bands"
        case .line: return "Line"
        case .spiral: return "Spiral"
        case .rainbowSpiral: return "Rainbow Spiral"
        }
    }
}

enum ParticleCount: Int, CaseIterable, Identifiable, Codable {
    case k1 = 1024
    case k2 = 2048
    case k5 = 5120
    case k10 = 10240
    case k20 = 20480
    case k30 = 30720
    case k35 = 35840
    case k40 = 40960

    var id: Int { self.rawValue }

    var displayString: String {
        switch self {
        case .k1: return "1K"
        case .k2: return "2K"
        case .k5: return "5K"
        case .k10: return "10K"
        case .k20: return "20K"
        case .k30: return "30K"
        case .k35: return "35K"
        case .k40: return "40K"
        }
    }
}

extension ParticleCount {
    
    /// Returns the particle count for a given species count (1-9).
    static func particles(for speciesCount: Int) -> ParticleCount {
        guard (1...9).contains(speciesCount) else { return k1 }

        // Map species count to an increasing particle count
        let mapping: [Int: ParticleCount] = [
            1: .k10,
            2: .k10,
            3: .k20,
            4: .k20,
            5: .k20,
            6: .k30,
            7: .k35,
            8: .k35,
            9: .k40
        ]

        return mapping[speciesCount] ?? .k10
    }
}

struct ParticleGenerator {
    
    static func generate(distribution: DistributionType, particleCount: ParticleCount, speciesCount: Int) -> [Particle] {
        
        Logger.log("Distribution: \(distribution), count: \(particleCount.displayString), speciesCount: \(speciesCount)", level: .debug)
        
        let count = particleCount.rawValue
        
        switch distribution {
        case .centered:
            return centered(count: count, speciesCount: speciesCount)
        case .uniform:
            return uniform(count: count, speciesCount: speciesCount)
        case .uniformCircle:
            return uniformCircle(count: count, speciesCount: speciesCount)
        case .centeredCircle:
            return centeredCircle(count: count, speciesCount: speciesCount)
        case .ring:
            return ring(count: count, speciesCount: speciesCount)
        case .rainbowRing:
            return rainbowRing(count: count, speciesCount: speciesCount)
        case .colorBattle:
            return colorBattle(count: count, speciesCount: speciesCount)
        case .colorWheel:
            return colorWheel(count: count, speciesCount: speciesCount)
        case .colorBands:
            return colorBands(count: count, speciesCount: speciesCount)
        case .line:
            return line(count: count, speciesCount: speciesCount)
        case .spiral:
            return spiral(count: count, speciesCount: speciesCount)
        case .rainbowSpiral:
            return rainbowSpiral(count: count, speciesCount: speciesCount)
        }
    }
}

extension ParticleGenerator {
    
    static func centered(count: Int, speciesCount: Int) -> [Particle] {
        let scale: Float = 0.3
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0) * scale * 0.5 + 0.5,
                Float.random(in: -1.0...1.0) * scale * 0.5 + 0.5
            )
            return Particle(position: position, velocity: .zero, species: Int32.random(in: 0..<Int32(speciesCount)))
        }
    }

    static func uniform(count: Int, speciesCount: Int) -> [Particle] {
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0),
                Float.random(in: -1.0...1.0)
            )
            return Particle(position: position, velocity: .zero, species: Int32.random(in: 0..<Int32(speciesCount)))
        }
    }

    static func uniformCircle(count: Int, speciesCount: Int) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = sqrt(Float.random(in: 0...1)) * 0.5
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32.random(in: 0..<Int32(speciesCount)))
        }
    }

    static func centeredCircle(count: Int, speciesCount: Int) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = Float.random(in: 0...0.5)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32.random(in: 0..<Int32(speciesCount)))
        }
    }

    static func ring(count: Int, speciesCount: Int) -> [Particle] {
        return (0..<count).map { _ in
            let angle = Float.random(in: 0...2 * .pi)
            let radius = 0.7 + Float.random(in: -0.02...0.02)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32.random(in: 0..<Int32(speciesCount)))
        }
    }

    static func rainbowRing(count: Int, speciesCount: Int) -> [Particle] {
        return (0..<count).map { i in
            let angle = (0.3 * Float.random(in: -1...1) + Float(i % speciesCount)) / Float(speciesCount) * 2 * .pi
            let radius = 0.7 + Float.random(in: -0.02...0.02)
            let position = SIMD2<Float>(cos(angle) * radius, sin(angle) * radius)
            return Particle(position: position, velocity: .zero, species: Int32(i % speciesCount))
        }
    }

    static func colorBattle(count: Int, speciesCount: Int) -> [Particle] {
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

    static func colorWheel(count: Int, speciesCount: Int) -> [Particle] {
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
    
    static func colorBands(count: Int, speciesCount: Int) -> [Particle] {
        var particles: [Particle] = []

        let bandHeight: Float = 0.4  // Vertical compression
        let horizontalPadding: Float = 0.2  // Use 60% of space
        let spacing = (2.0 - 2.0 * horizontalPadding) / Float(speciesCount)

        for _ in 0..<count {
            let species = Int32.random(in: 0..<Int32(speciesCount))

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
    
    static func line(count: Int, speciesCount: Int) -> [Particle] {
        return (0..<count).map { _ in
            let position = SIMD2<Float>(
                Float.random(in: -1.0...1.0),
                Float.random(in: -0.15...0.15)
            )
            return Particle(position: position, velocity: .zero, species: Int32.random(in: 0..<Int32(speciesCount)))
        }
    }

    static func spiral(count: Int, speciesCount: Int) -> [Particle] {
        let maxRotations: Float = 2
        return (0..<count).map { _ in
            let f = Float.random(in: 0...1)
            let angle = maxRotations * 2 * .pi * f
            let spread = 0.5 * min(f, 0.2)
            let radius = 0.9 * f + spread * Float.random(in: -1...1)
            let position = SIMD2<Float>(radius * cos(angle), radius * sin(angle))
            return Particle(position: position, velocity: .zero, species: Int32.random(in: 0..<Int32(speciesCount)))
        }
    }

    static func rainbowSpiral(count: Int, speciesCount: Int) -> [Particle] {
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
