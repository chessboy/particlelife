import Cocoa
import SwiftUI
import Metal
import MetalKit

class ViewController: NSViewController {
    var metalView: MTKView!
    var renderer: Renderer!
    var isPaused = false
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.makeFirstResponder(self)
        
        if let window = view.window {
            window.toggleFullScreen(nil)  // Make window fullscreen on launch
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalView = MTKView(frame: view.bounds, device: MTLCreateSystemDefaultDevice())
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.addSubview(metalView)
        
        renderer = Renderer(mtkView: metalView)
        
        let settingsView = SimulationSettingsView(renderer: renderer)
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.frame = CGRect(x: 20, y: 20, width: 300, height: 200)  // Adjust as needed
        view.addSubview(hostingView)
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.characters == "r" {
            resetSimulation()
            return
        }
        
        switch event.keyCode {
        case 49: // space bar
            isPaused.toggle()
            renderer.isPaused = isPaused
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
    
    func resetSimulation() {
        renderer.resetParticles()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        metalView.frame = view.bounds  // Resize Metal view with the window
    }
}
