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
        
        // ✅ Create Metal view
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
        } else if event.keyCode == 49 {  // Space bar for pause
            isPaused.toggle()
            renderer.isPaused = isPaused
            //print("Simulation Paused: \(isPaused)")
        } else {
            super.keyDown(with: event)
        }
    }

    func resetSimulation() {
        print("Reinitializing simulation...")
        renderer.resetParticles()  // ✅ Calls Renderer to reset particles
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        metalView.frame = view.bounds  // Resize Metal view with the window
    }
}
