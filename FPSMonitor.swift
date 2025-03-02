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
    private var timer: Timer?
    private var lastFPS: Int = -1 // Track last sent FPS as an Int

    func frameRendered() {
        frameCount += 1
        let currentTime = CFAbsoluteTimeGetCurrent()

        guard let lastTime = lastUpdateTime else {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastTime

        if deltaTime >= 1.0 {
            let calculatedFPS = Int(round(Double(frameCount) / deltaTime)) // Convert to Int

            // Only send notification if FPS has changed
            if calculatedFPS != lastFPS {
                NotificationCenter.default.post(
                    name: .fpsDidUpdate, object: nil, userInfo: ["fps": calculatedFPS]
                )
                //Logger.log("framerate: \(calculatedFPS) changed")
                lastFPS = calculatedFPS // Update last sent FPS
            }

            frameCount = 0
            lastUpdateTime = currentTime
        }
    }

    func startMonitoring() {
        Logger.log("starting FPS monitor", level: .debug)
        lastUpdateTime = nil // Reset so it initializes on first frame
    }

    func stopMonitoring() {
        Logger.log("stopping FPS monitor", level: .debug)
        timer?.invalidate()
        timer = nil
    }
}
