//
//  FPSMonitor.swift
//  particlelife
//
//  Created by Rob Silverman on 3/2/25.
//

import Foundation

extension Notification.Name {
    static let fpsDidUpdate = Notification.Name("fpsDidUpdate")
}

class FPSMonitor {
    private var lastUpdateTime: TimeInterval?
    private var frameCount: Int = 0
    private var lastFPS: Int = -1
    private var isPaused: Bool = false

    /// Call this when a frame is rendered
    func frameRendered() {
        // If paused, ignore frame updates
        if isPaused { return }

        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()

        guard let lastTime = lastUpdateTime else {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastTime

        if deltaTime >= 1.0 {
            let calculatedFPS = Int(round(Double(frameCount) / deltaTime))

            // Prevent FPS drop to 0 after unpausing
            let safeFPS = isPaused ? lastFPS : max(calculatedFPS, 30)

            if safeFPS != lastFPS {
                NotificationCenter.default.post(
                    name: .fpsDidUpdate, object: nil, userInfo: ["fps": safeFPS]
                )
                lastFPS = safeFPS
            }

            frameCount = 0
            lastUpdateTime = currentTime
        }
    }

    /// Call this when the app is paused or resumed
    private func setPaused(_ paused: Bool) {
        isPaused = paused

        if paused {
            //Logger.log("Pausing FPS monitor", level: .debug)
        } else {
            //Logger.log("Resuming FPS monitor", level: .debug)
            lastUpdateTime = CFAbsoluteTimeGetCurrent() // Reset timing
            frameCount = 0 // Prevent stale frame data
        }
    }

    func togglePaused() {
        setPaused(!isPaused)
    }
    
    func startMonitoring() {
        Logger.log("Starting FPS monitor", level: .debug)
        lastUpdateTime = nil // Reset time tracking
        isPaused = false
    }

    func stopMonitoring() {
        Logger.log("Stopping FPS monitor", level: .debug)
        isPaused = true
    }
}
