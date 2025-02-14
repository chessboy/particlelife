import Cocoa
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

        self.view.window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 {
            isPaused.toggle()
            renderer.isPaused = isPaused
        } else {
            super.keyDown(with: event)  // Pass unhandled keys to default behavior
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        metalView.frame = view.bounds  // Resize Metal view with the window
    }
}
