//
//  Contants.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import SwiftUI

let ASPECT_RATIO: CGFloat = 1.7778
let windowMinHeight: CGFloat = 1050

struct UserSettingsKeys {
    static let colorPaletteIndex = "colorPaletteIndex"
    static let colorOffset = "colorOffset"
    static let showingPhysicsPane = "showingPhysicsPane"
    static let matrixValueSliderStep = "matrixValueSliderStep"
}

struct AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}
