//
//  SliderPopupView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/24/25.
//

import SwiftUI

struct SliderPopupView: View {
    @Binding var value: Float
    let onValueChange: (Float) -> Void
    let onDismiss: () -> Void

    let quickValues: [Float] = [-1.0, -0.5, 0.0, 0.5, 1.0] // Quick select values

    var body: some View {
        VStack(spacing: 8) {
            Text(value.formattedTo2Places)
                .font(.title3)
                .bold()
                .foregroundColor(.white)

            Slider(value: $value, in: -1.0...1.0, step: 0.05)
                .frame(width: 280)
                .accentColor(.white)
                .onChange(of: value) { oldValue, newValue in
                    onValueChange(value)
                }
            HStack(spacing: 15) {
                ForEach(quickValues, id: \.self) { quickValue in
                    Button(action: {
                        value = quickValue
                        onValueChange(quickValue)
                        onDismiss()
                    }) {
                        Text(String(format: "%.1f", quickValue))
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                            .frame(width: 44, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorForValue(quickValue))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle()) // Keeps it visually consistent
                }
            }
            .frame(width: 280)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.15))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.8), radius: 8, y: 2)
        .onHover { isHovering in
            if !isHovering {
                onDismiss()
            }
        }
    }
    
    /// Determines color based on interaction value (consistent with matrix grid)
    private func colorForValue(_ value: Float) -> Color {
        if value > 0 {
            return Color(hue: 1/3, saturation: 1.0, brightness: 0.2 + 0.8 * Double(value)) // Green for attraction
        } else if value < 0 {
            return Color(hue: 0, saturation: 1.0, brightness: 0.2 + 0.8 * Double(-value)) // Red for repulsion
        } else {
            return .black // Neutral (0) is black
        }
    }

}

#Preview {
    struct SliderPopupPreviewWrapper: View {
        @State private var sliderValue: Float = 0.0

        var body: some View {
            ZStack {
                Color.black.opacity(0.5) // Background for contrast
                    .ignoresSafeArea()

                SliderPopupView(value: $sliderValue) { newValue in
                    print("Slider value changed: \(newValue)")
                } onDismiss: {}
            }
        }
    }

    return SliderPopupPreviewWrapper()
}
