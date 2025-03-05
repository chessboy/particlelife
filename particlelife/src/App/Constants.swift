//
//  Contants.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import SwiftUI

struct Constants {
        
    struct Controls {
        static let zoomStep: Float = 1.01
        static let panStep: Float = 0.01
    }
    
    static let ASPECT_RATIO: CGFloat = 1.7778
    
    static let startInFullScreen = false
}

struct UserSettingsKeys {
    static let colorPaletteIndex = "colorPaletteIndex"
    static let speciesColorOffset = "speciesColorOffset"
    static let startupInFullScreen = "startupInFullScreen"
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

struct SFSymbols {
    
    struct Name {
        static let close = "xmark.circle.fill"
        static let randomize = "shuffle"
        static let reset = "arrowshape.turn.up.backward.fill"
        static let respawn = "arrow.trianglehead.2.clockwise.rotate.90"
        static let settings = "gearshape.fill"
        static let colorEffect = "circle.bottomrighthalf.pattern.checkered"
        static let presets = "star.fill"
    }
    
    struct Symbol {
        static let new = "􀚈"
        static let random = "􀊝"
        static let presets = "􀋃"
        static let stored = "􀈖"
        static let save = "􀈸"
        static let delete = "􀈑"
    }
}
