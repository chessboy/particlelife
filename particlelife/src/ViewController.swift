import Cocoa
import SwiftUI
import Metal
import MetalKit

class ViewController: NSViewController {
    var metalView: MTKView!
    var renderer: Renderer!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.makeFirstResponder(self)
        
        if let window = view.window {
            window.toggleFullScreen(nil)  // Make window fullscreen on launch
        }
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

        // Add the settings UI
        let settingsView = SimulationSettingsView(renderer: renderer)
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = CGRect(x: 20, y: 20, width: 320, height: 520)

        view.addSubview(hostingView)

        // Ensure Metal View Fills the Window Properly
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.locationInWindow
        let convertedLocation = metalView.convert(location, from: nil)
        //print("Raw Click Location: \(location), Converted: \(convertedLocation), View Size: \(metalView.frame.size)")
        renderer.handleMouseClick(at: convertedLocation, in: metalView)
    }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.characters == "r" {
            renderer.resetParticles()
            return
        }
        
        switch event.keyCode {
        case 49: // space bar
            renderer.isPaused.toggle()
        case 53: // esc
            renderer.resetPanAndZoom()
        case 24: // `+` key
            renderer.zoomIn()
        case 27: // `-` key
            renderer.zoomOut()
        case 123: // Left arrow
            renderer.panLeft()
        case 124: // Right arrow
            renderer.panRight()
        case 125: // Down arrow
            renderer.panDown()
        case 126: // Up arrow
            renderer.panUp()
        default:
            super.keyDown(with: event)
        }
        
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        metalView.frame = view.bounds  // Resize Metal view with the window
    }
}
