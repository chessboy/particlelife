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
                        if col < speciesColors.count {  // ✅ Prevent index out of range
                            speciesColors[col]
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        }
                    }
                }

                ForEach(0..<interactionMatrix.count, id: \.self) { row in
                    HStack(spacing: 2) {
                        if row < speciesColors.count {  // ✅ Prevent index out of range
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
            .padding(5)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }

    // ✅ Color scale function based on interaction values
    func colorForValue(_ value: Float) -> Color {
        if value > 0 {
            return Color(red: Double(0.5 + value * 0.5), green: 0.2, blue: 0.2)  // ✅ Reddish for attraction
        } else {
            return Color(red: 0.2, green: Double(0.5 - value * 0.5), blue: 0.2)  // ✅ Greenish for repulsion
        }
    }
}
