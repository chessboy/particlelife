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
            
            Text("Particles: \(SimulationSettings.shared.selectedPreset.numParticles.displayString)")
                .font(.body)
                .foregroundColor(.white)
                .padding(.bottom, 5)

            Text(renderer.isPaused ? "PAUSED" : "FPS: \(renderer.fps)")
                .font(.headline)
                .foregroundColor(renderer.isPaused || renderer.fps < 30 ? .red : .green)
            
            MatrixView(interactionMatrix: particleSystem.interactionMatrix, speciesColors: particleSystem.speciesColors)
                
            Picker("Preset", selection: $settings.selectedPreset) {
                ForEach(SimulationPreset.allPresets, id: \.name) { preset in
                    Text(preset.name).tag(preset)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.bottom, 10)

            HStack {
                Button(action: {
                    settings.applyPreset(SimulationSettings.shared.selectedPreset, sendEvent: false)
                }) {
                    Text("Defaults")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .compositingGroup()  // Reduces GPU redraws
                        .drawingGroup()  // Renders UI as a single texture to reduce SwiftUI overhead
                        .cornerRadius(10)
                        .frame(height: 20)

                }
                
                Button(action: {
                    renderer.resetParticles()
                }) {
                    Text("Rebuild")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .compositingGroup()  // Reduces GPU redraws
                        .drawingGroup()  // Renders UI as a single texture to reduce SwiftUI overhead
                        .cornerRadius(10)
                        .frame(height: 20)
                }
            }.padding(.bottom, 14)

            VStack {
                
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
            }
        }
        .padding()
        .padding(.bottom, 280)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
        .shadow(radius: 5)
        .onReceive(NotificationCenter.default.publisher(for: .resetSimulation)) { _ in
            interactionMatrix = ParticleSystem.shared.interactionMatrix
            speciesColors = ParticleSystem.shared.speciesColors
        }
    }
}
