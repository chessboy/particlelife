//
//  ParticleSystem.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Metal
import simd
import SwiftUI
import Combine

class ParticleSystem: ObservableObject {
    static let shared = ParticleSystem()
    
    private var particles: [Particle] = []

    @Published var interactionMatrix: [[Float]] = []
    @Published var speciesColors: [Color] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970

    init() {
        let preset = SimulationPreset.defaultPreset
        
        generateParticles(preset: preset)
        generateNewMatrix(preset: preset)
        SimulationSettings.shared.applyPreset(.defaultPreset, sendEvent: false)
        updatePhysicsAndBuffers()
        
        // listen for changes when a preset is applied
        SimulationSettings.shared.presetApplied
            .sink { [weak self] in self?.respawn(shouldGenerateNewMatrix: true) }
            .store(in: &cancellables)
    }
    
    /// Updates buffers and physics settings
    private func updatePhysicsAndBuffers() {
        BufferManager.shared.clearParticleBuffers()
        BufferManager.shared.initializeParticleBuffers(
            particles: particles,
            interactionMatrix: interactionMatrix,
            numSpecies: SimulationSettings.shared.selectedPreset.numSpecies
        )
        BufferManager.shared.updatePhysicsBuffers()
        BufferManager.shared.updateCameraBuffer(cameraPosition: .zero)
        BufferManager.shared.updateZoomBuffer(zoomLevel: 1.0)
    }

    /// Resets the simulation and regenerates particles
    func respawn(shouldGenerateNewMatrix: Bool) {
        let preset = SimulationSettings.shared.selectedPreset
        print("respawning: \(preset.name)")
        generateParticles(preset: preset)
        if shouldGenerateNewMatrix {
            generateNewMatrix(preset: preset)
        }
        updatePhysicsAndBuffers()
    }
    
    /// Generates a new set of particles
    private func generateParticles(preset: SimulationPreset) {
        particles = ParticleGenerator.generate(distribution: preset.distributionType, count: preset.numParticles.rawValue, numSpecies: preset.numSpecies)

        let worldSize = SimulationSettings.shared.worldSize.value
        let scaleFactorX = worldSize * Constants.ASPECT_RATIO  // Scale X differently to match screen proportions
        let scaleFactorY = worldSize  // Keep Y as worldSize

        // Scale particle positions based on screen shape
        for i in particles.indices {
            particles[i].position.x *= scaleFactorX
            particles[i].position.y *= scaleFactorY
        }
    }
    
    /// Generates a new interaction matrix and updates colors
    private func generateNewMatrix(preset: SimulationPreset) {
        interactionMatrix = MatrixGenerator.generateInteractionMatrix(numSpecies: preset.numSpecies, type: preset.forceMatrixType)
        generateSpeciesColors(numSpecies: preset.numSpecies)
    }

    /// Generates colors for each species
    private func generateSpeciesColors(numSpecies: Int) {
        let predefinedColors = Constants.speciesColors
            
        DispatchQueue.main.async {
            self.speciesColors = (0..<numSpecies).map { species in
                predefinedColors[species % predefinedColors.count]
            }
            self.objectWillChange.send()
        }
    }

    /// Returns a string representation of the interaction matrix
    func getInteractionMatrixString() -> String {
        return "[\n" + interactionMatrix
            .map { "        [" + $0.map { String(format: "%.2f", $0) }.joined(separator: ", ") + "]" }
            .joined(separator: ",\n") + "\n    ]"
    }
    
    func dumpPresetAsCode() {
        let settings = SimulationSettings.shared
        let preset = settings.selectedPreset

        let code = """
        static let untitledPreset = SimulationPreset(
            name: "Untitled",
            numSpecies: \(preset.numSpecies),
            numParticles: .\(preset.numParticles),
            forceMatrixType: .custom(\(getInteractionMatrixString())),
            distributionType: .\(preset.distributionType),
            maxDistance: \(String(format: "%.2f", settings.maxDistance.value)),
            minDistance: \(String(format: "%.2f", settings.minDistance.value)),
            beta: \(String(format: "%.2f", settings.beta.value)),
            friction: \(String(format: "%.2f", settings.friction.value)),
            repulsion: \(String(format: "%.2f", settings.repulsion.value)),
            pointSize: \(Int(settings.pointSize.value)),
            worldSize: \(String(format: "%.2f", settings.worldSize.value))
        )
        """

        print(code)
    }

    var lastDT: Float = 0.001
    
    /// Updates delta time for particle movement
    func update() {
        let currentTime = Date().timeIntervalSince1970
        var dt = Float(currentTime - lastUpdateTime)
        dt = max(0.0001, min(dt, 0.01))
        lastUpdateTime = currentTime

        let smoothingFactor: Float = 0.1
        dt = (1.0 - smoothingFactor) * lastDT + smoothingFactor * dt
        
        if abs(dt - lastDT) > 0.0001 {
            BufferManager.shared.updateDeltaTimeBuffer(dt: &dt)
            lastDT = dt
        }
    }
}
