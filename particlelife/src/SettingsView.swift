//
//  SettingsView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI
import MetalKit

struct SimulationSettingsView: View {
    @ObservedObject var particleSystem = ParticleSystem.shared
    @ObservedObject var settings = SimulationSettings.shared
    @ObservedObject var renderer: Renderer
    
    @State private var interactionMatrix: [[Float]] = ParticleSystem.shared.interactionMatrix
    @State private var speciesColors: [Color] = ParticleSystem.shared.speciesColors
    @State private var isVisible: Bool = true

    var body: some View {
        VStack {
            
            HStack {
                Text("Particles: \(SimulationSettings.shared.selectedPreset.numParticles.displayString)")
                    .font(.body)
                    .foregroundColor(.white)
                
                Text(renderer.isPaused ? "PAUSED" : "FPS: \(renderer.fps)")
                    .font(.headline)
                    .foregroundColor(renderer.isPaused || renderer.fps < 30 ? .red : .green)
                
                Text("\(renderer.zoomLevel, specifier: "%.2f")x")
            }
            
            MatrixView(interactionMatrix: $particleSystem.interactionMatrix, isVisible: $isVisible, speciesColors: particleSystem.speciesColors)
            
            Picker("Preset", selection: $settings.selectedPreset) {
                ForEach(SimulationPreset.allPresets, id: \.name) { preset in
                    Text(preset.name).tag(preset)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.bottom, 10)
            
            HStack {
                Button(action: {
                    let isCommandClick = NSEvent.modifierFlags.contains(.command)

                    if isCommandClick {
                        particleSystem.dumpPresetAsCode()
                    } else {
                        settings.applyPreset(SimulationSettings.shared.selectedPreset, sendEvent: false)
                    }
                }) {
                    Text("Reset")
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
                    Text("Respawn")
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
                
                settingSlider(title: "Max Dist", setting: $settings.maxDistance)
                settingSlider(title: "Min Dist", setting: $settings.minDistance)
                settingSlider(title: "Beta", setting: $settings.beta)
                settingSlider(title: "Friction", setting: $settings.friction)
                settingSlider(title: "Repulsion", setting: $settings.repulsion)
                settingSlider(title: "Point Size", setting: $settings.pointSize)
                settingSlider(title: "World Size", setting: $settings.worldSize)
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.66))
        .cornerRadius(10)
        .shadow(radius: 5)
        .onReceive(NotificationCenter.default.publisher(for: .respawn)) { _ in
            interactionMatrix = ParticleSystem.shared.interactionMatrix
            speciesColors = ParticleSystem.shared.speciesColors
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .allowsHitTesting(isVisible) // Disable interaction when invisible
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.keyCode == 48 { // Tab key
                    withAnimation { isVisible.toggle() }
                }
                return event
            }
        }
    }
    
    /// Reusable slider view for settings (Single-Line Layout with Bold Value)
    private func settingSlider(title: String, setting: Binding<ConfigurableSetting>) -> some View {
        HStack {
            Text("\(title):")
                .frame(width: 75, alignment: .trailing)
            
            Text("\(setting.wrappedValue.value, specifier: setting.wrappedValue.format)")
                .bold()
            
            Slider(
                value: setting.value,
                in: setting.wrappedValue.min...setting.wrappedValue.max,
                step: setting.wrappedValue.step
            )
        }
        .padding(.horizontal)
    }
}

#Preview {
    let mtkView = MTKView()
    let renderer = Renderer(mtkView: mtkView)
    return NSHostingView(rootView: SimulationSettingsView(renderer: renderer))
}
