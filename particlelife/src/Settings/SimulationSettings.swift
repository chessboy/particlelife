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
    
    mutating func returnToDefault() {
        value = defaultValue
    }
}

class SimulationSettings: ObservableObject {
    static let shared = SimulationSettings()

    @Published var userPresets: [SimulationPreset] = PresetManager.shared.getUserPresets()
    @Published var selectedPreset: SimulationPreset = PresetDefinitions.getDefaultPreset()
    
    private var bufferUpdateWorkItem: DispatchWorkItem?

    private func scheduleBufferUpdate() {
        bufferUpdateWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            BufferManager.shared.updatePhysicsBuffers()
        }
        bufferUpdateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem) // 50ms delay
    }

    @Published var maxDistance = ConfigurableSetting(
        value: 0.65, defaultValue: 0.65, min: 0.25, max: 1.5, step: 0.05, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var minDistance = ConfigurableSetting(
        value: 0.04, defaultValue: 0.04, min: 0.01, max: 0.1, step: 0.01, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var beta = ConfigurableSetting(
        value: 0.3, defaultValue: 0.3, min: 0.1, max: 0.5, step: 0.025, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var friction = ConfigurableSetting(
        value: 0.1, defaultValue: 0.1, min: 0.02, max: 0.3, step: 0.02, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var repulsion = ConfigurableSetting(
        value: 0.03, defaultValue: 0.03, min: 0.01, max: 0.2, step: 0.01, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var pointSize = ConfigurableSetting(
        value: 11.0, defaultValue: 5, min: 1.0, max: 25.0, step: 1.0, format: "%.0f",
        onChange:{ newValue in handlePointSizeChange(newValue) }
    )
    
    @Published var worldSize = ConfigurableSetting(
        value: 1.0, defaultValue: 1.0, min: 0.5, max: 4, step: 0.25, format: "%.2f",
        onChange: { newValue in handleWorldSizeChange(newValue) }
    )
    
    @Published var speciesColorOffset: Int = 0 {
        didSet {
            SimulationSettings.shared.scheduleBufferUpdate()
        }
    }
    
    @Published var paletteIndex: Int = 0 {
        didSet {
            SimulationSettings.shared.scheduleBufferUpdate()
        }
    }
        
    @Published var colorEffectIndex: Int = 0 {
        didSet {
            SimulationSettings.shared.scheduleBufferUpdate()
        }
    }
    
    func incrementSpeciesColorOffset() {
        speciesColorOffset = (speciesColorOffset + 1) % ColorPalette.speciesCount
    }
    
    func decrementSpeciesColorOffset() {
        speciesColorOffset = (speciesColorOffset - 1 + ColorPalette.speciesCount) % ColorPalette.speciesCount
    }
    
    func incrementPaletteIndex() {
        paletteIndex = (paletteIndex + 1) % ColorPalette.allCases.count
    }
    
    func decrementPaletteIndex() {
        paletteIndex = (paletteIndex - 1 + ColorPalette.allCases.count) % ColorPalette.allCases.count
    }
    
    func nextDistributionType(direction: Int = 1) {
        updateDistributionType(selectedPreset.distributionType.nextDistributionType(direction: direction))
    }
    
    func toggleColorEffect() {
        colorEffectIndex = 1 - colorEffectIndex
    }
}

extension SimulationSettings {
    
    private static func handlePointSizeChange(_ newValue: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 50ms debounce
            if shared.pointSize.value == newValue { // Ensure consistency
                SimulationSettings.shared.scheduleBufferUpdate()
            }
        }
    }
    
    func updateMatrixType(_ newType: MatrixType) {
        selectedPreset = selectedPreset.copy(newMatrixType: newType)
        ParticleSystem.shared.respawn(shouldGenerateNewMatrix: true)
    }
    
    func updateDistributionType(_ newType: DistributionType) {
        selectedPreset = selectedPreset.copy(newDistributionType: newType)
        ParticleSystem.shared.respawn(shouldGenerateNewMatrix: false)
    }
    
    private static func handleWorldSizeChange(_ newValue: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 50ms debounce
            if shared.worldSize.value == newValue { // Ensure consistency
                SimulationSettings.shared.scheduleBufferUpdate()
            }
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
        speciesColorOffset = preset.speciesColorOffset
        paletteIndex = preset.paletteIndex
        colorEffectIndex = preset.colorEffectIndex
    }
}

extension SimulationSettings {
    func saveCurrentPreset(named presetName: String, matrix: [[Float]], replaceExisting: Bool = false) {
        let newPreset = SimulationPreset(
            name: presetName,
            speciesCount: selectedPreset.speciesCount,
            particleCount: selectedPreset.particleCount,
            matrixType: .custom(matrix),
            distributionType: selectedPreset.distributionType,
            maxDistance: maxDistance.value,
            minDistance: minDistance.value,
            beta: beta.value,
            friction: friction.value,
            repulsion: repulsion.value,
            pointSize: pointSize.value,
            worldSize: worldSize.value,
            isBuiltIn: false,
            preservesUISettings: false,
            speciesColorOffset: speciesColorOffset,
            paletteIndex: paletteIndex,
            colorEffectIndex: colorEffectIndex
        )
        
        // Save preset
        let persistedPreset = UserPresetStorage.saveUserPreset(newPreset, replaceExisting: replaceExisting)
        
        // Ensure `userPresets` updates before selecting
        userPresets = UserPresetStorage.loadUserPresets()
        
        // Poll every 50ms for up to 1 second to ensure the preset is loaded
        var retryCount = 0
        let maxRetries = 20
        
        func attemptSelection() {
            if let updatedPreset = self.userPresets.first(where: { $0.id == persistedPreset.id }) {
                self.selectedPreset = updatedPreset
                Logger.log("selected preset found after \(retryCount) tr\(retryCount == 1 ? "y" : "ies")")
            } else if retryCount < maxRetries {
                retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { attemptSelection() }
                
            } else {
                Logger.log("ERROR: Preset '\(persistedPreset.name)' (ID: \(persistedPreset.id)) not found after multiple attempts!", level: .error)
            }
        }
        
        attemptSelection()
    }
}
