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
    private var cancellables = Set<AnyCancellable>()

    @Published var interactionMatrix: [[Float]] = []
    @Published var speciesColors: [Color] = []
    
    var numSpecies = Constants.numSpecies
    var particles: [Particle] = []
    var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970

    init() {
        let preset = SimulationPreset.defaultPreset
        
        generateParticles(preset: preset)
        generateNewMatrix(preset: preset)
        updatePhysicsAndBuffers()
        
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
            numSpecies: numSpecies
        )
        BufferManager.shared.updatePhysicsBuffers()
        BufferManager.shared.updateCameraBuffer(position: .zero)
        BufferManager.shared.updateZoomBuffer(zoom: 1.0)
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
        particles = ParticleGenerator.generate(distribution: preset.distributionType, count: preset.numParticles.rawValue, numSpecies: preset.numSpecies)
    }
    
    /// Generates a new interaction matrix and updates colors
    private func generateNewMatrix(preset: SimulationPreset) {
        interactionMatrix = MatrixGenerator.generateInteractionMatrix(numSpecies: preset.numSpecies, type: preset.forceMatrixType)
        generateSpeciesColors()
    }

    /// Generates colors for each species
    private func generateSpeciesColors() {
        let predefinedColors = Constants.speciesColors
            
        DispatchQueue.main.async {
            self.speciesColors = (0..<self.numSpecies).map { species in
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

    /// Updates delta time for particle movement
    func update() {
        let currentTime = Date().timeIntervalSince1970
        var dt = Float(currentTime - lastUpdateTime)
        dt = max(0.0001, min(dt, 0.01))
        lastUpdateTime = currentTime

        BufferManager.shared.updateDeltaTimeBuffer(dt: &dt)
    }
}
