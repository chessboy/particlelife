//
//  Settings.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI
import Combine

class SimulationSettings: ObservableObject {
    static let shared = SimulationSettings()

    @Published var selectedPreset: SimulationPreset = .defaultPreset {
        didSet {
            applyPreset(selectedPreset)
        }
    }

    static let maxDistanceDefault: Float = 0.64
    static let maxDistanceMin: Float = 0.5
    static let maxDistanceMax: Float = 1.5

    static let minDistanceDefault: Float = 0.04
    static let minDistanceMin: Float = 0.01
    static let minDistanceMax: Float = 0.1

    static let betaDefault: Float = 0.3
    static let betaMin: Float = 0.1
    static let betaMax: Float = 0.5

    static let frictionDefault: Float = 0.2
    static let frictionMin: Float = 0
    static let frictionMax: Float = 0.5

    static let repulsionStrengthDefault: Float = 0.03
    static let repulsionStrengthMin: Float = 0.01
    static let repulsionStrengthMax: Float = 0.2

    @Published var maxDistance: Float = maxDistanceDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var minDistance: Float = minDistanceDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var beta: Float = betaDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var friction: Float = frictionDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }
    @Published var repulsionStrength: Float = repulsionStrengthDefault { didSet { BufferManager.shared.updatePhysicsBuffers() } }

    let presetApplied = PassthroughSubject<Void, Never>()
    
    func applyPreset(_ preset: SimulationPreset, sendEvent: Bool = true) {
        maxDistance = preset.maxDistance
        minDistance = preset.minDistance
        beta = preset.beta
        friction = preset.friction
        repulsionStrength = preset.repulsionStrength
        
        if sendEvent {
            presetApplied.send()
        }
    }
}
