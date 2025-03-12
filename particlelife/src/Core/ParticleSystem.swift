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

    var renderer: Renderer?
    private var particles: [Particle] = []
    
    @Published var matrix: [[Float]] = []
    @Published private(set) var speciesColors: [Color] = []
    
    private var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970
    private var lastDT: Float = 0.001
    
    init() {
        
        PresetDefinitions.loadSpecialPresets()
        let initialPreset = PresetDefinitions.randomSpecialPreset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.selectPreset(initialPreset)
        }
    }
            
    /// Updates buffers and physics settings
    private func updatePhysicsAndBuffers(preset: SimulationPreset) {
        BufferManager.shared.updateParticleBuffers(
            particles: particles,
            matrix: matrix,
            speciesCount: preset.speciesCount
        )
        BufferManager.shared.updatePhysicsBuffers()
        BufferManager.shared.updateCameraBuffer(cameraPosition: .zero)
        BufferManager.shared.updateZoomBuffer(zoomLevel: 1.0)
    }
    
    /// Resets the simulation and regenerates particles
    func respawn(shouldGenerateNewMatrix: Bool) {
        
        let preset = SimulationSettings.shared.selectedPreset
        
        generateParticles(preset: preset)
        if shouldGenerateNewMatrix {
            generateNewMatrixAndColors(preset: preset, speciesColorOffset: SimulationSettings.shared.speciesColorOffset, paletteIndex: SimulationSettings.shared.paletteIndex)
        }
        updatePhysicsAndBuffers(preset: preset)
    }
    
    func speciesCountWillChange(newCount: Int) {
        let settings = SimulationSettings.shared
        guard newCount != settings.selectedPreset.speciesCount else { return }

        if let renderer = renderer {
            renderer.resetFrameCount()
        }
        
        guard newCount != settings.selectedPreset.speciesCount else {
            Logger.log("No change needed, speciesCount is already \(settings.selectedPreset.speciesCount)", level: .debug)
            return
        }
        
        let newPreset = settings.selectedPreset.copy(newSpeciesCount: newCount)
        
        if newPreset.matrixType.isRandom {
            // try to preseve the matrix as much as possible
            matrix = MatrixGenerator.generateMatrix(speciesCount: newPreset.speciesCount, type: .custom(matrix))
        } else {
            generateNewMatrixAndColors(preset: newPreset, speciesColorOffset: SimulationSettings.shared.speciesColorOffset, paletteIndex: SimulationSettings.shared.paletteIndex)
        }
        
        generateSpeciesColors(speciesCount: newPreset.speciesCount, speciesColorOffset: SimulationSettings.shared.speciesColorOffset, paletteIndex: SimulationSettings.shared.paletteIndex)

        generateParticles(preset: newPreset)
        updatePhysicsAndBuffers(preset: newPreset)
        
        SimulationSettings.shared.selectedPreset = newPreset
    }
    
    func particleCountWillChange(newCount: ParticleCount) {
        let settings = SimulationSettings.shared
        guard newCount != settings.selectedPreset.particleCount else { return }
        
        let newPreset = SimulationSettings.shared.selectedPreset.copy(newParticleCount: newCount)
        generateParticles(preset: newPreset)
        updatePhysicsAndBuffers(preset: newPreset)
        SimulationSettings.shared.selectedPreset = newPreset
    }
    
    /// Generates a new set of particles
    private func generateParticles(preset: SimulationPreset) {
        
        if let renderer = renderer {
            renderer.resetFrameCount()
        }

        particles = ParticleGenerator.generate(
            distribution: preset.distributionType,
            particleCount: preset.particleCount,
            speciesCount: preset.speciesCount
        )
        
        //let uniqueSpecies = Set(particles.map { $0.species })
        //Logger.log("Unique species in new particles: \(uniqueSpecies)", level: .debug)
        
        let worldSize = SimulationSettings.shared.worldSize.value
        let scaleFactorX = preset.distributionType.shouldScaleToAspectRatio ? worldSize * Float(ASPECT_RATIO) : worldSize
        let scaleFactorY = worldSize
        
        if preset.distributionType.shouldRecenter {
            // Compute the centroid before scaling
            var center = SIMD2<Float>(0, 0)
            for p in particles {
                center += p.position
            }
            center /= Float(particles.count) // Compute average center
            
            // Scale, aspect correct, and recenter
            for i in particles.indices {
                particles[i].position.x = (particles[i].position.x - center.x) * scaleFactorX
                particles[i].position.y = (particles[i].position.y - center.y) * scaleFactorY
            }
        } else {
            // Just apply scaling/aspect correction
            for i in particles.indices {
                particles[i].position.x *= scaleFactorX
                particles[i].position.y *= scaleFactorY
            }
        }
        
        Logger.log("particles generated: speciesCount: \(preset.speciesCount), particleCount: \(preset.particleCount), matrixType: \(preset.matrixType.shortString)")
    }
    
    /// Generates a new matrix and updates colors using species color offset
    private func generateNewMatrixAndColors(preset: SimulationPreset, speciesColorOffset: Int, paletteIndex: Int) {
        matrix = MatrixGenerator.generateMatrix(speciesCount: preset.speciesCount, type: preset.matrixType)
        generateSpeciesColors(speciesCount: preset.speciesCount, speciesColorOffset: speciesColorOffset, paletteIndex: paletteIndex)
    }
    
    /// Generates colors for each species based on the selected palette
    private func generateSpeciesColors(speciesCount: Int, speciesColorOffset: Int, paletteIndex: Int) {
        //Logger.log("updateSpeciesColors: speciesCount: \(speciesCount), speciesColorOffset: \(speciesColorOffset), paletteIndex: \(paletteIndex)", level: .debug)
        
        DispatchQueue.main.async {
            guard let selectedPalette = ColorPalette(rawValue: paletteIndex) else { return }
            let predefinedColors = selectedPalette.colors // Get colors directly from the enum
            
            self.speciesColors = (0..<speciesCount).map { predefinedColors[($0 + speciesColorOffset) % predefinedColors.count] }
            self.objectWillChange.send()
        }
    }
    
    func updateSpeciesColors(speciesCount: Int, speciesColorOffset: Int, paletteIndex: Int) {
        generateSpeciesColors(speciesCount: speciesCount, speciesColorOffset: speciesColorOffset, paletteIndex: paletteIndex)
    }
    
    private func updateSpeciesColorsFromSettings() {
        updateSpeciesColors(speciesCount: speciesColors.count,
            speciesColorOffset: SimulationSettings.shared.speciesColorOffset,
            paletteIndex: SimulationSettings.shared.paletteIndex
        )
    }
    
    func dumpCurrentPresetAsJson() {
        UserPresetStorage.printPresetsAsJSON([asPreset])
    }
        
    /// Updates delta time for particle movement
    func update() {
        let currentTime = Date().timeIntervalSince1970
        var dt = Float(currentTime - lastUpdateTime)
        dt = max(0.0001, min(dt, 0.0105)) // Clamp dt was 0.01
        
        let smoothingFactor = SystemCapabilities.shared.smoothingFactor
        
        dt = (1.0 - smoothingFactor) * lastDT + smoothingFactor * dt
        
        // Quantize dt to avoid micro jitter
        let quantizationStep: Float = 0.0004 // was 0.0005
        dt = round(dt / quantizationStep) * quantizationStep
        
        if abs(dt - lastDT) > 0.00005 {
            BufferManager.shared.updateDeltaTimeBuffer(dt: &dt)
            lastDT = dt
        }
                
        lastUpdateTime = currentTime
    }
}

extension ParticleSystem {
    
    // select one of the built-in presets that are not the current preset
    func selectRandomBuiltInPreset() {
        selectPreset(PresetDefinitions.randomSpecialPreset(excluding: SimulationSettings.shared.selectedPreset))
    }
    
    func selectPreset(_ preset: SimulationPreset) {
        
        let settings = SimulationSettings.shared
        let selectedPreset = settings.selectedPreset
        
        Logger.log("Attempting to select preset '\(preset.name)' (ID: \(preset.id))", level: .debug)
        
        let userPresets = UserPresetStorage.loadUserPresets()
        let allPresets = PresetDefinitions.getAllBuiltInPresets() + userPresets
        //let availablePresets = allPresets.map { "\($0.name) (ID: \($0.id))" }
        //Logger.log("Available presets: \n\(availablePresets.joined(separator: "\n"))", level: .debug)
        
        guard let storedPreset = allPresets.first(where: { $0.id == preset.id }) else {
            Logger.log("Preset '\(preset.name)' (ID: \(preset.id)) not found in storage!", level: .error)
            return
        }
        
        var presetToApply = storedPreset

        // optimize particle count for current device
        let gpuCoreCount = SystemCapabilities.shared.gpuCoreCount
        let optimizedCount = storedPreset.particleCount.optimizedParticleCount(for: gpuCoreCount, gpuType: SystemCapabilities.shared.gpuType)
        if storedPreset.particleCount > optimizedCount {
            Logger.log("Optimizing particle count for \(storedPreset.name): \(storedPreset.particleCount.displayString) → \(optimizedCount.displayString)", level: .debug)
            presetToApply = storedPreset.copy(newParticleCount: optimizedCount)
        }
        
        //Logger.log("Preset '\(preset.name)' found. Selecting it now.", level: .debug)
        
        if storedPreset.preservesUISettings {
            Logger.log("Preserving UI settings while selecting preset '\(preset.name)'", level: .debug)
            presetToApply = storedPreset.copy(
                
                // preserve these from current preset
                newSpeciesCount: selectedPreset.speciesCount,
                newParticleCount: selectedPreset.particleCount,
                newDistributionType: selectedPreset.distributionType,
                
                // preserve these from current UI
                newMaxDistance: settings.maxDistance.value,
                newMinDistance: settings.minDistance.value,
                newBeta: settings.beta.value,
                newFriction: settings.friction.value,
                newRepulsion: settings.repulsion.value,
                newPointSize: settings.pointSize.value,
                newWorldSize: settings.worldSize.value,
                newSpeciesColorOffset: settings.speciesColorOffset,
                newPaletteIndex: settings.paletteIndex,
                newColorEffectIndex: settings.colorEffectIndex
            )
        } else {
            Logger.log("Using all preset setttings while selecting preset '\(preset.name)'", level: .debug)
        }
        
        SimulationSettings.shared.selectedPreset = presetToApply
        SimulationSettings.shared.applyPreset(presetToApply)
        respawn(shouldGenerateNewMatrix: true)
    }
    
    func incrementSpeciesColorOffset() {
        SimulationSettings.shared.incrementSpeciesColorOffset()
        UserSettings.shared.set(SimulationSettings.shared.speciesColorOffset, forKey: UserSettingsKeys.speciesColorOffset)
        updateSpeciesColorsFromSettings()
    }
    
    func decrementSpeciesColorOffset() {
        SimulationSettings.shared.decrementSpeciesColorOffset()
        UserSettings.shared.set(SimulationSettings.shared.speciesColorOffset, forKey: UserSettingsKeys.speciesColorOffset)
        updateSpeciesColorsFromSettings()
    }
    
    func incrementPaletteIndex() {
        SimulationSettings.shared.incrementPaletteIndex()
        UserSettings.shared.set(SimulationSettings.shared.paletteIndex, forKey: UserSettingsKeys.colorPaletteIndex)
        updateSpeciesColorsFromSettings()
    }
    
    func decrementPaletteIndex() {
        SimulationSettings.shared.decrementPaletteIndex()
        UserSettings.shared.set(SimulationSettings.shared.paletteIndex, forKey: UserSettingsKeys.colorPaletteIndex)
        updateSpeciesColorsFromSettings()
    }
    
    func toggleColorEffect() {
        SimulationSettings.shared.toggleColorEffect()
        UserSettings.shared.set(SimulationSettings.shared.colorEffectIndex, forKey: UserSettingsKeys.colorEffectIndex)
    }
}

extension ParticleSystem {
    
    // create a preset from the selected preset AND the current state of simulation settings 
    var asPreset: SimulationPreset {
        let settings = SimulationSettings.shared
        let preset = settings.selectedPreset
        let matrixType = MatrixType.custom(matrix)

        return SimulationPreset(
            id: UUID(),
            name: preset.name,
            speciesCount: preset.speciesCount,
            particleCount: preset.particleCount,
            matrixType: matrixType,
            distributionType: preset.distributionType,
            maxDistance: settings.maxDistance.value,
            minDistance: settings.minDistance.value,
            beta: settings.beta.value,
            friction: settings.friction.value,
            repulsion: settings.repulsion.value,
            pointSize: settings.pointSize.value,
            worldSize: settings.worldSize.value,
            isBuiltIn: preset.isBuiltIn,
            preservesUISettings: preset.preservesUISettings,
            speciesColorOffset: settings.speciesColorOffset,
            paletteIndex: settings.paletteIndex,
            colorEffectIndex: settings.colorEffectIndex
        )
    }
}
