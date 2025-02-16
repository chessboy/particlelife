//
//  ParticleSystem.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Metal
import simd
import SwiftUI

class ParticleSystem: ObservableObject {
    static let shared = ParticleSystem()

    @Published var interactionMatrix: [[Float]] = []
    @Published var speciesColors: [Color] = []
    
    var numSpecies: Int = 6
    var particles: [Particle] = []
    var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970

    init() {
        generateParticles()

        //SettingsGenerator.applyPreset(.snakes)
        generateNewMatrix()
        updatePhysicsAndBuffers()
    }
    
    /// Updates buffers and physics settings
    private func updatePhysicsAndBuffers() {
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
        generateParticles()
        generateNewMatrix()
        updatePhysicsAndBuffers()
    }
    
    /// Generates a new set of particles
    private func generateParticles() {
        //return ParticleGenerator.colorBands(count: Constants.defaultParticleCount, numSpecies: 6)
        particles = ParticleGenerator.uniform(count: Constants.defaultParticleCount, numSpecies: 6)
    }
    
    /// Generates a new interaction matrix and updates colors
    private func generateNewMatrix() {
        interactionMatrix = MatrixGenerator.generateInteractionMatrix(numSpecies: numSpecies, type: .random)
        generateSpeciesColors()
        BufferManager.shared.updateInteractionMatrix(matrix: interactionMatrix, numSpecies: numSpecies)
    }

    /// Generates colors for each species
    private func generateSpeciesColors() {
        let predefinedColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

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
