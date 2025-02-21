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
            onChange?(value)
        }
    }
    
    let defaultValue: Float
    let min: Float
    let max: Float
    let step: Float
    let format: String
    var onChange: ((Float) -> Void)?
}

class SimulationSettings: ObservableObject {
    static let shared = SimulationSettings()
    @Published var userPresets: [SimulationPreset] = PresetManager.shared.getUserPresets()
    @Published var selectedPreset: SimulationPreset = PresetDefinitions.getDefaultPreset()

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
        value: 11.0, defaultValue: 11.0, min: 3.0, max: 25.0, step: 2.0, format: "%.0f",
        onChange:{ newValue in handlePointSizeChange(newValue) }
    )
    
    @Published var worldSize = ConfigurableSetting(
        value: 1.0, defaultValue: 1.0, min: 0.5, max: 4, step: 0.25, format: "%.2f",
        onChange: { newValue in handleWorldSizeChange(newValue) }
    )
        
    private static func handlePointSizeChange(_ newValue: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 50ms debounce
            if shared.pointSize.value == newValue { // Ensure consistency
                BufferManager.shared.updatePhysicsBuffers()
            }
        }
    }
    
    private static func handleWorldSizeChange(_ newValue: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 50ms debounce
            if shared.worldSize.value == newValue { // Ensure consistency
                BufferManager.shared.updatePhysicsBuffers()
            }
        }
    }
    
    func selectPreset(_ preset: SimulationPreset, skipRespawn: Bool = false) {
        guard let storedPreset = PresetManager.shared.getPreset(named: preset.name) else {
            print("❌ Error: Preset '\(preset.name)' not found in storage.")
            return
        }

        selectedPreset = storedPreset
        applyPreset(selectedPreset)
        
        if skipRespawn {
            NotificationCenter.default.post(name: .presetSelectedNoRespawn, object: nil)
        } else {
            NotificationCenter.default.post(name: .presetSelected, object: nil)
        }
    }
    
    func applyPreset(_ preset: SimulationPreset) {
        maxDistance.value = preset.maxDistance
        minDistance.value = preset.minDistance
        beta.value = preset.beta
        friction.value = preset.friction
        repulsion.value = preset.repulsion
        pointSize.value = preset.pointSize
        worldSize.value = preset.worldSize
    }
        
    func saveCurrentPreset(named presetName: String, interactionMatrix: [[Float]]) {
        let newPreset = SimulationPreset(
            name: presetName,
            numSpecies: selectedPreset.numSpecies,
            numParticles: selectedPreset.numParticles,
            forceMatrixType: .custom(interactionMatrix),
            distributionType: selectedPreset.distributionType,
            maxDistance: maxDistance.value,
            minDistance: minDistance.value,
            beta: beta.value,
            friction: friction.value,
            repulsion: repulsion.value,
            pointSize: pointSize.value,
            worldSize: worldSize.value,
            isBuiltIn: false
        )
        
        let persistedPreset = PresetManager.shared.addUserPreset(newPreset)
        userPresets = PresetManager.shared.getUserPresets()
        selectedPreset = persistedPreset
    }
}
