//
//  Contants.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import SwiftUI

let ASPECT_RATIO: CGFloat = 1.777778

struct UserSettingsKeys {
    static let colorPaletteIndex = "colorPaletteIndex"
    static let speciesColorOffset = "speciesColorOffset"
    static let showingPhysicsPane = "showingPhysicsPane"
    static let colorEffectIndex = "colorEffectIndex"
}

struct AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}
