//
//  Notifications.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Foundation

extension Notification.Name {
    static let respawn = Notification.Name("respawn")
    static let presetSelected = Notification.Name("presetSelected")
    static let saveTriggered = Notification.Name("saveTriggered")
    static let closeSettingsPanel = Notification.Name("closeSettingsPanel")
    static let lowPerformanceWarning = Notification.Name("lowPerformanceWarning")
    static let particlesRespawned = Notification.Name("particlesRespawned")
}
