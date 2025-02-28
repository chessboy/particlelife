//
//  ViewController.swift
//  particlelife
//
//  Created by Rob Silverman on 2/24/25.
//

import Cocoa
import SwiftUI
import Metal
import MetalKit

class ViewController: NSViewController  {
    private var metalView: MTKView!
    private var renderer: Renderer!
    private var actionTimer: Timer?
    private var hostingView: NSHostingView<SimulationSettingsView>!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.makeFirstResponder(self)
        centerWindowIfNeeded()
        enforceWindowSizeConstraints()

        NotificationCenter.default.addObserver(self, selector: #selector(didExitFullScreen), name: NSWindow.didExitFullScreenNotification, object: nil)
        actionTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateCamera), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        actionTimer?.invalidate()
        actionTimer = nil
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.autoresizingMask = [.width, .height]
        metalView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metalView)
        
        renderer = Renderer(mtkView: metalView)
        addSettingsPanel()
        
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
                
        view.window?.isMovableByWindowBackground = false
    }
           
    func centerWindowIfNeeded() {
        guard let window = view.window, let screen = window.screen else { return }

        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let centeredOrigin = NSPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2
        )

        window.setFrameOrigin(centeredOrigin)
        Logger.log("Window centered on screen: windowSize: \(windowSize), screenFrame: \(screenFrame)", level: .debug)
    }

    private func enforceWindowSizeConstraints() {
        guard let window = view.window else { return }

        let aspectRatio: CGFloat = Constants.ASPECT_RATIO
        let minContentHeight: CGFloat = 900
        let minContentWidth: CGFloat = round(minContentHeight * aspectRatio)

        let titleBarHeight = window.frame.height - window.contentLayoutRect.height
        let minWindowHeight = minContentHeight + titleBarHeight
        let minWindowWidth = minContentWidth

        // These two lines do ALL the work!
        window.aspectRatio = NSSize(width: aspectRatio, height: 1)
        window.minSize = NSSize(width: minWindowWidth, height: minWindowHeight)

        Logger.log("window size: \(window.frame.size) | content size: \(window.contentLayoutRect.size) | titleBarHeight: \(titleBarHeight)", level: .debug)
    }
    
    // Reapply aspect ratio when exiting full screen
    @objc private func didExitFullScreen() {
        DispatchQueue.main.async {
            self.enforceWindowSizeConstraints()
        }
    }
    
    func addSettingsPanel() {
        let settingsView = SimulationSettingsView(renderer: renderer)
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        
        // Constrain to desired width and let height be flexible
        NSLayoutConstraint.activate([
            hostingView.widthAnchor.constraint(equalToConstant: 340),
            hostingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -2)
        ])
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

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.characters == "r" {
            renderer.respawnParticles()
            return
        }
        
        if handleMovementKey(event, isKeyDown: true) {
            return // Suppress system beep by returning early
        }
        
        switch event.keyCode {
        case 49: // Space bar
            renderer.isPaused.toggle()
        case 29: // Zero
            renderer.resetPanAndZoom()
        default:
            return // Do NOT call super.keyDown(with: event) to prevent beep
        }
    }

    override func keyUp(with event: NSEvent) {
        if handleMovementKey(event, isKeyDown: false) {
            return // Suppress system beep by returning early
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
