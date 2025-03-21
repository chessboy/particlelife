import Foundation
import Cocoa
import simd

class KeyEventRouter {
    
    private var zoomingIn = false
    private var zoomingOut = false
    private var panningLeft = false
    private var panningRight = false
    private var panningUp = false
    private var panningDown = false
    
    private let simulationManager: SimulationManager
    private let renderer: Renderer
    private let toggleSettingsPanelAction: () -> Void
    private var actionTimer: Timer?
    
    init(renderer: Renderer,
         simulationManager: SimulationManager,
         toggleSettingsPanelAction: @escaping () -> Void) {
        self.renderer = renderer
        self.simulationManager = simulationManager
        self.toggleSettingsPanelAction = toggleSettingsPanelAction
        
        // Run at roughly 60fps.
        actionTimer = Timer.scheduledTimer(timeInterval: 0.016,
                                           target: self,
                                           selector: #selector(updateCamera),
                                           userInfo: nil,
                                           repeats: true)
    }
    
    func stopListeningForEvents() {
        actionTimer?.invalidate()
        actionTimer = nil
    }
    
    func keyDown(with event: NSEvent) {
        if handleMovementKey(event, isKeyDown: true) {
            return
        }
        handleOtherKeyDown(with: event)
    }
    
    func keyUp(with event: NSEvent) {
        _ = handleMovementKey(event, isKeyDown: false)
    }
    
    @discardableResult
    func handleMovementKey(_ event: NSEvent, isKeyDown: Bool) -> Bool {
        switch event.keyCode {
        case 24: // + key
            zoomingIn = isKeyDown
        case 27: // - key
            zoomingOut = isKeyDown
        case 123: // Left arrow
            panningLeft = isKeyDown
        case 124: // Right arrow
            panningRight = isKeyDown
        case 125: // Down arrow
            panningDown = isKeyDown
        case 126: // Up arrow
            panningUp = isKeyDown
        case 29: // Zero key – reset pan/zoom
            if isKeyDown {
                simulationManager.resetPanAndZoom()
            }
        default:
            return false
        }
        return true
    }
    
    private func handleOtherKeyDown(with event: NSEvent) {
        // Keys that work even when paused.
        if event.keyCode == 49 { // Space bar toggles pause
            simulationManager.togglePaused()
            return
        } else if event.keyCode == 48 { // Tab toggles settings panel
            toggleSettingsPanelAction()
            return
        }
        
        // If paused, ignore other keys.
        if simulationManager.isPaused {
            return
        }
        
        let isCommandDown = event.modifierFlags.contains(.command)
        let isShiftDown = event.modifierFlags.contains(.shift)
        let isOptionDown = event.modifierFlags.contains(.option)
        
        switch event.keyCode {
        case 15: // R key
            if isCommandDown {
                ParticleSystem.shared.respawn(shouldGenerateNewMatrix: false)
            } else if isOptionDown {
                ParticleSystem.shared.selectPreset(SimulationSettings.shared.selectedPreset)
            }
        case 1: // S key
            if isCommandDown {
                NotificationCenter.default.post(name: .saveTriggered, object: nil)
            }
        case 45: // N key
            if isCommandDown {
                ParticleSystem.shared.selectPreset(PresetDefinitions.emptyPreset)
            }
        case 44: // ? key
            if isCommandDown {
                ParticleSystem.shared.selectPreset(PresetDefinitions.randomPreset)
            }
        case 33: // [ key
            ParticleSystem.shared.decrementPaletteIndex()
        case 30: // ] key
            ParticleSystem.shared.incrementPaletteIndex()
        case 116: // Page Up
            ParticleSystem.shared.decrementSpeciesColorOffset()
        case 121: // Page Down
            ParticleSystem.shared.incrementSpeciesColorOffset()
        case 8: // C key
            ParticleSystem.shared.nextColorEffect(direction: isShiftDown ? -1 : 1)
        case 2: // D key
            SimulationSettings.shared.nextDistributionType(direction: isShiftDown ? -1 : 1)
        case 35: // P key
            ParticleSystem.shared.selectRandomBuiltInPreset()
        case 46: // M key
            if SimulationSettings.shared.selectedPreset.matrixType.isRandom {
                ParticleSystem.shared.respawn(shouldGenerateNewMatrix: true)
            }
        default:
            break
        }
    }
    
    @objc private func updateCamera() {
        if zoomingIn {
            simulationManager.zoomIn(step: 1.01)
        }
        if zoomingOut {
            simulationManager.zoomOut(step: 1.01)
        }
        if panningLeft {
            simulationManager.pan(by: simd_float2(-0.01 / simulationManager.zoomLevel, 0))
        }
        if panningRight {
            simulationManager.pan(by: simd_float2(0.01 / simulationManager.zoomLevel, 0))
        }
        if panningUp {
            simulationManager.pan(by: simd_float2(0, 0.01 / simulationManager.zoomLevel))
        }
        if panningDown {
            simulationManager.pan(by: simd_float2(0, -0.01 / simulationManager.zoomLevel))
        }
    }
}
