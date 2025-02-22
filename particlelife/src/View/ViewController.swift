import Cocoa
import SwiftUI
import Metal
import MetalKit

class ViewController: NSViewController {
    var metalView: MTKView!
    var renderer: Renderer!
    
    private var zoomingIn = false
    private var zoomingOut = false
    private var panningLeft = false
    private var panningRight = false
    private var panningUp = false
    private var panningDown = false
    private var actionTimer: Timer?

    var hostingView: NSHostingView<SimulationSettingsView>!

    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.makeFirstResponder(self)
        
        if let window = view.window {
            window.toggleFullScreen(nil)  // Make window fullscreen on launch
        }
        
        actionTimer = Timer.scheduledTimer(timeInterval: 0.016, target: self, selector: #selector(updateCamera), userInfo: nil, repeats: true)
        self.view.window?.makeFirstResponder(self)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let screen = NSScreen.main {
            let screenFrame = screen.frame  // Gets actual screen size
            print("Screen Size: \(screenFrame.size)")
            metalView = MTKView(frame: screenFrame, device: MTLCreateSystemDefaultDevice())
        } else {
            print("❌ Could not get screen size, falling back to view.bounds")
            metalView = MTKView(frame: view.bounds, device: MTLCreateSystemDefaultDevice())
        }
        
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        // Allow Metal View to resize dynamically
        metalView.autoresizingMask = [.width, .height]
        metalView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(metalView)
        
        renderer = Renderer(mtkView: metalView)

        addSettingsPanel()
        
        // Ensure Metal View Fills the Window Properly
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func addSettingsPanel() {
        let settingsView = SimulationSettingsView(renderer: renderer)
        let hostingView = NSHostingView(rootView: settingsView)

        // Let SwiftUI determine height
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(hostingView)

        // Constrain to desired width and let height be flexible
        NSLayoutConstraint.activate([
            hostingView.widthAnchor.constraint(equalToConstant: 320),
            hostingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10)
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
        case 53: // esc
            renderer.resetPanAndZoom()
        case 24: // `+` key (Start Zooming In)
            zoomingIn = true
            return
        case 27: // `-` key (Start Zooming Out)
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
        case 24: // `+` key (Stop Zooming In)
            zoomingIn = false
        case 27: // `-` key (Stop Zooming Out)
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
        case 24: // `+` key
            zoomingIn = isKeyDown
            return true
        case 27: // `-` key
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
    
    override func viewDidLayout() {
        super.viewDidLayout()
        metalView.frame = view.bounds  // Resize Metal view with the window
    }
}
