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
    
    private let minWindowHeight: CGFloat = 940
    
    private var metalView: MTKView!
    private var renderer: Renderer!
    private var fpsMonitor = FPSMonitor()
    private var keyEventRouter: KeyEventRouter?
    private var didShowSplash = false

    private var settingsButton: NSHostingView<SettingsButtonView>?
    private var settingsButtonFadeTimer: Timer?
    private var settingsPanel: NSHostingView<SimulationSettingsView>!
    private var splashScreen: NSHostingView<SplashScreenView>!

    private let startupInFullScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetalView()
        setupSettingsButton()
        setupSettingsPanel()
        setupSplashScreen()
        setupMouseTracking()
        setupKeyboardTracking()
        setupNotifications()
    }
        
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterFullScreen), name: NSWindow.didEnterFullScreenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didExitFullScreen), name: NSWindow.didExitFullScreenNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideSettingsPanel), name: .closeSettingsPanel, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkLowPerformanceWarning), name: .lowPerformanceWarning, object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard let window = view.window else { return }

        let adjustedAspectRatio = 2.16667
        window.aspectRatio = NSSize(width: adjustedAspectRatio, height: 1)
        window.minSize = NSSize(width: adjustedAspectRatio * minWindowHeight, height: minWindowHeight)

        window.makeFirstResponder(self)
        window.backgroundColor = NSColor(white: 0.07, alpha: 1)

        centerWindow()
        self.enforceWindowSizeConstraints()
        
        if startupInFullScreen {
            window.alphaValue = 0.0
            DispatchQueue.main.async {
                window.toggleFullScreen(nil)
                window.alphaValue = 1.0
            }
        }

        // Delay settings panel appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showSettingsPanel()
        }
    }
        
    override func viewDidAppear() {
        fpsMonitor.startMonitoring()
    }
        
    override func viewWillDisappear() {
        super.viewWillDisappear()
        fpsMonitor.stopMonitoring()
        keyEventRouter?.stopListeningForEvents()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        enforceWindowSizeConstraints()
    }
}

// MARK: Window Management

extension ViewController {
    
    func centerWindow() {
        guard let window = view.window, let screen = window.screen else { return }

        let screenFrame = screen.frame
        let windowSize = window.frame.size
        let centerX = (screenFrame.width - windowSize.width) / 2
        let centerY = (screenFrame.height - windowSize.height) / 2
        window.setFrameOrigin(NSPoint(x: centerX, y: centerY))
    }
    
    func enforceWindowSizeConstraints() {
        guard let window = view.window else {
            Logger.log("⚠️ No window available, skipping enforceWindowSizeConstraints()", level: .error)
            return
        }

        let settingsPanelWidth: CGFloat = 340  // Space for the settings panel
        let aspectRatio: CGFloat = 1.7778  // Metal view should always maintain this AR
        let contentWidth = window.contentLayoutRect.width - settingsPanelWidth
        let contentHeight = window.contentLayoutRect.height

        // Factor in the title bar height
        let titleBarHeight = window.frame.height - contentHeight

        // Ensure metal view behavior is **consistent with fullscreen**
        let targetWidth = contentWidth
        let targetHeight = targetWidth / aspectRatio

        var adjustedWidth: CGFloat
        var adjustedHeight: CGFloat
        var metalViewX: CGFloat
        var metalViewY: CGFloat

        if targetHeight > contentHeight {
            // If too tall, **force FSM-like behavior**: fill width, letterbox top/bottom
            adjustedWidth = contentWidth
            adjustedHeight = adjustedWidth / aspectRatio
            metalViewX = settingsPanelWidth
            metalViewY = (contentHeight - adjustedHeight) / 2  // Center vertically
        } else {
            // Fill width first, force letterboxing on top/bottom
            adjustedWidth = targetWidth
            adjustedHeight = targetHeight
            metalViewX = settingsPanelWidth
            metalViewY = (contentHeight - targetHeight) / 2  // Keep it centered
        }

        // Apply new frame to Metal View
        metalView.frame = CGRect(x: metalViewX, y: metalViewY, width: adjustedWidth, height: adjustedHeight)

        // 🛠 LOGGING: Confirm fix
        Logger.log("✅ FSM-matching enforced | MetalView Frame: \(metalView.frame)", level: .debug)
    }
    
    @objc private func didEnterFullScreen() {
        if !didShowSplash {
            didShowSplash = true
        }
    }
    
    // Reapply aspect ratio when exiting full screen
    @objc private func didExitFullScreen() {
        self.enforceWindowSizeConstraints()
    }
    
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        
        DispatchQueue.main.async {
            alert.runModal()
        }
    }
}

private let settingsButtonWidth: CGFloat = 120
private let settingsButtonLeftOffset: CGFloat = 100
private let settingsPanelWidth: CGFloat = 340
private let triggerZoneX: CGFloat = 300
private let settingsButtonHeight: CGFloat = 44

private var settingsButtonYConstraint: NSLayoutConstraint?
private var initialSettingsButtonY: CGFloat?

// MARL: Metal View

extension ViewController {
    
    private func setupMetalView() {
        metalView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.autoresizingMask = []
        metalView.translatesAutoresizingMaskIntoConstraints = true
        
        view.addSubview(metalView)

        renderer = Renderer(metalView: metalView, fpsMonitor: fpsMonitor)
    }
    
    @objc private func checkLowPerformanceWarning() {
        if let warning = SystemCapabilities.shared.performanceWarning() {
            self.showAlert(title: warning.title, message: warning.message)
        }
    }
}

// MARK: Settings Panel

extension ViewController {
    
    private func setupSettingsPanel() {
        let settingsView = SimulationSettingsView(renderer: renderer)
        
        settingsPanel = NSHostingView(rootView: settingsView)
        settingsPanel.translatesAutoresizingMaskIntoConstraints = false
        settingsPanel.isHidden = true
        settingsPanel.alphaValue = 0.0  // Start at 0 so first-time animation works
        
        view.addSubview(settingsPanel)
        
        NSLayoutConstraint.activate([
            settingsPanel.widthAnchor.constraint(equalToConstant: settingsPanelWidth),
            settingsPanel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingsPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -2)
        ])
    }
    
    private func toggleSettingsPanel() {
        if settingsPanel.isHidden {
            showSettingsPanel()
        } else {
            hideSettingsPanel()
        }
    }
    
    func showSettingsPanel() {
        guard settingsPanel.isHidden else { return }
        
        settingsPanel.isHidden = false
        settingsPanel.alphaValue = 0.0  // Ensure it starts fully transparent
        
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
}

// MARK Settings Button

extension ViewController {
            
    private func setupSettingsButton() {
        let settingsButtonView = SettingsButtonView(action: { self.toggleSettingsPanel() })
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


// MARK: Event Handling

extension ViewController {
    
    override var acceptsFirstResponder: Bool { true }
    
    // MARK: Mouse Events
    
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
    
    // MARK: Key Events
    
    private func setupKeyboardTracking() {
        keyEventRouter = KeyEventRouter(renderer: renderer, toggleSettingsPanelAction: { self.toggleSettingsPanel() })
    }

    override func keyDown(with event: NSEvent) {
        guard let keyEventRouter = keyEventRouter else { return }
        if keyEventRouter.handleMovementKey(event, isKeyDown: true) {
            return
        }
        keyEventRouter.handleOtherKeyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        guard let keyEventRouter = keyEventRouter else { return }
        _ = keyEventRouter.handleMovementKey(event, isKeyDown: false)
    }
}

// MARK: Splash Screen

extension ViewController {
    
    private func setupSplashScreen() {
        
        let spashView = SplashScreenView(onDismiss: {
            self.removeSplashScreen()
        })
        
        splashScreen = NSHostingView(rootView: spashView)
        
        splashScreen.translatesAutoresizingMaskIntoConstraints = false
        splashScreen.alphaValue = 1.0 // Ensure it starts fully visible
        view.addSubview(splashScreen)
        
        NSLayoutConstraint.activate([
            splashScreen.topAnchor.constraint(equalTo: view.topAnchor),
            splashScreen.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            splashScreen.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splashScreen.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func removeSplashScreen() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 1.0
            splashScreen.animator().alphaValue = 0.0
        } completionHandler: {
            self.splashScreen.removeFromSuperview()
            self.splashScreen = nil
        }
    }
}
