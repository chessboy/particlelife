//
//  SliderPopupView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/24/25.
//

import SwiftUI

enum SliderMode: Equatable {
    case valueSelection
    case percentageSelection(minimum: Float, maximum: Float)

    static func == (lhs: SliderMode, rhs: SliderMode) -> Bool {
        switch (lhs, rhs) {
        case (.valueSelection, .valueSelection):
            return true
        case let (.percentageSelection(lhsMin, lhsMax), .percentageSelection(rhsMin, rhsMax)):
            return lhsMin == rhsMin && lhsMax == rhsMax
        default:
            return false
        }
    }
}

struct SliderPopupView: View {

    @Binding var value: Float
    @State private var isAllEvenHovered = false
    @State private var isStepSizeHovered = false
    @State private var hoveredQuickValue: Float?

    let mode: SliderMode  // New mode property

    let onValueChange: (Float) -> Void
    let onAllEven: () -> Void
    let onDismiss: () -> Void
    
    @State private var stepSize: Float = UserSettings.shared.float(forKey: UserSettingsKeys.matrixValueSliderStep, defaultValue: 0.05)
    
    let quickValues: [Float] = [-1.0, -0.5, 0.0, 0.5, 1.0] // Quick select values
    
    var sliderRange: ClosedRange<Float> {
        switch mode {
        case .valueSelection:
            return -1.0...1.0
        case .percentageSelection(let minimum, let maximum):
            return minimum...maximum // Uses both min and max values
        }
    }
    
    var iconForStepSize: String {
        return (stepSize == 0.01) ? SFSymbols.Name.stepSize01 : SFSymbols.Name.stepSize05
    }
    
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 0) {
                stepSizeButton
                Spacer()
                displayedValue
                Spacer()
                if mode != .valueSelection {
                    allEvenButton
                        .onTapGesture {
                            onAllEven()
                        }
                } else {
                    Rectangle()
                        .frame(width: 80, height: 10)
                        .foregroundColor(Color.clear)
                }
            }
            .frame(width: 280) // Ensure alignment

            let snappedBinding = Binding<Float>(
                get: { value },
                set: { newValue in
                    let clamped = max(sliderRange.lowerBound, min(sliderRange.upperBound, newValue))
                    let rounded = round(clamped / stepSize) * stepSize
                    value = rounded
                    onValueChange(value)
                }
            )
            
            // Slider
            Slider(value: snappedBinding, in: sliderRange.lowerBound...sliderRange.upperBound)
                .frame(width: 280)
                .onChange(of: value) { oldValue, newValue in
                    onValueChange(value)
                }

            // Quick Value Buttons (Only for .valueSelection Mode)
            if mode == .valueSelection {
                quickValueButtons
            }
        }
        .padding(20)
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

    // Step Size Button
    private var stepSizeButton: some View {
        Button(action: {
            stepSize = (stepSize == 0.05) ? 0.01 : 0.05
            UserSettings.shared.set(stepSize, forKey: UserSettingsKeys.matrixValueSliderStep)
        }) {
            HStack(spacing: 5) {
                let icon = iconForStepSize
                Image(systemName: icon)
                    .font(.body)
                Text(stepSize.formattedTo2Places)
                    .font(.body)
                    .bold()
                    .frame(width: 38)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: 80)
            .background(isStepSizeHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.08)) // Slight brightness increase on hover
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isStepSizeHovered ? 1.05 : 1.0) // Slight scale-up effect on hover
            .animation(.easeInOut(duration: 0.2), value: isStepSizeHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation {
                isStepSizeHovered = hovering
            }
        }
    }
    
    // Step Size Button
    private var allEvenButton: some View {

        Button(action: {
            onAllEven()
        }) {
            HStack(spacing: 5) {
                Text("All Even")
                    .font(.body)
                    .bold()
                    .frame(width: 80)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: 80)
            .background(isAllEvenHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.08)) // Slight brightness increase on hover
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isAllEvenHovered ? 1.05 : 1.0) // Slight scale-up effect on hover
            .animation(.easeInOut(duration: 0.2), value: isAllEvenHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation {
                isAllEvenHovered = hovering
            }
        }
    }


    // Displayed Value (Handles Different Modes)
    private var displayedValue: some View {
        Text(mode == .valueSelection ? value.formattedTo2Places : value.formattedToPercent2Places)
            .font(.title3)
            .bold()
            .foregroundColor(.white)
            .frame(width: 80)
    }

    // Quick Value Buttons
    private var quickValueButtons: some View {
        HStack(spacing: 15) {
            ForEach(quickValues, id: \.self) { quickValue in
                Button(action: {
                    value = quickValue
                    onValueChange(quickValue)
                    onDismiss()
                }) {
                    Text(quickValue.formatted)
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
                .buttonStyle(PlainButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered(for: quickValue) ? Color.white.opacity(0.12) : Color.white.opacity(0.08))
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaleEffect(isHovered(for: quickValue) ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered(for: quickValue))
                .onHover { hovering in
                    hoveredQuickValue = hovering ? quickValue : nil
                }
            }
        }
        .frame(width: 280)
    }

    private func isHovered(for value: Float) -> Bool {
        return hoveredQuickValue == value
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

                SliderPopupView(value: $sliderValue, mode: .percentageSelection(minimum: 0.05, maximum: 0.95), onValueChange: { _ in }, onAllEven: { }, onDismiss: { })
            }
        }
    }

    return SliderPopupPreviewWrapper()
}
