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
    private var simulationManager: SimulationManager?
    private var keyEventRouter: KeyEventRouter?
    private var fpsMonitor: FPSMonitor?
    private var didShowSplash = false

    private var settingsButton: NSHostingView<SettingsButtonView>?
    private var settingsButtonFadeTimer: Timer?
    private var settingsPanel: NSHostingView<SimulationSettingsView>!
    private var splashScreen: NSHostingView<SplashScreenView>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FeatureFlags.configure()
        
        simulationManager = SimulationManager()
        fpsMonitor = FPSMonitor()
        
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

        if FeatureFlags.windowAspectRatioUnlocked.isOff {
            window.aspectRatio = NSSize(width: ASPECT_RATIO, height: 1)
        }
        
        window.minSize = NSSize(width: ASPECT_RATIO * windowMinHeight, height: windowMinHeight)

        window.makeFirstResponder(self) // Ensure proper input focus
        window.backgroundColor = .black

        centerWindow()
        enforceWindowSizeConstraints()

        if FeatureFlags.noStartupInFullScreen.isOff {
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
        fpsMonitor?.startMonitoring()
    }
        
    override func viewWillDisappear() {
        super.viewWillDisappear()
        fpsMonitor?.stopMonitoring()
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
        let aspectRatio: CGFloat = ASPECT_RATIO
        let percentage: CGFloat = 0.75
        
        // Calculate window size based on % width first
        var targetWidth = screenFrame.width * percentage
        var targetHeight = targetWidth / aspectRatio

        // If the calculated height is too tall for a portrait screen, adjust it
        if targetHeight > screenFrame.height * percentage {
            targetHeight = screenFrame.height * percentage
            targetWidth = targetHeight * aspectRatio  // Recalculate width based on height
        }

        let windowSize = NSSize(width: targetWidth, height: targetHeight)

        let centerX = (screenFrame.width - windowSize.width) / 2
        let centerY = (screenFrame.height - windowSize.height) / 2

        window.setFrame(NSRect(x: centerX, y: centerY, width: windowSize.width, height: windowSize.height), display: true, animate: true)
    }

    func enforceWindowSizeConstraints() {
        guard let window = view.window else { return }

        let aspectRatio: CGFloat = ASPECT_RATIO
        let contentWidth = window.contentLayoutRect.width
        let contentHeight = window.contentLayoutRect.height

        // Factor in the title bar height
        let titleBarHeight = window.frame.height - contentHeight
        let adjustedContentHeight = contentHeight + titleBarHeight

        let targetWidth = contentWidth
        let targetHeight = targetWidth / aspectRatio

        if targetHeight > adjustedContentHeight {
            // Too tall, adjust width instead
            let adjustedHeight = adjustedContentHeight
            let adjustedWidth = adjustedHeight * aspectRatio
            metalView.frame = CGRect(x: (contentWidth - adjustedWidth) / 2, y: 0, width: adjustedWidth, height: adjustedHeight)
        } else {
            // Center normally
            metalView.frame = CGRect(x: 0, y: (adjustedContentHeight - targetHeight) / 2, width: targetWidth, height: targetHeight)
        }

        // Logger.log("MetalView resized to: \(metalView.frame.size), aspect ratio: \(metalView.frame.size.aspectRatioFormattedTo2Places) ", level: .debug)
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

        guard let fpsMonitor = fpsMonitor, let simulationManager = simulationManager else {
            Logger.log("fpsMonitor or simulationManager is nil", level: .error)
            return
        }
        
        renderer = Renderer(metalView: metalView, fpsMonitor: fpsMonitor, simulationManager: simulationManager)
        ParticleSystem.shared.renderer = renderer
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
        
        guard let simulationManager = simulationManager else {
            Logger.log("simulationManager is nil", level: .error)
            return
        }

        let settingsView = SimulationSettingsView(simulationManager: simulationManager)
        
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
        guard let simulationManager = simulationManager else {
            Logger.log("simulationManager is nil", level: .error)
            return
        }

        let location = event.locationInWindow
        let convertedLocation = metalView.convert(location, from: nil)
        let worldPosition = simulationManager.screenToWorld(screenPosition: convertedLocation,
                                                                     drawableSize: metalView.drawableSize,
                                                                     viewSize: metalView.frame.size)
        let effectRadius: Float = isRightClick ? 3.0 : 1.0
        simulationManager.handleMouseClick(at: worldPosition, effectRadius: effectRadius)
    }

    // MARK: Key Events
    
    private func setupKeyboardTracking() {
        guard let simulationManager = simulationManager else {
            Logger.log("simulationManager is nil", level: .error)
            return
        }

        keyEventRouter = KeyEventRouter(renderer: renderer,
                                        simulationManager: simulationManager,
                                        toggleSettingsPanelAction: { self.toggleSettingsPanel() })
    }
    
    override func keyDown(with event: NSEvent) {
        keyEventRouter?.keyDown(with: event)
    }
    
    override func keyUp(with event: NSEvent) {
        keyEventRouter?.keyUp(with: event)
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
