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
            .sink { [weak self] in self?.reset() }
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
    func reset() {
        let preset = SimulationSettings.shared.selectedPreset
        print("resetting: \(preset.name)")
        generateParticles(preset: preset)
        generateNewMatrix(preset: preset)
        updatePhysicsAndBuffers()
    }
    
    /// Generates a new set of particles
    private func generateParticles(preset: SimulationPreset) {
        //numSpecies = preset.numSpecies
        particles = ParticleGenerator.generate(distribution: preset.distributionType, count: preset.numParticles.rawValue, numSpecies: preset.numSpecies)
        
        let worldSize = SimulationSettings.shared.worldSize.value
        let scaleFactor = worldSize / 1.0
        print("scaling particle positions by \(scaleFactor)")
        for i in particles.indices {
            particles[i].position *= scaleFactor
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
        return interactionMatrix
            .map { $0.map { String(format: "%.2f", $0) }.joined(separator: "  ") }
            .joined(separator: "\n")
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
