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
    static let presetSelectedNoRespawn = Notification.Name("presetSelectedNoRespawn")
}
