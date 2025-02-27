import Cocoa
import SwiftUI
import Metal
import MetalKit

class ViewController: NSViewController, NSWindowDelegate {
    var metalView: MTKView!
    var renderer: Renderer!
    
    private var zoomingIn = false
    private var zoomingOut = false
    private var panningLeft = false
    private var panningRight = false
    private var panningUp = false
    private var panningDown = false
    private var actionTimer: Timer?

    private var isResizing = false

    var hostingView: NSHostingView<SimulationSettingsView>!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let window = view.window {
            window.delegate = self
        }

        self.view.window?.makeFirstResponder(self)
        centerWindowIfNeeded()

        actionTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateCamera), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        actionTimer?.invalidate()
        actionTimer = nil
    }
    
    private var retryCount = 0
    private let maxRetries = 10
    
    func centerWindowIfNeeded() {
        guard let window = view.window, let screen = window.screen else {
            if retryCount < maxRetries {
                retryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.centerWindowIfNeeded() }
            }
            return
        }

        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let centeredOrigin = NSPoint(
            x: screenFrame.midX - windowSize.width / 2,
            y: screenFrame.midY - windowSize.height / 2
        )

        window.setFrameOrigin(centeredOrigin)
        Logger.log("Window centered on screen")
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

        DispatchQueue.main.async {
            if let window = self.view.window {
                self.constrainWindowAspectRatio()

                // Force the window size to be within constraints **before** manual resize
                let minHeight: CGFloat = 900
                let minWidth: CGFloat = minHeight * Constants.ASPECT_RATIO
                let correctedFrame = NSRect(x: window.frame.origin.x, y: window.frame.origin.y, width: max(window.frame.width, minWidth), height: max(window.frame.height, minHeight))
                
                window.setFrame(correctedFrame, display: true, animate: false)
            }
        }
        
        view.window?.isMovableByWindowBackground = false
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if isResizing {
            return frameSize // Let macOS complete its own resizing
        }
        return enforceAspectRatio(for: frameSize)
    }
    
    func windowWillStartLiveResize(_ notification: Notification) {
        isResizing = true
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        isResizing = false
        //Logger.log("Resize finished, enforcing strict aspect ratio.", level: .debug)
        
        DispatchQueue.main.async {
            self.constrainWindowAspectRatio()
        }
    }
        
    func enforceAspectRatio(for frameSize: NSSize) -> NSSize {
        let aspectRatio: CGFloat = Constants.ASPECT_RATIO
        let minAllowedHeight: CGFloat = 900
        let minAllowedWidth: CGFloat = minAllowedHeight * aspectRatio

        let newWidth = max(frameSize.height * aspectRatio, minAllowedWidth)
        let newHeight = max(frameSize.width / aspectRatio, minAllowedHeight)

        return NSSize(width: newWidth, height: newHeight)
    }
    
    func constrainWindowAspectRatio() {
        guard let window = view.window else { return }

        let aspectRatio: CGFloat = Constants.ASPECT_RATIO
        let titleBarHeight = window.frame.height - window.contentLayoutRect.height

        let minAllowedHeight: CGFloat = 900
        let minAllowedWidth: CGFloat = minAllowedHeight * aspectRatio

        window.aspectRatio = NSSize(width: aspectRatio, height: 1)
        window.minSize = NSSize(width: minAllowedWidth, height: minAllowedHeight + titleBarHeight)

        // Force constraints to take effect immediately
        if window.frame.width < minAllowedWidth || window.frame.height < minAllowedHeight {
            let correctedFrame = NSRect(
                x: window.frame.origin.x,
                y: window.frame.origin.y,
                width: max(window.frame.width, minAllowedWidth),
                height: max(window.frame.height, minAllowedHeight)
            )
            window.setFrame(correctedFrame, display: true, animate: false)
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
        if event.modifierFlags.contains(.command) && event.characters == "r" {
            renderer.respawnParticles()
            return
        }
        
        switch event.keyCode {
        case 49: // space bar
            renderer.isPaused.toggle()
        case 29: // zero
            renderer.resetPanAndZoom()
        case 24: // + key (Start Zooming In)
            zoomingIn = true
            return
        case 27: // - key (Start Zooming Out)
            zoomingOut = true
            return
        case 123: // Left arrow (Start Panning Left)
            panningLeft = true
            return
        case 124: // Right arrow (Start Panning Right)
            panningRight = true
            return
        case 125: // Down arrow (Start Panning Down)
            panningDown = true
            return
        case 126: // Up arrow (Start Panning Up)
            panningUp = true
            return
        default:
            super.keyDown(with: event)
        }
    }
    
    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 24: // + key (Stop Zooming In)
            zoomingIn = false
        case 27: // - key (Stop Zooming Out)
            zoomingOut = false
        case 123: // Left arrow (Stop Panning Left)
            panningLeft = false
        case 124: // Right arrow (Stop Panning Right)
            panningRight = false
        case 125: // Down arrow (Stop Panning Down)
            panningDown = false
        case 126: // Up arrow (Stop Panning Up)
            panningUp = false
        default:
            break
        }
    }

    private func handleZoomKeys(_ event: NSEvent, isKeyDown: Bool) -> Bool {
        switch event.keyCode {
        case 24: // + key
            zoomingIn = isKeyDown
            return true
        case 27: // - key
            zoomingOut = isKeyDown
            return true
        default:
            return false
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
