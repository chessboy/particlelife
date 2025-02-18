//
//  Contants.swift
//  particlelife
//
//  Created by Rob Silverman on 2/15/25.
//

import SwiftUI

struct Constants {
    
    static let speciesColors: [Color] = [
        Color(red: 1.0, green: 0.2, blue: 0.2), // 🔴 Soft Red
        Color(red: 1.0, green: 0.6, blue: 0.0), // 🟠 Orange
        Color(red: 0.95, green: 0.95, blue: 0.0), // 🟡 Warm Yellow
        Color(red: 0.0, green: 0.8, blue: 0.2), // 🟢 Green (Deeper)
        Color(red: 0.0, green: 0.4, blue: 1.0), // 🔵 Bright Blue
        Color(red: 0.6, green: 0.2, blue: 1.0), // 🟣 Purple
        Color(red: 0.0, green: 1.0, blue: 1.0), // 🔵 Cyan
        Color(red: 1.0, green: 0.0, blue: 0.6), // 💖 Hot Pink (Instead of Magenta)
        Color(red: 0.2, green: 0.8, blue: 0.6)  // 🌊 Teal (Replaces White)
    ]
    
    struct Controls {
        static let zoomStep: Float = 1.1
        static let panStep: Float = 0.05
    }
    
    static let ASPECT_RATIO: Float = 1.7778
}
