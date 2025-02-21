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
    
    @State private var presetName: String = ""  // Stores input name
    @State private var isShowingSaveSheet = false  // Controls sheet visibility

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
            
            MatrixView(interactionMatrix: $particleSystem.interactionMatrix, isVisible: $isVisible, renderer: renderer, speciesColors: particleSystem.speciesColors)
            
            Picker("Preset", selection: Binding(
                get: { settings.selectedPreset },
                set: { newPreset in settings.selectPreset(newPreset) }
            )) {
                Text("— Random Presets —").disabled(true)
                ForEach(PresetDefinitions.randomPresets, id: \.name) { preset in
                    Text(preset.name).tag(preset)
                }

                Text("— Empty Presets —").disabled(true)
                ForEach(PresetDefinitions.emptyPresets, id: \.name) { preset in
                    Text(preset.name).tag(preset)
                }

                Text("— Special Presets —").disabled(true)
                ForEach(PresetDefinitions.specialPresets, id: \.name) { preset in
                    Text(preset.name).tag(preset)
                }

                if !settings.userPresets.isEmpty {
                    Text("— User Presets —").disabled(true)
                    ForEach(settings.userPresets, id: \.name) { preset in
                        Text(preset.name).tag(preset)
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)

            VStack {
                Button(action: {
                    presetName = ""  // Reset input
                    isShowingSaveSheet = true  // Show sheet
                }) {
                    Text("Save Preset")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .compositingGroup()  // Reduces GPU redraws
                        .drawingGroup()  // Renders UI as a single texture to reduce SwiftUI overhead
                        .cornerRadius(10)
                        .frame(height: 20)
                }
                .disabled(renderer.isPaused)

            }
            .padding()
            .sheet(isPresented: $isShowingSaveSheet) {
                VStack(spacing: 12) {  // Reduce spacing
                    Text("Enter Preset Name")
                        .font(.headline)

                    TextField("Preset Name", text: $presetName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                        .padding(.horizontal, 10)
                        .onSubmit {
                            savePreset()
                        }

                    HStack {
                        Button("Cancel") {
                            isShowingSaveSheet = false
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 80)

                        Spacer()

                        Button("Save") {
                            savePreset()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width: 80)
                        .disabled(presetName.isEmpty)
                    }
                    .padding(.top, 5)
                }
                .padding(15)
                .frame(width: 250)
            }

            HStack {
                Button(action: {
                    let isCommandClick = NSEvent.modifierFlags.contains(.command)

                    if isCommandClick {
                        particleSystem.dumpPresetAsCode()
                    } else {
                        settings.applyPreset(SimulationSettings.shared.selectedPreset)
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
                .disabled(renderer.isPaused)

                Button(action: {
                    renderer.respawnParticles()
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
            }
            .padding(.bottom, 14)
            .disabled(renderer.isPaused)
            
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
        .frame(width: 320, height: 2000)
        .background(renderer.isPaused ? Color(red: 0.5, green: 0, blue: 0).opacity(0.75) : Color.black.opacity(0.75))
        .cornerRadius(10)
        .shadow(radius: 5)
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
    
    private func savePreset() {
        if !presetName.isEmpty {
            settings.saveCurrentPreset(named: presetName)
            isShowingSaveSheet = false
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
        .disabled(renderer.isPaused)
    }
}

#Preview {
    let mtkView = MTKView()
    let renderer = Renderer(mtkView: mtkView)
    return NSHostingView(rootView: SimulationSettingsView(renderer: renderer))
}
