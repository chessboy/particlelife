//
//  ViewController.swift
//  particlelife
//
//  Created by Rob Silverman on 2/24/25.
//

import Cocoa
import SwiftUI
import MetalKit

class ViewController: NSViewController {
    private var metalView: MTKView!
    private var renderer: Renderer!
    private var actionTimer: Timer?
    private var fpsMonitor = FPSMonitor()

    private var settingsButton: NSHostingView<SettingsButtonView>?
    private var settingsButtonFadeTimer: Timer?
    private var settingsPanel: NSHostingView<SimulationSettingsView>!

    override func viewWillAppear() {
        super.viewWillAppear()
    
        setupMetalView()

        self.view.window?.makeFirstResponder(self)
        setupSettingsButton()
        setupSettingsPanel()
        showSettingsPanel()
        setupMouseTracking()

        centerWindow()
        enforceWindowSizeConstraints()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterFullScreen), name: NSWindow.didEnterFullScreenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didExitFullScreen), name: NSWindow.didExitFullScreenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideSettingsPanel), name: .closeSettingsPanel, object: nil)
        actionTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateCamera), userInfo: nil, repeats: true)
        
        if UserSettings.shared.bool(forKey: UserSettingsKeys.startupInFullScreen, defaultValue: true), let window = view.window {
            window.toggleFullScreen(nil)  // Make window fullscreen on launch
        }
    }
    
    override func viewDidAppear() {
        fpsMonitor.startMonitoring()
    }
        
    override func viewWillDisappear() {
        super.viewWillDisappear()
        fpsMonitor.stopMonitoring()
        actionTimer?.invalidate()
        actionTimer = nil
    }
        
    private func setupMetalView() {
        metalView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.autoresizingMask = [.width, .height]
        metalView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metalView)

        renderer = Renderer(metalView: metalView, fpsMonitor: fpsMonitor)

        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func centerWindow() {
        guard let window = view.window, let screen = window.screen else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let centeredOrigin = NSPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2
        )
        
        window.setFrameOrigin(centeredOrigin)
        Logger.log("Window centered on screen: windowSize: \(windowSize), screenFrame: \(screenFrame), origin: \(centeredOrigin)", level: .debug)
    }
    
    private func enforceWindowSizeConstraints() {
        guard let window = view.window else { return }
        
        let aspectRatio: CGFloat = Constants.ASPECT_RATIO
        let minContentHeight: CGFloat = 940
        let minContentWidth: CGFloat = round(minContentHeight * aspectRatio)
        
        let titleBarHeight = window.frame.height - window.contentLayoutRect.height
        let minWindowHeight = minContentHeight + titleBarHeight
        let minWindowWidth = minContentWidth
        
        // These two lines do ALL the work!
        window.aspectRatio = NSSize(width: aspectRatio, height: 1)
        window.minSize = NSSize(width: minWindowWidth, height: minWindowHeight)
        
        Logger.log("window size: \(window.frame.size) | content size: \(window.contentLayoutRect.size) | titleBarHeight: \(titleBarHeight)", level: .debug)
    }
    
    @objc private func didEnterFullScreen() {
        if !UserSettings.shared.bool(forKey: UserSettingsKeys.startupInFullScreen) {
            UserSettings.shared.set(true, forKey: UserSettingsKeys.startupInFullScreen)
        }
    }
    
    // Reapply aspect ratio when exiting full screen
    @objc private func didExitFullScreen() {
        DispatchQueue.main.async {
            self.enforceWindowSizeConstraints()
        }
        UserSettings.shared.set(false, forKey: UserSettingsKeys.startupInFullScreen)
    }
}

private var settingsButtonYConstraint: NSLayoutConstraint?
private var initialSettingsButtonY: CGFloat?  // Store first Y entry, clear after hiding

private let settingsButtonWidth: CGFloat = 120
private let settingsButtonLeftOffset: CGFloat = 40
private let settingsPanelWidth: CGFloat = 340
private let triggerZoneX: CGFloat = 200
private let settingsButtonHeight: CGFloat = 44

// handling of settings panel
extension ViewController {
    
    private func setupMouseTracking() {
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
            self.handleMouseMove(event: event)
            return event
        }
    }
    
    private func handleMouseMove(event: NSEvent) {
        guard settingsPanel.isHidden else { return }
        
        let mouseX = event.locationInWindow.x
        let mouseY = event.locationInWindow.y
        
        if mouseX < triggerZoneX {
            if settingsButton?.isHidden ?? true {
                let detectedY = initialSettingsButtonY ?? computeInitialY(from: mouseY)
                showSettingsButton(at: detectedY)
            }
        } else {
            hideSettingsButton()
        }
    }
        
    private func setupSettingsButton() {
        let settingsButtonView = SettingsButtonView(action: toggleSettingsPanel)
        let hostingView = NSHostingView(rootView: settingsButtonView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.alphaValue = 0.0 // Start hidden
        
        view.addSubview(hostingView)
        settingsButton = hostingView
        
        if let settingsButton = settingsButton {
            
            NSLayoutConstraint.activate([
                settingsButton.widthAnchor.constraint(equalToConstant: settingsButtonWidth), // Adjust as needed
                settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: settingsButtonLeftOffset) // Slight offset from the edge
            ])
        }
    }
    
    private func setupSettingsPanel() {
        let settingsView = SimulationSettingsView(renderer: renderer)
        
        settingsPanel = NSHostingView(rootView: settingsView)
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.isHidden = false
        
        view.addSubview(settingsPanel)
        
        NSLayoutConstraint.activate([
            settingsPanel.widthAnchor.constraint(equalToConstant: settingsPanelWidth),
            settingsPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -2)
        ])
    }
    
    @objc private func toggleSettingsPanel() {
        if settingsPanel.isHidden {
            showSettingsPanel()
        } else {
            hideSettingsPanel()
        }
    }
    
    func showSettingsPanel() {
        guard settingsPanel.isHidden else { return }
        
        settingsPanel.isHidden = false
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            settingsPanel.animator().alphaValue = 1.0
        } completionHandler: {
            self.hideSettingsButton() // Hide button when panel is open
        }
    }
    
    @objc func hideSettingsPanel() {
        guard !settingsPanel.isHidden else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            settingsPanel.animator().alphaValue = 0.0
        } completionHandler: {
            self.settingsPanel.isHidden = true
        }
    }
    
    private func showSettingsButton(at mouseY: CGFloat) {
        guard let settingsButton = settingsButton else { return }

        settingsButton.isHidden = false
        settingsButton.alphaValue = 0.0

        // Ensure we store Y **only once**
        if initialSettingsButtonY == nil {
            initialSettingsButtonY = mouseY
        }

        // Invert Y relative to screen height
        let storedY = initialSettingsButtonY ?? view.bounds.height / 2
        let invertedY = view.bounds.height - storedY

        var clampedY = computeInitialY(from: invertedY)
        // nudge it down a bit so the cursor is in a good spot
        clampedY -= 40

        if let existingConstraint = settingsButtonYConstraint {
            view.removeConstraint(existingConstraint)
        }

        let newYConstraint = settingsButton.topAnchor.constraint(equalTo: view.topAnchor, constant: clampedY)
        settingsButtonYConstraint = newYConstraint

        NSLayoutConstraint.activate([
            settingsButton.widthAnchor.constraint(equalToConstant: settingsButtonWidth),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: settingsButtonLeftOffset),
            newYConstraint
        ])

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            settingsButton.animator().alphaValue = 1.0
        }
    }
    
    // Computes Initial Y Position for settings button
    private func computeInitialY(from mouseY: CGFloat) -> CGFloat {
        guard let window = view.window else { return view.bounds.height / 2 }
        return max(settingsButtonHeight, min(window.frame.height - mouseY, view.bounds.height))
    }

    private func hideSettingsButton() {
        initialSettingsButtonY = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            settingsButton?.animator().alphaValue = 0.0
        } completionHandler: {
            self.settingsButton?.isHidden = true
        }
    }
}

private var zoomingIn = false
private var zoomingOut = false
private var panningLeft = false
private var panningRight = false
private var panningUp = false
private var panningDown = false

extension ViewController {

    override var acceptsFirstResponder: Bool { true }
    
    override func mouseDown(with event: NSEvent) {
        handleMouseEvent(event, isRightClick: false)
    }

    override func rightMouseDown(with event: NSEvent) {
        handleMouseEvent(event, isRightClick: true)
    }

    private func handleMouseEvent(_ event: NSEvent, isRightClick: Bool) {
        let location = event.locationInWindow
        let convertedLocation = metalView.convert(location, from: nil)
        renderer.handleMouseClick(at: convertedLocation, in: metalView, isRightClick: isRightClick)
    }
    
    override func keyDown(with event: NSEvent) {
        if handleMovementKey(event, isKeyDown: true) { return }
        if handleCommandKey(event) { return }
        handleOtherKeyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        _ = handleMovementKey(event, isKeyDown: false)
    }

    private func handleMovementKey(_ event: NSEvent, isKeyDown: Bool) -> Bool {
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

    private func handleCommandKey(_ event: NSEvent) -> Bool {
        // ⌘R Respawn
        if event.modifierFlags.contains(.command) && event.characters == "r" {
            renderer.respawnParticles()
            return true
        }
        
        // ⌘S Save the current settings to a preset
        if event.modifierFlags.contains(.command) && event.characters == "s" {
            NotificationCenter.default.post(name: .saveTriggered, object: nil)
            return true
        }
        
        // ⌘N New preset
        if event.modifierFlags.contains(.command) && event.characters == "n" {
            ParticleSystem.shared.selectPreset(PresetDefinitions.emptyPreset)
           return true
        }
        
        // ⌘/ (? key) New random-mode preset
        if event.modifierFlags.contains(.command) && event.characters == "/" {
            ParticleSystem.shared.selectPreset(PresetDefinitions.randomPreset)
            return true
        }
        
        return false
    }
    
    func handleOtherKeyDown(with event: NSEvent) {
        
        switch event.keyCode {
        case 48: // Tab
            toggleSettingsPanel()
        case 49: // Space bar
            renderer.isPaused.toggle()
        case 29: // Zero
            renderer.resetPanAndZoom()
        case 116: // page up
            ParticleSystem.shared.decrementSpeciesColorOffset()
        case 121: // page down
            ParticleSystem.shared.incrementSpeciesColorOffset()
        case 17: // T key
            SimulationSettings.shared.toggleColorEffect()
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
