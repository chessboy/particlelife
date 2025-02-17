//
//  MatrixView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI

struct MatrixView: View {
    let interactionMatrix: [[Float]]
    let speciesColors: [Color]
    
    var body: some View {
        VStack {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Color.clear.frame(width: 20, height: 20)
                    ForEach(0..<interactionMatrix.count, id: \.self) { col in
                        if col < speciesColors.count {  // Prevent index out of range
                            speciesColors[col]
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }
                    }
                }
                
                ForEach(0..<interactionMatrix.count, id: \.self) { row in
                    HStack(spacing: 2) {
                        if row < speciesColors.count {  // Prevent index out of range
                            speciesColors[row]
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }
                        
                        ForEach(0..<interactionMatrix[row].count, id: \.self) { col in
                            Rectangle()
                                .fill(colorForValue(interactionMatrix[row][col]))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 20)
            .cornerRadius(8)
        }
    }
    
    // Color scale function based on interaction values
    func colorForValue(_ value: Float) -> Color {
        if value > 0 {
            return Color(hue: 1/3, saturation: 1.0, brightness: 0.2 + 0.8 * Double(value))  // 🟢 Green (brighter for stronger attraction)
        } else if value < 0 {
            return Color(hue: 0, saturation: 1.0, brightness: 0.2 + 0.8 * Double(-value)) // 🔴 Red (brighter for stronger repulsion)
        } else {
            return .black  // 🖤 Neutral (0) should be black
        }
    }
}
