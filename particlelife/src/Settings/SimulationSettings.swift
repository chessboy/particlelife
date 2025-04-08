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
        value: 0.65, defaultValue: 0.65, minValue: 0.25, maxValue: 1.5, step: 0.05, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var minDistance = ConfigurableSetting(
        value: 0.04, defaultValue: 0.04, minValue: 0.01, maxValue: 0.15, step: 0.01, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var beta = ConfigurableSetting(
        value: 0.3, defaultValue: 0.3, minValue: 0.1, maxValue: 0.5, step: 0.025, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var friction = ConfigurableSetting(
        value: 0.1, defaultValue: 0.1, minValue: 0.01, maxValue: 0.3, step: 0.01, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var repulsion = ConfigurableSetting(
        value: 0.03, defaultValue: 0.03, minValue: 0.01, maxValue: 0.2, step: 0.01, format: "%.2f",
        onChange: { _ in SimulationSettings.shared.scheduleBufferUpdate() }
    )
    
    @Published var pointSize = ConfigurableSetting(
        value: 11.0, defaultValue: 11.0, minValue: 1.0, maxValue: 30.0, step: 1.0, format: "%.0f",
        onChange:{ newValue in handlePointSizeChange(newValue) }
    )
    
    @Published var worldSize = ConfigurableSetting(
        value: 1.0, defaultValue: 1.0, minValue: 0.5, maxValue: 4, step: 0.25, format: "%.2f",
        onChange: { newValue in handleWorldSizeChange(newValue) }
    )
    
    @Published var colorOffset: Int = 0 {
        didSet {
            BufferManager.shared.updateColorOffset(colorOffset: colorOffset)
        }
    }
    
    @Published var paletteIndex: Int = 0 {
        didSet {
            BufferManager.shared.updatePaletteIndex(paletteIndex: paletteIndex)
        }
    }
        
    @Published var colorEffect: ColorEffect = .none {
        didSet {
            BufferManager.shared.updateColorEffect(colorEffect: colorEffect)
        }
    }
    
    func incrementColorOffset() {
        colorOffset = (colorOffset + 1) % ColorPalette.speciesCount
    }
    
    func decrementColorOffset() {
        colorOffset = (colorOffset - 1 + ColorPalette.speciesCount) % ColorPalette.speciesCount
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
    
    func nextColorEffect(direction: Int = 1) {
        colorEffect = colorEffect.nextColorEffect(direction: direction)
    }
}

extension SimulationSettings {
    
    private static func handlePointSizeChange(_ newValue: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 50ms debounce
            if shared.pointSize.value == newValue { // Ensure consistency
                BufferManager.shared.updatePointSize(pointSize: newValue)
            }
        }
    }
    
    func updateMatrixType(_ newType: MatrixType) {
        if newType.isRandom {
            selectedPreset = selectedPreset.copy(withName: "Random", newMatrixType: newType)
        } else {
            selectedPreset = selectedPreset.copy(withName: "New", newMatrixType: newType)
        }
        ParticleSystem.shared.respawn(shouldGenerateNewMatrix: true)
    }
    
    func updateSpeciesDistribution(_ newDistribution: SpeciesDistribution) {
        guard selectedPreset.speciesDistribution != newDistribution else { return }
        
        selectedPreset = selectedPreset.copy(newSpeciesDistribution: newDistribution)
        ParticleSystem.shared.respawn(shouldGenerateNewMatrix: false)
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
        colorOffset = preset.colorOffset
        paletteIndex = preset.paletteIndex
        colorEffect = preset.colorEffect
    }
}

extension SimulationSettings {
    func saveCurrentPreset(named presetName: String, matrix: [[Float]], speciesDistribution: SpeciesDistribution, replaceExisting: Bool = false) {
        let newPreset = SimulationPreset(
            name: presetName,
            speciesCount: selectedPreset.speciesCount,
            particleCount: selectedPreset.particleCount,
            speciesDistribution: speciesDistribution,
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
            colorOffset: colorOffset,
            paletteIndex: paletteIndex,
            colorEffect: colorEffect
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
                Logger.log("Preset '\(persistedPreset.name)' (ID: \(persistedPreset.id)) not found after multiple attempts!", level: .error)
            }
        }
        
        attemptSelection()
    }
}
