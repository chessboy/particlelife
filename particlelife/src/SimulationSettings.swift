//
//  Settings.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI

class SimulationSettings: ObservableObject {
    static let shared = SimulationSettings()

    static let maxDistanceDefault: Float = 0.64
    static let maxDistanceMin: Float = 0.5
    static let maxDistanceMax: Float = 1.5

    static let minDistanceDefault: Float = 0.03
    static let minDistanceMin: Float = 0.01
    static let minDistanceMax: Float = 0.1

    static let betaDefault: Float = 0.3
    static let betaMin: Float = 0.1
    static let betaMax: Float = 0.5

    static let frictionDefault: Float = 0.8
    static let frictionMin: Float = 0.5
    static let frictionMax: Float = 1.0

    static let repulsionStrengthDefault: Float = 0.03
    static let repulsionStrengthMin: Float = 0.01
    static let repulsionStrengthMax: Float = 0.2

    @Published var maxDistance: Float = maxDistanceDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var minDistance: Float = minDistanceDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var beta: Float = betaDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var friction: Float = frictionDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var repulsionStrength: Float = repulsionStrengthDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }

    func resetToDefaults() {
        maxDistance = SimulationSettings.maxDistanceDefault
        minDistance = SimulationSettings.minDistanceDefault
        beta = SimulationSettings.betaDefault
        friction = SimulationSettings.frictionDefault
        repulsionStrength = SimulationSettings.repulsionStrengthDefault
        print("Physics settings reset to defaults.")
    }
}
