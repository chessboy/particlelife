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
    @Published var speciesColors: [Color] = []  // Ensure this is @Published
    
    var numSpecies: Int
    var particles: [Particle]
    
    var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970

    init(numSpecies: Int = 6) {
        self.numSpecies = numSpecies
        self.particles = (0..<Constants.defaultParticleCount).map { _ in Particle.create(numSpecies: numSpecies) }

        generateNewMatrix()
        updatePhysicsAndBuffers()
    }

    /// Centralized function to update physics and buffers
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

    func reset() {
        print("🔄 Resetting simulation...")

        generateNewMatrix()

        for i in 0..<particles.count {
            particles[i].randomize(numSpecies: numSpecies)
        }

        updatePhysicsAndBuffers()
    }

    private func generateNewMatrix() {
        interactionMatrix = generateInteractionMatrix(numSpecies: numSpecies)
        generateSpeciesColors(numSpecies: numSpecies)
        BufferManager.shared.updateInteractionMatrix(matrix: interactionMatrix, numSpecies: numSpecies)
    }

    private func generateSpeciesColors(numSpecies: Int) {
        let predefinedColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

        DispatchQueue.main.async {
            self.speciesColors = numSpecies > predefinedColors.count
                ? (0..<numSpecies).map { _ in Color(hue: Double.random(in: 0...1), saturation: 0.8, brightness: 0.9) }
                : Array(predefinedColors.prefix(numSpecies))
            
            self.objectWillChange.send()  // Force UI refresh
        }
    }

    func getInteractionMatrixString() -> String {
        return interactionMatrix
            .map { $0.map { String(format: "%.2f", $0) }.joined(separator: "  ") }
            .joined(separator: "\n")
    }

    func update() {
        let currentTime = Date().timeIntervalSince1970
        var dt = Float(currentTime - lastUpdateTime)
        dt = max(0.0001, min(dt, 0.01))
        lastUpdateTime = currentTime

        BufferManager.shared.updateDeltaTimeBuffer(dt: &dt)
    }
}
