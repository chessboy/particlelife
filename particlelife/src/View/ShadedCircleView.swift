//
//  ShadedCircleView.swift
//  particlelife
//
//  Created by Rob Silverman on 3/1/25.
//

import SwiftUI

struct ShadedCircleView: View {
    var color: Color
    var cellSize: CGFloat
    var circleScale: CGFloat
    
    struct ShadingConstants {
        static let brightnessBoost: Double = 0.1
        
        static let highlightOpacity: Double = 0.2
        static let highlightStartRadiusFactor: CGFloat = 0.0
        static let highlightEndRadiusFactor: CGFloat = 0.5
        
        static let shadowOpacity: Double = 0.25
        static let shadowStartRadiusFactor: CGFloat = 0.0
        static let shadowEndRadiusFactor: CGFloat = 0.85
        
        static let overlayOpacity: Double = 0.1
    }

    var body: some View {
        ZStack {
            // Base color with brightness boost
            Circle()
                .fill(color)
                .brightness(ShadingConstants.brightnessBoost)
                .frame(width: cellSize * circleScale, height: cellSize * circleScale)
            
            // Soft radial highlight (top-left)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(ShadingConstants.highlightOpacity),
                            Color.clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: cellSize * circleScale * ShadingConstants.highlightEndRadiusFactor
                    )
                )
                .frame(width: cellSize * circleScale, height: cellSize * circleScale)
            
            // Depth shadow (bottom-right)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(ShadingConstants.shadowOpacity),
                            Color.clear
                        ]),
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: cellSize * circleScale * ShadingConstants.shadowEndRadiusFactor
                    )
                )
                .frame(width: cellSize * circleScale, height: cellSize * circleScale)
            
            // Overlay for smooth blending
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(ShadingConstants.overlayOpacity),
                            Color.clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: cellSize * circleScale, height: cellSize * circleScale)
        }
        .clipShape(Circle()) // Ensure everything remains within the circle
        .frame(width: cellSize, height: cellSize) // Align with the grid
    }
}
