//
//  Notifications.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import Foundation

extension Notification.Name {
    static let saveTriggered = Notification.Name("saveTriggered")
    static let closeSettingsPanel = Notification.Name("closeSettingsPanel")
    static let lowPerformanceWarning = Notification.Name("lowPerformanceWarning")
}
