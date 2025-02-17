//
//  Settings.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI
import Combine

struct ConfigurableSetting {
    var value: Float {
        didSet {
            onChange?(value) // ✅ Triggers the update when `value` changes
        }
    }
    
    let defaultValue: Float
    let min: Float
    let max: Float
    let step: Float
    let format: String
    var onChange: ((Float) -> Void)? // ✅ Callback for updates
}

class SimulationSettings: ObservableObject {
    static let shared = SimulationSettings()

    @Published var maxDistance = ConfigurableSetting(
        value: 0.65, defaultValue: 0.65, min: 0.5, max: 1.5, step: 0.05, format: "%.2f",
        onChange: { _ in BufferManager.shared.updatePhysicsBuffers() }
    )

    @Published var minDistance = ConfigurableSetting(
        value: 0.04, defaultValue: 0.04, min: 0.01, max: 0.1, step: 0.01, format: "%.2f",
        onChange: { _ in BufferManager.shared.updatePhysicsBuffers() }
    )

    @Published var beta = ConfigurableSetting(
        value: 0.3, defaultValue: 0.3, min: 0.1, max: 0.5, step: 0.025, format: "%.2f",
        onChange: { _ in BufferManager.shared.updatePhysicsBuffers() }
    )

    @Published var friction = ConfigurableSetting(
        value: 0.2, defaultValue: 0.2, min: 0, max: 0.5, step: 0.05, format: "%.2f",
        onChange: { _ in BufferManager.shared.updatePhysicsBuffers() }
    )

    @Published var repulsion = ConfigurableSetting(
        value: 0.03, defaultValue: 0.03, min: 0.01, max: 0.2, step: 0.01, format: "%.2f",
        onChange: { _ in BufferManager.shared.updatePhysicsBuffers() }
    )

    @Published var pointSize = ConfigurableSetting(
        value: 7.0, defaultValue: 7.0, min: 3.0, max: 25.0, step: 2.0, format: "%.0f",
        onChange: { _ in BufferManager.shared.updatePhysicsBuffers() }
    )

    @Published var selectedPreset: SimulationPreset = .defaultPreset {
        didSet {
            applyPreset(selectedPreset)
        }
    }

    let presetApplied = PassthroughSubject<Void, Never>()
    
    func applyPreset(_ preset: SimulationPreset, sendEvent: Bool = true) {
        maxDistance.value = preset.maxDistance
        minDistance.value = preset.minDistance
        beta.value = preset.beta
        friction.value = preset.friction
        repulsion.value = preset.repulsion
        pointSize.value = preset.pointSize

        if sendEvent {
            presetApplied.send()
        }
    }
}
