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
}

struct AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
}
