import Cocoa
import Metal
import MetalKit

class ViewController: NSViewController {
    var metalView: MTKView!
    var renderer: Renderer!

    override func viewWillAppear() {
        super.viewWillAppear()

        if let window = view.window {
            window.toggleFullScreen(nil)  // Make window fullscreen on launch
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Use Storyboard's view as the Metal view
        metalView = MTKView(frame: view.bounds, device: MTLCreateSystemDefaultDevice())
        metalView.autoresizingMask = [.width, .height]  // Ensures it resizes automatically
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        view.addSubview(metalView) // Attach Metal view to the main view

        renderer = Renderer(mtkView: metalView)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        metalView.frame = view.bounds  // Resize Metal view with the window
    }
}
