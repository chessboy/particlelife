//
//  SpashScreenView.swift
//  particlelife
//
//  Created by Rob Silverman on 3/5/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 0.0
    @State private var circleOpacities = [0.0, 0.0, 0.0] // Start circles fully transparent
    
    var speciesColors: [Color] = Array(ColorPalette.classic.colors.dropFirst(1).prefix(3))
    var onDismiss: () -> Void // Closure to notify VC when splash is done

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                Image("particle-life-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 500)

                HStack {
                    ForEach(0..<speciesColors.count, id: \.self) { index in
                        ShadedCircleView(color: speciesColors[index], cellSize: 15, circleScale: 0.75)
                            .frame(width: 40)
                            .opacity(circleOpacities[index]) // Apply staggered fade-in effect
                    }
                }
                .padding(.top, 30)

                Text("©2025 Redbar LLC")
                    .foregroundColor(.gray)
                    .padding(.top, 60)
            }
            .opacity(opacity)

            // Fade in on appear
            .onAppear {
                // Fade in the main content
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1.0
                }

                // Staggered fade-in for circles
                for i in 0..<circleOpacities.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + (0.3 * Double(i))) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            circleOpacities[i] = 1.0
                        }
                    }
                }

                // Hold for 2.5 seconds, then fade everything out
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 1.0)) {
                        opacity = 0.0
                        circleOpacities = [0.0, 0.0, 0.0] // Fade out circles too
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onDismiss() // Notify VC to remove splash
                    }
                }
            }
        }
    }
}
#Preview {
    SplashScreenView(onDismiss: {})
}
