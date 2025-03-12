//
//  KeyEventRouter.swift
//  particlelife
//
//  Created by Rob Silverman on 3/6/25.
//

import Foundation
import Cocoa

class KeyEventRouter {
    
    private var zoomingIn = false
    private var zoomingOut = false
    private var panningLeft = false
    private var panningRight = false
    private var panningUp = false
    private var panningDown = false
    
    private var renderer: Renderer
    private var toggleSettingsPanelAction: () -> Void
    private var actionTimer: Timer?

    init(renderer: Renderer, toggleSettingsPanelAction: @escaping () -> Void) {
        self.renderer = renderer
        self.toggleSettingsPanelAction = toggleSettingsPanelAction
        
        actionTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateCamera), userInfo: nil, repeats: true)
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
    
    func handleMovementKey(_ event: NSEvent, isKeyDown: Bool) -> Bool {
        switch event.keyCode {
        case 24: zoomingIn = isKeyDown          // + key
        case 27: zoomingOut = isKeyDown         // - key
        case 123: panningLeft = isKeyDown       // Left arrow
        case 124: panningRight = isKeyDown      // Right arrow
        case 125: panningDown = isKeyDown       // Down arrow
        case 126: panningUp = isKeyDown         // Up arrow
        default: return false // Return false if key was not handled
        }
        return true // Return true if key was handled
    }
    
    func handleOtherKeyDown(with event: NSEvent) {
        
        // handle keys allowed while paused
        if event.keyCode == 49 { // Space bar
            renderer.togglePaused()
            return
        } else if event.keyCode == 48 { // Tab
            toggleSettingsPanelAction()
            return
        }
        
        // now bail if paused
        if renderer.isPaused {
            return
        }

        let isCommandDown = event.modifierFlags.contains(.command)
        let isShiftDown = event.modifierFlags.contains(.shift)
        let isOptionDown = event.modifierFlags.contains(.option)
        
        //Logger.log("Key pressed: \(event.keyCode)", level: .debug)
        switch event.keyCode {

        case 15: // R
            if isCommandDown {
                ParticleSystem.shared.respawn(shouldGenerateNewMatrix: false)
            } else if isOptionDown {
                ParticleSystem.shared.selectPreset(SimulationSettings.shared.selectedPreset)
            }
        case 1: // S
            if isCommandDown {
                NotificationCenter.default.post(name: .saveTriggered, object: nil)
            }
        case 45: // N
            if isCommandDown {
                ParticleSystem.shared.selectPreset(PresetDefinitions.emptyPreset)
            }
        case 44: // ?
            if isCommandDown {
                ParticleSystem.shared.selectPreset(PresetDefinitions.randomPreset)
            }
        case 33: // [
            ParticleSystem.shared.decrementPaletteIndex()
        case 30: // ]
            ParticleSystem.shared.incrementPaletteIndex()
        case 29: // Zero
            renderer.resetPanAndZoom()
        case 116: // page up
            ParticleSystem.shared.decrementSpeciesColorOffset()
        case 121: // page down
            ParticleSystem.shared.incrementSpeciesColorOffset()
        case 8: // C key
            ParticleSystem.shared.toggleColorEffect()
        case 2: // D key
            SimulationSettings.shared.nextDistributionType(direction: isShiftDown ? -1 : 1)
        case 35: // P key
            ParticleSystem.shared.selectRandomBuiltInPreset()
        case 46: // M key
            if SimulationSettings.shared.selectedPreset.matrixType.isRandom {
                ParticleSystem.shared.respawn(shouldGenerateNewMatrix: true)
            }
        default:
            return // Do NOT call super.keyDown(with: event) to prevent beep
        }
    }
    
    @objc private func updateCamera() {
        if zoomingIn {
            renderer.zoomIn()  // Small zoom step for smooth effect
        }
        if zoomingOut {
            renderer.zoomOut() // Small zoom step for smooth effect
        }
        if panningLeft {
            renderer.panLeft()  // Smooth panning left
        }
        if panningRight {
            renderer.panRight()  // Smooth panning right
        }
        if panningUp {
            renderer.panUp()  // Smooth panning up
        }
        if panningDown {
            renderer.panDown()  // Smooth panning down
        }
    }
}
