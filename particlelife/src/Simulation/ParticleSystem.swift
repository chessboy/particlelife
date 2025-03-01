//
//  ParticleSystem.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Metal
import simd
import SwiftUI
import Combine

class ParticleSystem: ObservableObject {
    static let shared = ParticleSystem()
    
    private var particles: [Particle] = []
    
    @Published var matrix: [[Float]] = []
    @Published private(set) var speciesColors: [Color] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdateTime: TimeInterval = Date().timeIntervalSince1970
    private var lastDT: Float = 0.001
    
    init() {
        let defaultPreset = PresetDefinitions.getDefaultPreset()
        
        SimulationSettings.shared.applyPreset(defaultPreset)
        generateParticles(preset: defaultPreset)
        generateNewMatrix(preset: defaultPreset, speciesColorOffset: defaultPreset.speciesColorOffset, paletteIndex: 0)
        updatePhysicsAndBuffers(preset: defaultPreset)
        
        // listen for changes when a preset is applied
        NotificationCenter.default.addObserver(self, selector: #selector(presetApplied), name: Notification.Name.presetSelected, object: nil)
    }
    
    /// Called when a preset is applied
    @objc private func presetApplied() {
        Logger.log("Preset applied - updating Particle System with respawn")
        respawn(shouldGenerateNewMatrix: true)
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
            generateNewMatrix(preset: preset, speciesColorOffset: SimulationSettings.shared.speciesColorOffset, paletteIndex: SimulationSettings.shared.paletteIndex)
        }
        updatePhysicsAndBuffers(preset: preset)
    }
    
    func speciesCountWillChange(newCount: Int) {
        let settings = SimulationSettings.shared
        
        guard newCount != settings.selectedPreset.speciesCount else {
            Logger.log("No change needed, speciesCount is already \(settings.selectedPreset.speciesCount)", level: .debug)
            return
        }
        
        let newPreset = settings.selectedPreset.copy(newSpeciesCount: newCount)
        
        generateNewMatrix(preset: newPreset, speciesColorOffset: SimulationSettings.shared.speciesColorOffset, paletteIndex: SimulationSettings.shared.paletteIndex)
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
        
        Logger.log("generateParticles: speciesCount: \(preset.speciesCount), particleCount: \(preset.particleCount), matrixType: \(preset.matrixType)")
        
        particles = ParticleGenerator.generate(
            distribution: preset.distributionType,
            particleCount: preset.particleCount,
            speciesCount: preset.speciesCount
        )
        
        //let uniqueSpecies = Set(particles.map { $0.species })
        //Logger.log("Unique species in new particles: \(uniqueSpecies)", level: .debug)
        
        let worldSize = SimulationSettings.shared.worldSize.value
        let scaleFactorX = preset.distributionType.shouldScaleToAspectRatio ? worldSize * Float(Constants.ASPECT_RATIO) : worldSize
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
    }
    
    /// Generates a new matrix and updates colors using species color offset
    private func generateNewMatrix(preset: SimulationPreset, speciesColorOffset: Int, paletteIndex: Int) {
        matrix = MatrixGenerator.generateMatrix(speciesCount: preset.speciesCount, type: preset.matrixType)
        generateSpeciesColors(speciesCount: preset.speciesCount, speciesColorOffset: speciesColorOffset, paletteIndex: paletteIndex)
    }
    
    /// Generates colors for each species based on the selected palette
    private func generateSpeciesColors(speciesCount: Int, speciesColorOffset: Int, paletteIndex: Int) {
        Logger.log("updateSpeciesColors: speciesCount: \(speciesCount), speciesColorOffset: \(speciesColorOffset), paletteIndex: \(paletteIndex)", level: .debug)
        
        DispatchQueue.main.async {
            guard let selectedPalette = SpeciesPalette(rawValue: paletteIndex) else { return }
            let predefinedColors = selectedPalette.colors // Get colors directly from the enum
            
            self.speciesColors = (0..<speciesCount).map { predefinedColors[($0 + speciesColorOffset) % predefinedColors.count] }
            self.objectWillChange.send()
        }
    }
    
    func updateSpeciesColors(speciesCount: Int, speciesColorOffset: Int, paletteIndex: Int) {
        generateSpeciesColors(speciesCount: speciesCount, speciesColorOffset: speciesColorOffset, paletteIndex: paletteIndex)
    }
    
    func dumpPresetAsCode() {
        print(SimulationSettings.shared.selectedPreset.asCode)
    }
    
    /// Updates delta time for particle movement
    func update() {
        let currentTime = Date().timeIntervalSince1970
        var dt = Float(currentTime - lastUpdateTime)
        dt = max(0.0001, min(dt, 0.01)) // Clamp dt
        
        let smoothingFactor: Float = 0.05
        dt = (1.0 - smoothingFactor) * lastDT + smoothingFactor * dt
        
        // Snap dt to avoid micro jitter
        let quantizationStep: Float = 0.0005
        dt = round(dt / quantizationStep) * quantizationStep
        
        if abs(dt - lastDT) > 0.00005 {
            BufferManager.shared.updateDeltaTimeBuffer(dt: &dt)  // Send RAW dt (not dtFactor!)
            lastDT = dt
        }
        
        lastUpdateTime = currentTime
    }
}

extension ParticleSystem {
    
    func selectPreset(_ preset: SimulationPreset) {
        
        let settings = SimulationSettings.shared
        let selectedPreset = settings.selectedPreset
        
        Logger.log("Attempting to select preset '\(preset.name)' (ID: \(preset.id))", level: .debug)
        
        let userPresets = UserPresetStorage.loadUserPresets()
        let allPresets = PresetDefinitions.getAllBuiltInPresets() + userPresets
        //let availablePresets = allPresets.map { "\($0.name) (ID: \($0.id))" }
        //Logger.log("Available presets: \n\(availablePresets.joined(separator: "\n"))", level: .debug)
        
        guard let storedPreset = allPresets.first(where: { $0.id == preset.id }) else {
            Logger.log("ERROR: Preset '\(preset.name)' (ID: \(preset.id)) not found in storage!", level: .error)
            return
        }
        
        Logger.log("Preset '\(preset.name)' found. Selecting it now.", level: .debug)
        
        var presetToApply = storedPreset
        
        if storedPreset.preservesUISettings {
            Logger.log("Preserving UI settings while selecting preset '\(preset.name)'", level: .debug)
            presetToApply = storedPreset.copy(
                newSpeciesCount: selectedPreset.speciesCount,
                newParticleCount: selectedPreset.particleCount,
                newDistributionType: selectedPreset.distributionType,
                newSpeciesColorOffset: settings.speciesColorOffset,
                newPaletteIndex: settings.paletteIndex
            )
        } else {
            Logger.log("Using all preset setttings while selecting preset '\(preset.name)'", level: .debug)
        }
        
        SimulationSettings.shared.selectedPreset = presetToApply
        SimulationSettings.shared.applyPreset(presetToApply)
        
        NotificationCenter.default.post(name: .presetSelected, object: nil)
    }
}
