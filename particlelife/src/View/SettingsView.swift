//
//  SettingsView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI
import MetalKit
import SceneKit

struct SimulationSettingsView: View {
    @ObservedObject var particleSystem = ParticleSystem.shared
    @ObservedObject var settings = SimulationSettings.shared
    @ObservedObject var renderer: Renderer
    
    @State private var isVisible: Bool = true
    @State private var isShowingSaveSheet = false
    @State private var isShowingDeleteSheet = false
    @State private var presetName: String = "Untitled"
    @State private var isPinned: Bool = true

    var body: some View {
        VStack {
            
            Image("particle-life-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 220)
                .padding()
                .padding(.top, 10)
                        
            MatrixView(interactionMatrix: $particleSystem.interactionMatrix, isVisible: $isVisible, renderer: renderer, speciesColors: particleSystem.speciesColors)
                .frame(width: 300, height: 300)
            
            VStack(spacing: 20) {
                PresetPickerView(settings: settings, renderer: renderer)
                MarixPickerView(settings: settings, renderer: renderer)
                DistributionPickerView(settings: settings, renderer: renderer)
            }
            .padding(.top, 15)
            
            VStack(spacing: 20) {
                PresetButtonsView(isShowingSaveSheet: $isShowingSaveSheet, isShowingDeleteSheet: $isShowingDeleteSheet, renderer: renderer)
                CustomDivider()
                SpeciesAndParticlesView(settings: settings, renderer: renderer)
                    .padding(.top, 6)
                SimulationButtonsView(renderer: renderer)
                    .padding(.top, 6)
            }
            .padding(.top, 20)
            .padding(.bottom, 4)

            SimulationSlidersView(settings: settings, renderer: renderer)
                .padding(.top, 10)
            
            CustomDivider()
                .padding(.top, 20)
            
            FooterView(renderer: renderer, isPinned: $isPinned)
                .padding(.top, 6)
                .padding(.bottom, 6)
                .padding(.horizontal, 10)

            Spacer()
        }
        .background(renderer.isPaused ? Color(red: 0.5, green: 0, blue: 0).opacity(0.9) : Color.black.opacity(0.9))
        .clipShape(RoundedCornerShape(corners: [.topRight, .bottomRight], radius: 20))
        .overlay(
            RoundedCornerShape(corners: [.topRight, .bottomRight], radius: 20)
                .stroke(Color(white: 0.33), lineWidth: 2)
        )
        .shadow(radius: 5)
        .opacity(isVisible ? 1.0 : 0.0)
        .allowsHitTesting(isVisible)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .popover(isPresented: $isShowingSaveSheet) {
            SavePresetSheet(isShowingSaveSheet: $isShowingSaveSheet, presetName: $presetName)
        }
        .popover(isPresented: $isShowingDeleteSheet) {
            DeletePresetSheet(isShowingDeleteSheet: $isShowingDeleteSheet)
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.keyCode == 48 { // Tab key
                    withAnimation { isVisible.toggle() }
                }
                return event
            }
        }
        .onHover { hovering in
            if !isPinned && !isShowingSaveSheet && !isShowingDeleteSheet {
                withAnimation {
                    isVisible = hovering
                }
            }
        }
    }
}

struct CustomDivider: View {
    var body: some View {
        Divider()
            .background(Color(white: 0.33))
            .padding(.vertical, 4)
    }
}

struct FooterView: View {
    @ObservedObject var renderer: Renderer
    @Binding var isPinned: Bool

    var body: some View {
        HStack {

            Text("v\(AppInfo.version)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)

            Spacer()

            Text(renderer.isPaused ? "PAUSED" : "FPS: \(renderer.fps)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(renderer.isPaused || renderer.fps < 30 ? .red : .green)
            
            Spacer()
            
            Button(action: {
                isPinned.toggle() // Toggle the pinned state
            }) {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .foregroundColor(isPinned ? .yellow : .gray)
                    .font(.system(size: 16))
                    .padding(4)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle()) // Prevents default button styling

        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PresetPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Preset:")
                .frame(width: 90, alignment: .trailing)
            Picker("", selection: Binding(
                get: { settings.selectedPreset.id },
                set: { newPresetID in
                    if let newPreset = ([
                        PresetDefinitions.randomPreset,
                        PresetDefinitions.emptyPreset
                    ] + PresetDefinitions.specialPresets + settings.userPresets)
                        .first(where: { $0.id == newPresetID }) {
                        settings.selectPreset(newPreset)
                    }
                }
            )) {
                Text("⬜ \(PresetDefinitions.emptyPreset.name)").tag(PresetDefinitions.emptyPreset.id)
                Text("🔀 \(PresetDefinitions.randomPreset.name)").tag(PresetDefinitions.randomPreset.id)
                Text("").disabled(true)
                ForEach(PresetDefinitions.specialPresets, id: \.id) { preset in
                    Text("⭐ \(preset.name)").tag(preset.id)
                }
                
                if !settings.userPresets.isEmpty {
                    Text("").disabled(true)
                    ForEach(settings.userPresets, id: \.id) { preset in
                        Text("📁 \(preset.name)").tag(preset.id)
                    }
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)
        }
        .frame(width: 248)
    }
}

struct MarixPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Matrix:")
                .frame(width: 90, alignment: .trailing)
            Picker("", selection: Binding(
                get: { settings.selectedPreset.matrixType },
                set: { newType in
                    if newType != settings.selectedPreset.matrixType {
                        settings.updateMatrixType(newType)
                    }
                }
            )) {
                ForEach(MatrixType.allCases, id: \.self) { type in
                    Text(type.name).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)
        }
        .frame(width: 248)
    }
    
}

struct DistributionPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Distribution:")
                .frame(width: 90, alignment: .trailing)
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
        .frame(width: 248)
    }
}

struct PresetButtonsView: View {
    @Binding var isShowingSaveSheet: Bool
    @Binding var isShowingDeleteSheet: Bool
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 20) {
            Button("📁  Save") {
                isShowingSaveSheet = true
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused)
            
            Button("❌  Delete") {
                if !SimulationSettings.shared.selectedPreset.isBuiltIn {
                    isShowingDeleteSheet = true
                }
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused || SimulationSettings.shared.selectedPreset.isBuiltIn)
        }
    }
}

struct SimulationButtonsView: View {
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 20) {
            Button("↩️  Reset") {
                let commandDown = NSEvent.modifierFlags.contains(.command)
                if commandDown {
                    ParticleSystem.shared.dumpPresetAsCode()
                }
                else {
                    SimulationSettings.shared.selectPreset(SimulationSettings.shared.selectedPreset)
                }
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused)
            
            Button("♻️  Respawn") {
                renderer.respawnParticles()
            }
            .buttonStyle(SettingsButtonStyle())
            .disabled(renderer.isPaused)
        }
    }
}

struct SpeciesAndParticlesView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer

    var body: some View {
        VStack(spacing: 20) {
            speciesCountPicker()
            particleCountPicker()
        }
    }
    
    private func speciesCountPicker() -> some View {
        HStack(spacing: 0) {
            Text("Species:")
                .frame(width: 90, alignment: .trailing)

            Picker("", selection: Binding(
                get: { settings.selectedPreset.speciesCount },
                set: { newCount in
                    ParticleSystem.shared.speciesCountWillChange(newCount: newCount)
                }
            )) {
                ForEach(1...9, id: \.self) { count in
                    Text("\(count)").tag(count)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .pickerStyle(MenuPickerStyle())
        }
        .frame(width: 248)
        .padding(.horizontal)
    }
    
    private func particleCountPicker() -> some View {
        HStack(spacing: 0) {
            Text("Particles:")
                .frame(width: 90, alignment: .trailing)

            Picker("", selection: Binding(
                get: { settings.selectedPreset.particleCount },
                set: { newCount in
                    ParticleSystem.shared.particleCountWillChange(newCount: newCount)
                }
            )) {
                ForEach(ParticleCount.allCases, id: \.self) { count in
                    Text(count.displayString).tag(count)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
        .frame(width: 248)
        .padding(.horizontal)
    }
}

struct SimulationSlidersView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        VStack(spacing: 20) {
            CustomDivider()
            settingSlider(title: "Max Dist", setting: $settings.maxDistance)
            settingSlider(title: "Min Dist", setting: $settings.minDistance)
            settingSlider(title: "Beta", setting: $settings.beta)
            settingSlider(title: "Friction", setting: $settings.friction)
            settingSlider(title: "Repulsion", setting: $settings.repulsion)
            settingSlider(title: "Point Size", setting: $settings.pointSize)
            settingSlider(title: "World Size", setting: $settings.worldSize)
        }
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
            presetName = "Untitled"
            isShowingSaveSheet = false
        }
    }
}

struct DeletePresetSheet: View {
    @Binding var isShowingDeleteSheet: Bool
    let presetToDelete = SimulationSettings.shared.selectedPreset
    
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
                .buttonStyle(.bordered)

                Button("Delete") {
                    PresetManager.shared.deleteUserPreset(named: presetToDelete.name)
                    SimulationSettings.shared.userPresets = PresetManager.shared.getUserPresets()
                    SimulationSettings.shared.selectPreset(PresetDefinitions.getDefaultPreset())
                    isShowingDeleteSheet = false
                }
                .buttonStyle(.borderedProminent)
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
        HStack {
            configuration.label
                .font(.system(size: 14, weight: .medium)) // Bigger, slightly bolder text
                .foregroundColor(.white)
            Spacer() // Push text/icons to the left
        }
        .padding(.horizontal, 10) // More breathing room
        .frame(width: 120, height: 30)
        .background(Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.85)) // Darker background
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
