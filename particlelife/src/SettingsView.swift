//
//  SettingsView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI

struct SimulationSettingsView: View {
    @ObservedObject var particleSystem = ParticleSystem.shared
    @ObservedObject var settings = SimulationSettings.shared
    @ObservedObject var renderer: Renderer  // Observe Renderer for FPS updates

    @State private var interactionMatrix: [[Float]] = ParticleSystem.shared.interactionMatrix
    @State private var speciesColors: [Color] = ParticleSystem.shared.speciesColors

    var body: some View {
        VStack {
            Text("Simulation Settings")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 5)
            
            Text("Particles: \(Constants.defaultParticleCount)")
                .font(.body)
                .foregroundColor(.white)
                .padding(.bottom, 5)

            Text(renderer.isPaused ? "PAUSED" : "FPS: \(renderer.fps)")
                .font(.headline)
                .foregroundColor(renderer.isPaused || renderer.fps < 30 ? .red : .green)
            
            MatrixView(interactionMatrix: particleSystem.interactionMatrix, speciesColors: particleSystem.speciesColors)

            Slider(value: $settings.maxDistance, in: SimulationSettings.maxDistanceMin...SimulationSettings.maxDistanceMax, step: 0.01) {
                Text("Max Distance: \(settings.maxDistance, specifier: "%.2f")")
            }

            Slider(value: $settings.minDistance, in: SimulationSettings.minDistanceMin...SimulationSettings.minDistanceMax, step: 0.01) {
                Text("Min Distance: \(settings.minDistance, specifier: "%.2f")")
            }

            Slider(value: $settings.beta, in: SimulationSettings.betaMin...SimulationSettings.betaMax, step: 0.01) {
                Text("Beta: \(settings.beta, specifier: "%.2f")")
            }

            Slider(value: $settings.friction, in: SimulationSettings.frictionMin...SimulationSettings.frictionMax, step: 0.01) {
                Text("Friction: \(settings.friction, specifier: "%.2f")")
            }

            Slider(value: $settings.repulsionStrength, in: SimulationSettings.repulsionStrengthMin...SimulationSettings.repulsionStrengthMax, step: 0.01) {
                Text("Repulsion: \(settings.repulsionStrength, specifier: "%.2f")")
            }
            
            Divider()
                .background(Color.white.opacity(0.5))
                .padding(.vertical, 5)
            
            Button(action: {
                settings.resetToDefaults()  // Reset physics settings to defaults
            }) {
                Text("Reset to Defaults")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .compositingGroup()  // Reduces GPU redraws
                    .drawingGroup()  // Renders UI as a single texture to reduce SwiftUI overhead
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .padding(.bottom, 240)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
        .shadow(radius: 5)
        .onReceive(NotificationCenter.default.publisher(for: .resetSimulation)) { _ in
            interactionMatrix = ParticleSystem.shared.interactionMatrix
            speciesColors = ParticleSystem.shared.speciesColors
        }
    }
}
