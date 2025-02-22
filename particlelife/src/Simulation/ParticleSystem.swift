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
    private var lastDT: Float = 0.001

    init() {
        let defaultPreset = PresetDefinitions.getDefaultPreset()
        
        SimulationSettings.shared.applyPreset(defaultPreset)
        generateParticles(preset: defaultPreset)
        generateNewMatrix(preset: defaultPreset)
        updatePhysicsAndBuffers()
        
        // listen for changes when a preset is applied
        NotificationCenter.default.addObserver(self, selector: #selector(presetApplied), name: Notification.Name.presetSelected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(presetAppliedNoRespawn), name: Notification.Name.presetSelectedNoRespawn, object: nil)
    }
    
    /// Called when a preset is applied
    @objc private func presetApplied() {
        print("✅ Preset applied - updating Particle System with respawn")
        respawn(shouldGenerateNewMatrix: true)
    }
    
    /// Called when a preset is applied but we don't want to respawn (eg. reset button)
    @objc private func presetAppliedNoRespawn() {
        print("✅ Preset applied - updating Particle System - NO RESPAWN")
        generateNewMatrix(preset: SimulationSettings.shared.selectedPreset)
        BufferManager.shared.updateInteractionBuffer(interactionMatrix: interactionMatrix)
    }

    /// Updates buffers and physics settings
    private func updatePhysicsAndBuffers() {
        BufferManager.shared.clearParticleBuffers()
        BufferManager.shared.initializeParticleBuffers(
            particles: particles,
            interactionMatrix: interactionMatrix,
            speciesCount: SimulationSettings.shared.selectedPreset.speciesCount
        )
        BufferManager.shared.updatePhysicsBuffers()
        BufferManager.shared.updateCameraBuffer(cameraPosition: .zero)
        BufferManager.shared.updateZoomBuffer(zoomLevel: 1.0)
    }

    /// Resets the simulation and regenerates particles
    func respawn(shouldGenerateNewMatrix: Bool) {
        let preset = SimulationSettings.shared.selectedPreset

        generateParticles(preset: preset)
        if shouldGenerateNewMatrix {
            generateNewMatrix(preset: preset)
        }
        updatePhysicsAndBuffers()
    }
    
    func particleCountWillChange(newCount: ParticleCount) {
        let settings = SimulationSettings.shared
        guard newCount != settings.selectedPreset.particleCount else { return }
        
        let newPreset = SimulationSettings.shared.selectedPreset.copy(newParticleCount: newCount)
        generateParticles(preset: newPreset)
        updatePhysicsAndBuffers()
        SimulationSettings.shared.selectedPreset = newPreset
    }
    
    /// Generates a new set of particles
    private func generateParticles(preset: SimulationPreset) {
        particles = ParticleGenerator.generate(distribution: preset.distributionType, particleCount: preset.particleCount, speciesCount: preset.speciesCount)

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
        interactionMatrix = MatrixGenerator.generateInteractionMatrix(speciesCount: preset.speciesCount, type: preset.matrixType)
        generateSpeciesColors(speciesCount: preset.speciesCount)
    }

    /// Generates colors for each species
    private func generateSpeciesColors(speciesCount: Int) {
        let predefinedColors = Constants.speciesColors
            
        DispatchQueue.main.async {
            self.speciesColors = (0..<speciesCount).map { species in
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
            speciesCount: \(preset.speciesCount),
            particleCount: .\(preset.particleCount),
            matrixType: .custom(\(getInteractionMatrixString())),
            distributionType: .\(preset.distributionType),
            maxDistance: \(String(format: "%.2f", settings.maxDistance.value)),
            minDistance: \(String(format: "%.2f", settings.minDistance.value)),
            beta: \(String(format: "%.2f", settings.beta.value)),
            friction: \(String(format: "%.2f", settings.friction.value)),
            repulsion: \(String(format: "%.2f", settings.repulsion.value)),
            pointSize: \(Int(settings.pointSize.value)),
            worldSize: \(String(format: "%.2f", settings.worldSize.value)),
            isBuiltIn: true
        )
        """

        print(code)
    }
    
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
