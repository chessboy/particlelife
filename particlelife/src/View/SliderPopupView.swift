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

    var body: some View {
        VStack(spacing: 6) {
            Text(String(format: "%.2f", value))
                .font(.headline)
                .bold()
                .foregroundColor(.white)

            Slider(value: $value, in: -1.0...1.0, step: 0.05)
                .frame(width: 280)
                .accentColor(.white)
                .onChange(of: value) { oldValue, newValue in
                    onValueChange(value)
                }
            
            HStack {
                Text("-1").font(.headline).foregroundColor(.gray)
                Spacer()
                Text("0").font(.headline).foregroundColor(.gray)
                    .offset(x: -2.5, y: 0)
                Spacer()
                Text("1").font(.headline).foregroundColor(.gray)
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
                onDismiss() // Close when hovering away
            }
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
