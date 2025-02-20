//
//  PresetManager.swift
//  particlelife
//
//  Created by Rob Silverman on 2/20/25.
//
import Foundation

class PresetManager {
    static let shared = PresetManager()
    
    private let userPresetsKey = "userPresets"
    private var userPresets: [SimulationPreset] = []
    
    private let randomPresets: [SimulationPreset]
    private let specialPresets: [SimulationPreset]
    private let emptyPresets: [SimulationPreset]
    
    init() {
        randomPresets = [
            PresetManager.makeRandomPreset(speciesCount: 3),
            PresetManager.makeRandomPreset(speciesCount: 6),
            PresetManager.makeRandomPreset(speciesCount: 9)
        ]
        
        specialPresets = [
            PresetManager.inchworm, PresetManager.cells, PresetManager.comet, PresetManager.snuggleBugs, PresetManager.aliens
        ]
        
        emptyPresets = [
            PresetManager.makeEmptyPreset(speciesCount: 2),
            PresetManager.makeEmptyPreset(speciesCount: 3),
            PresetManager.makeEmptyPreset(speciesCount: 4),
            PresetManager.makeEmptyPreset(speciesCount: 5),
            PresetManager.makeEmptyPreset(speciesCount: 6),
            PresetManager.makeEmptyPreset(speciesCount: 7),
            PresetManager.makeEmptyPreset(speciesCount: 8),
            PresetManager.makeEmptyPreset(speciesCount: 9)
        ]
        
        loadPresets()
    }
    
    func savePreset(_ preset: SimulationPreset) {
        let uniqueName = ensureUniqueName(for: preset.name)
        
        let newPreset = preset.copy(withName: uniqueName)
        
        if !userPresets.contains(where: { $0.name.lowercased() == uniqueName.lowercased() }) {
            userPresets.append(newPreset)
        } else {
            userPresets = userPresets.map { $0.name == uniqueName ? newPreset : $0 }
        }
        
        persistPresets()
    }
    
    func deletePreset(named presetName: String) {
        userPresets.removeAll { $0.name.caseInsensitiveCompare(presetName) == .orderedSame }
        persistPresets()
    }
    
    func getUserPresets() -> [SimulationPreset] {
        return userPresets
    }
    
    func getRandomPresets() -> [SimulationPreset] {
        return randomPresets
    }
    
    func getSpecialPresets() -> [SimulationPreset] {
        return specialPresets
    }
    
    func getEmptyPresets() -> [SimulationPreset] {
        return emptyPresets
    }
    
    func getAllPresets() -> [SimulationPreset] {
        return randomPresets + specialPresets + emptyPresets + getUserPresets()
    }
    
    var defaultPreset: SimulationPreset {
        return getRandomPresets().first!
    }
    
    private func persistPresets() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let encoded = try encoder.encode(userPresets)
            UserDefaults.standard.set(encoded, forKey: userPresetsKey)
        } catch {
            print("Error encoding presets: \(error)")
        }
    }
    
    private func loadPresets() {
        if let savedData = UserDefaults.standard.data(forKey: userPresetsKey) {
            let decoder = JSONDecoder()
            if let loadedPresets = try? decoder.decode([SimulationPreset].self, from: savedData) {
                userPresets = loadedPresets
            }
        }
    }
    
    private func ensureUniqueName(for presetName: String) -> String {
        let allPresetNames = Set(getAllPresets().map { $0.name.lowercased() })
        var uniqueName = presetName
        var counter = 1
        while allPresetNames.contains(uniqueName.lowercased()) {
            uniqueName = "\(presetName) \(counter)"
            counter += 1
        }
        return uniqueName
    }
}

extension PresetManager {
    private static func makeRandomPreset(speciesCount: Int, forceMatrixType: MatrixType = .random) -> SimulationPreset {
        return SimulationPreset(
            name: "Random \(speciesCount)x\(speciesCount)",
            numSpecies: speciesCount,
            numParticles: .k40,
            forceMatrixType: forceMatrixType,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 11,
            worldSize: 1.0
        )
    }
    
    private static func makeEmptyPreset(speciesCount: Int) -> SimulationPreset {
        
        let emptyMatrix = MatrixType.custom(Array(repeating: Array(repeating: 0.0, count: speciesCount), count: speciesCount))
        
        return SimulationPreset(
            name: "Empty \(speciesCount)x\(speciesCount)",
            numSpecies: speciesCount,
            numParticles: ParticleCount.particles(for: speciesCount),
            forceMatrixType: emptyMatrix,
            distributionType: .uniform,
            maxDistance: 0.65,
            minDistance: 0.04,
            beta: 0.3,
            friction: 0.2,
            repulsion: 0.03,
            pointSize: 5,
            worldSize: 0.5
        )
    }
    
    private static let inchworm = SimulationPreset(
        name: "Inchworm",
        numSpecies: 6,
        numParticles: .k30,
        forceMatrixType: .snakes,
        distributionType: .colorBands,
        maxDistance: 0.8,
        minDistance: 0.08,
        beta: 0.28,
        friction: 0.3,
        repulsion: 0.04,
        pointSize: 21,
        worldSize: 1.0
    )
    
    private static let cells = SimulationPreset(
        name: "Cells",
        numSpecies: 3,
        numParticles: .k40,
        forceMatrixType: .custom([
            [-1.00,  -0.25,  1.00],
            [-0.25,  0.50,  -0.25],
            [1.00,  -0.25,  -1.00]
        ]),
        distributionType: .uniform,
        maxDistance: 0.80,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 15,
        worldSize: 1.25
    )
    
    private static let comet = SimulationPreset(
        name: "Comet",
        numSpecies: 3,
        numParticles: .k40,
        forceMatrixType: .custom([
            [-1.00, 1.00, -0.25],
            [1.00, -1.00, 0.50],
            [-0.25, -0.25, 0.50]
        ]),
        distributionType: .uniform,
        maxDistance: 1.5,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.20,
        repulsion: 0.03,
        pointSize: 17,
        worldSize: 2.00
    )
    
    private static let aliens = SimulationPreset(
        name: "Aliens",
        numSpecies: 9,
        numParticles: .k40,
        forceMatrixType: .custom([
            [0.99, 0.16, -0.79, 0.89, -0.13, 0.94, 0.94, 0.33, 0.18],
            [-0.68, -0.99, 0.63, 0.30, 0.26, 0.32, 0.06, 0.63, 0.47],
            [-0.59, -0.64, 0.81, -0.17, -0.97, 0.68, 0.90, 0.19, 0.31],
            [-0.40, 0.98, 0.74, 0.61, 0.08, 0.75, 0.82, 0.99, 0.80],
            [-0.41, -0.70, -0.36, -0.34, 0.09, 0.58, -0.29, 0.76, -0.61],
            [0.27, -0.70, 0.72, -0.90, -0.27, 0.45, 0.21, 0.61, -0.70],
            [-0.37, 0.26, 0.98, -0.66, 0.83, -0.83, -1.00, 0.88, 0.11],
            [0.66, 0.28, 0.30, 0.81, -0.23, -0.63, 0.59, 0.10, -0.23],
            [0.94, 0.87, -0.77, -0.56, -0.11, -0.92, 0.40, 0.22, -0.44]
        ]),
        distributionType: .colorWheel,
        maxDistance: 0.75,
        minDistance: 0.04,
        beta: 0.30,
        friction: 0.10,
        repulsion: 0.03,
        pointSize: 19,
        worldSize: 4
    )
    
    private static let snuggleBugs = SimulationPreset(
        name: "Snuggle Bugs",
        numSpecies: 9,
        numParticles: .k40,
        forceMatrixType: .custom([
            [0.25, 0.20, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.25, 0.20, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.25, 0.20, 0.00, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.25, 0.20, 0.00, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.25, 0.20, 0.00, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.25, 0.20, 0.00, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.25, 0.20, 0.00],
            [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.25, 0.20],
            [0.20, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.25]
        ]),
        distributionType: .uniform,
        maxDistance: 0.50,
        minDistance: 0.05,
        beta: 0.1,
        friction: 0.20,
        repulsion: 0.01,
        pointSize: 17,
        worldSize: 1.0
    )
}
