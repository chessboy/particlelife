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
        value: 11.0, defaultValue: 5, min: 1.0, max: 15.0, step: 1.0, format: "%.0f",
        onChange:{ newValue in handlePointSizeChange(newValue) }
    )
    
    @Published var worldSize = ConfigurableSetting(
        value: 1.0, defaultValue: 1.0, min: 0.5, max: 4, step: 0.25, format: "%.2f",
        onChange: { newValue in handleWorldSizeChange(newValue) }
    )
    
    @Published var speciesColorOffset: Int = 0 {
        didSet {
            BufferManager.shared.updatePhysicsBuffers()
        }
    }
}

extension SimulationSettings {
    
    private static func handlePointSizeChange(_ newValue: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 50ms debounce
            if shared.pointSize.value == newValue { // Ensure consistency
                BufferManager.shared.updatePhysicsBuffers()
            }
        }
    }
    
    func updateMatrixType(_ newType: MatrixType) {
        selectedPreset = selectedPreset.copy(newMatrixType: newType)
        NotificationCenter.default.post(name: .presetSelected, object: nil)
    }
    
    func updateDistributionType(_ newType: DistributionType) {
        selectedPreset = selectedPreset.copy(newDistributionType: newType)
        NotificationCenter.default.post(name: .presetSelected, object: nil)
    }
    
    private static func handleWorldSizeChange(_ newValue: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { // 50ms debounce
            if shared.worldSize.value == newValue { // Ensure consistency
                BufferManager.shared.updatePhysicsBuffers()
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
    }
    
    func selectPreset(_ preset: SimulationPreset, skipRespawn: Bool = false) {
        
        Logger.log("Attempting to select preset '\(preset.name)' (ID: \(preset.id))", level: .debug)
        
        let allPresets = PresetDefinitions.getAllBuiltInPresets() + userPresets
        //let availablePresets = allPresets.map { "\($0.name) (ID: \($0.id))" }
        //Logger.log("Available presets: \n\(availablePresets.joined(separator: "\n"))", level: .debug)
        
        guard let storedPreset = allPresets.first(where: { $0.id == preset.id }) else {
            Logger.log("ERROR: Preset '\(preset.name)' (ID: \(preset.id)) not found in storage!", level: .error)
            return
        }
        
        Logger.log("Preset '\(preset.name)' found. Selecting it now.", level: .debug)
        
        var presetToApply = storedPreset
        
        if !storedPreset.shouldResetSpeciesCount {
            Logger.log("Preserving speciesCount (\(selectedPreset.speciesCount)) while selecting preset '\(preset.name)'", level: .debug)
            presetToApply = storedPreset.copy(newSpeciesCount: selectedPreset.speciesCount)  // Carry over species count
        } else {
            Logger.log("Ignoring previous speciesCount (\(selectedPreset.speciesCount)), using preset value: \(storedPreset.speciesCount)", level: .debug)
        }
        
        selectedPreset = presetToApply
        applyPreset(selectedPreset)
        
        if skipRespawn {
            NotificationCenter.default.post(name: .presetSelectedNoRespawn, object: nil)
        } else {
            NotificationCenter.default.post(name: .presetSelected, object: nil)
        }
    }
}

extension SimulationSettings {
    func saveCurrentPreset(named presetName: String, interactionMatrix: [[Float]], replaceExisting: Bool = false) {
        let newPreset = SimulationPreset(
            name: presetName,
            speciesCount: selectedPreset.speciesCount,
            particleCount: selectedPreset.particleCount,
            matrixType: .custom(interactionMatrix),
            distributionType: selectedPreset.distributionType,
            maxDistance: maxDistance.value,
            minDistance: minDistance.value,
            beta: beta.value,
            friction: friction.value,
            repulsion: repulsion.value,
            pointSize: pointSize.value,
            worldSize: worldSize.value,
            isBuiltIn: false,
            shouldResetSpeciesCount: true,
            speciesColorOffset: speciesColorOffset
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
