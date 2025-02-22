//
//  SettingsView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI
import MetalKit

import SwiftUI
import MetalKit

struct SimulationSettingsView: View {
    @ObservedObject var particleSystem = ParticleSystem.shared
    @ObservedObject var settings = SimulationSettings.shared
    @ObservedObject var renderer: Renderer
    
    @State private var isVisible: Bool = true
    @State private var isShowingSaveSheet = false
    @State private var isShowingDeleteSheet = false
    @State private var presetName: String = ""
    @State private var presetToDelete: SimulationPreset?
    
    var body: some View {
        VStack {
            Spacer()

            SimulationHeaderView(renderer: renderer)
            
            MatrixView(interactionMatrix: $particleSystem.interactionMatrix, isVisible: $isVisible, renderer: renderer, speciesColors: particleSystem.speciesColors)
                .padding(.top, 15)
            
            PresetPickerView(settings: settings, renderer: renderer)
                .padding(.top, 20)
            
            DistributionPickerView(settings: settings, renderer: renderer)
                .padding(.top, 10)
                .padding(.bottom, 20)

            PresetButtonsView(
                isShowingSaveSheet: $isShowingSaveSheet,
                isShowingDeleteSheet: $isShowingDeleteSheet,
                presetToDelete: $presetToDelete,
                renderer: renderer
            )
            
            SimulationControlsView(renderer: renderer)
                .padding(.bottom, 14)
            
            SimulationSlidersView(settings: settings, renderer: renderer)
                .padding(.top, 10)
            
            Spacer()
        }
        .padding(20)
        .frame(width: 320, height: 2000)
        .background(renderer.isPaused ? Color(red: 0.5, green: 0, blue: 0).opacity(0.75) : Color.black.opacity(0.75))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(isVisible ? 1.0 : 0.0)
        .allowsHitTesting(isVisible)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .sheet(isPresented: $isShowingSaveSheet) {
            SavePresetSheet(isShowingSaveSheet: $isShowingSaveSheet, presetName: $presetName)
        }
        .sheet(isPresented: $isShowingDeleteSheet) {
            if let preset = presetToDelete {
                DeletePresetSheet(isShowingDeleteSheet: $isShowingDeleteSheet, presetToDelete: preset)
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.keyCode == 48 { // Tab key
                    withAnimation { isVisible.toggle() }
                }
                return event
            }
        }
    }
}

struct SimulationHeaderView: View {
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack {
            Text(renderer.isPaused ? "PAUSED" : "FPS: \(renderer.fps)")
                .font(.headline)
                .foregroundColor(renderer.isPaused || renderer.fps < 30 ? .red : .green)
            
            Text("\(renderer.zoomLevel, specifier: "%.2f")x")
        }
    }
}

struct DistributionPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Distribution:")
                .frame(width: 100, alignment: .trailing)
            Picker("", selection: Binding(
                get: { settings.selectedPreset.distributionType },
                set: { newType in
                    if newType != settings.selectedPreset.distributionType {
                        settings.updateDistributionType(newType)
                    }
                }
            )) {
                ForEach(DistributionType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)
        }
    }
}

struct PresetPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Preset:")
                .frame(width: 100, alignment: .trailing)
            Picker("", selection: Binding(
                get: { settings.selectedPreset },
                set: { newPreset in
                    if newPreset != settings.selectedPreset {
                        settings.selectPreset(newPreset)
                    }
                }
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
        }
    }
}

struct PresetButtonsView: View {
    @Binding var isShowingSaveSheet: Bool
    @Binding var isShowingDeleteSheet: Bool
    @Binding var presetToDelete: SimulationPreset?
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack {
            Button("Save") {
                isShowingSaveSheet = true
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused)
            
            Button("Delete") {
                presetToDelete = SimulationSettings.shared.selectedPreset
                isShowingDeleteSheet = true
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused || SimulationSettings.shared.selectedPreset.isBuiltIn)
        }
    }
}

struct SimulationControlsView: View {
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack {
            Button("Reset") {
                let commandDown = NSEvent.modifierFlags.contains(.command)
                if commandDown {
                    ParticleSystem.shared.dumpPresetAsCode()
                }
                else {
                    SimulationSettings.shared.selectPreset(SimulationSettings.shared.selectedPreset, skipRespawn: true)
                }
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused)
            
            Button("Respawn") {
                renderer.respawnParticles()
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused)
        }
    }
}

struct SimulationSlidersView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        VStack {
            
            particleCountStepper()
            settingSlider(title: "Max Dist", setting: $settings.maxDistance)
            settingSlider(title: "Min Dist", setting: $settings.minDistance)
            settingSlider(title: "Beta", setting: $settings.beta)
            settingSlider(title: "Friction", setting: $settings.friction)
            settingSlider(title: "Repulsion", setting: $settings.repulsion)
            settingSlider(title: "Point Size", setting: $settings.pointSize)
            settingSlider(title: "World Size", setting: $settings.worldSize)
        }
    }
    
    private func particleCountStepper() -> some View {
        HStack(spacing: 0) {
            Text("Particles:")
                .frame(width: 75, alignment: .trailing)

            Text(settings.selectedPreset.particleCount.displayString)
                .bold()
                .frame(width: 37, alignment: .trailing)
                //.padding(.right, 10)
            
            Stepper("", onIncrement: {
                if let next = ParticleCount.allCases.first(where: { $0.rawValue > settings.selectedPreset.particleCount.rawValue }) {
                    ParticleSystem.shared.particleCountWillChange(newCount: next)
                }
            }, onDecrement: {
                if let prev = ParticleCount.allCases.last(where: { $0.rawValue < settings.selectedPreset.particleCount.rawValue }) {
                    ParticleSystem.shared.particleCountWillChange(newCount: prev)
                }
            })
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
    
    private func settingSlider(title: String, setting: Binding<ConfigurableSetting>) -> some View {
        HStack {
            Text("\(title):").frame(width: 75, alignment: .trailing)
            Text("\(setting.wrappedValue.value, specifier: setting.wrappedValue.format)").bold()
            Slider(value: setting.value, in: setting.wrappedValue.min...setting.wrappedValue.max, step: setting.wrappedValue.step)
        }
        .padding(.horizontal)
        .disabled(renderer.isPaused)
    }
}

struct SavePresetSheet: View {
    @Binding var isShowingSaveSheet: Bool
    @Binding var presetName: String
    
    var body: some View {
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
                .frame(width: 120)
                
                Button("Save") {
                    savePreset()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 120)
                .disabled(presetName.isEmpty)
            }
            .padding(.top, 5)
        }
        .padding(15)
        .frame(width: 250)
    }
    
    private func savePreset() {
        if !presetName.isEmpty {
            SimulationSettings.shared.saveCurrentPreset(named: presetName, interactionMatrix: ParticleSystem.shared.interactionMatrix)
            isShowingSaveSheet = false
        }
    }
}

struct DeletePresetSheet: View {
    @Binding var isShowingDeleteSheet: Bool
    let presetToDelete: SimulationPreset
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Delete Preset?")
                .font(.title2)
                .bold()
            
            Text("Are you sure you want to delete **\(presetToDelete.name)**?")
                .multilineTextAlignment(.center)
            
            HStack {
                Button("Cancel") {
                    isShowingDeleteSheet = false
                }
                .buttonStyle(SettingsButtonStyle())
                
                Button("Delete") {
                    PresetManager.shared.deleteUserPreset(named: presetToDelete.name)
                    SimulationSettings.shared.userPresets = PresetManager.shared.getUserPresets()
                    SimulationSettings.shared.selectPreset(PresetDefinitions.getDefaultPreset())
                    isShowingDeleteSheet = false
                }
                .buttonStyle(SettingsButtonStyle())
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 10)
    }
}

struct SettingsButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 120, height: 30)
            .background(Color(red: 0.4, green: 0.4, blue: 0.4).opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .compositingGroup()
            .drawingGroup()
            .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1.0 : 0.6))
    }
}

#Preview {
    let mtkView = MTKView()
    let renderer = Renderer(mtkView: mtkView)
    return NSHostingView(rootView: SimulationSettingsView(renderer: renderer))
}
