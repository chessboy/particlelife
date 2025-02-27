//
//  SettingsView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI
import MetalKit
import SceneKit

private let pickerViewWidth: CGFloat = 289
private let pickerLabelWidth: CGFloat = 72
private let labelColor = Color(white: 0.8)

struct SimulationSettingsView: View {
    @ObservedObject var particleSystem = ParticleSystem.shared
    @ObservedObject var settings = SimulationSettings.shared
    @ObservedObject var renderer: Renderer
    
    @State private var isVisible: Bool = true
    @State private var isShowingSaveSheet = false
    @State private var isShowingDeleteSheet = false
    @State private var presetName: String = "New Preset"
    
    @State private var isPinned: Bool = true
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .topLeading) {
                MatrixView(
                    interactionMatrix: $particleSystem.interactionMatrix,
                    isVisible: $isVisible,
                    isPinned: $isPinned,
                    renderer: renderer,
                    speciesColors: particleSystem.speciesColors
                )
                .frame(width: 300, height: 300)
                .padding(.top, 10)

                // Pin Button in the Empty Top-Left Space
                Button(action: {
                    isPinned.toggle() // Toggle the pinned state
                }) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .foregroundColor(isPinned ? .yellow : .gray)
                        .font(.system(size: 16))
                        .padding(6)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .offset(x: -3, y: 7)
                .buttonStyle(PlainButtonStyle())
            }
                        
            // Preset, Matrix, Distribution: Grouped neatly
            VStack(spacing: 12) {
                PresetPickerView(settings: settings, renderer: renderer)
                SpeciesPickerView(settings: settings, renderer: renderer)
                ParticleCountPickerView(settings: settings, renderer: renderer)
                MarixPickerView(settings: settings, renderer: renderer)
                DistributionPickerView(settings: settings, renderer: renderer)
            }
            .padding(.top, 15)
            
            // Controls: A little more room for clarity
            SimulationButtonsView(renderer: renderer)
            
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            PhysicsSettingsView(settings: settings, renderer: renderer)
            FooterView(renderer: renderer, isPinned: $isPinned)
            
            Spacer()
        }
        .frame(width: 340)
        .background(renderer.isPaused ? Color(red: 0.2, green: 0, blue: 0).opacity(0.9) : Color(white: 0.07).opacity(0.9))
        .clipShape(RoundedCornerShape(corners: [.topRight, .bottomRight], radius: 20))
        .overlay(
            RoundedCornerShape(corners: [.topRight, .bottomRight], radius: 20)
                .stroke(Color(white: 0.33), lineWidth: 2)
        )
        .shadow(radius: 10)
        .opacity(isVisible ? 1.0 : 0.0)
        .disabled(!isVisible)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .onHover { hovering in
            if !isPinned && !isShowingSaveSheet && !isShowingDeleteSheet {
                withAnimation {
                    isVisible = hovering
                }
            }
        }
    }
}

struct PresetPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    @State private var isShowingSaveSheet = false
    @State private var isShowingDeleteSheet = false


    var body: some View {
        HStack(spacing: 8) {
            Text("File:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth, alignment: .trailing)

            Menu {
                // 📁 File Actions
                Button("⬜️ New") { settings.selectPreset(PresetDefinitions.emptyPreset) }
                Button("🔀 Random") { settings.selectPreset(PresetDefinitions.randomPreset) }
                Divider()
                Button("💾 Save", action: { isShowingSaveSheet = true })
                Button("🗑 Delete", action: {
                    if !settings.selectedPreset.isBuiltIn {
                        isShowingDeleteSheet = true
                    }
                })
                .disabled(settings.selectedPreset.isBuiltIn)
                
                // ⭐ Built-in Presets
                if !PresetDefinitions.specialPresets.isEmpty {
                    Divider()
                    Menu("⭐ Presets") {
                        ForEach(PresetDefinitions.specialPresets, id: \.id) { preset in
                            Button(preset.name) { settings.selectPreset(preset) }
                        }
                    }
                }

                // 📂 User Presets
                if !settings.userPresets.isEmpty {
                    Divider()
                    Menu("📂 Mine") {
                        ForEach(settings.userPresets, id: \.id) { preset in
                            Button(preset.name) { settings.selectPreset(preset) }
                        }
                    }
                }
            } label: {
                Text(settings.selectedPreset.name)
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)
            .popover(
                isPresented: $isShowingSaveSheet,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                SavePresetSheet(isShowingSaveSheet: $isShowingSaveSheet, presetName: .constant(settings.selectedPreset.name))
            }
            .popover(
                isPresented: $isShowingDeleteSheet,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) {
                DeletePresetSheet(isShowingDeleteSheet: $isShowingDeleteSheet)
            }
        }
        .frame(width: pickerViewWidth)
    }
}

struct MarixPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Matrix:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth, alignment: .trailing)
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
        .frame(width: pickerViewWidth)
    }
}

struct DistributionPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Distribute:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth, alignment: .trailing)
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
        .frame(width: pickerViewWidth)
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

struct SpeciesPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer

    var body: some View {
        HStack(spacing: 0) {
            Text("Species:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth, alignment: .trailing)
            
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
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)

        }
        .frame(width: pickerViewWidth)
    }
}

struct ParticleCountPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer

    var body: some View {
        HStack(spacing: 0) {
            Text("Particles:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth, alignment: .trailing)
            
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
            .disabled(renderer.isPaused)
        }
        .frame(width: pickerViewWidth)
    }
}

struct SimulationSlidersView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    var body: some View {
        VStack(spacing: 10) {
            settingSlider(title: "Max Dist", setting: $settings.maxDistance)
            settingSlider(title: "Min Dist", setting: $settings.minDistance)
            settingSlider(title: "Beta", setting: $settings.beta)
            settingSlider(title: "Friction", setting: $settings.friction)
            settingSlider(title: "Repulsion", setting: $settings.repulsion)
            settingSlider(title: "World Size", setting: $settings.worldSize)
            settingSlider(title: "Point Size", setting: $settings.pointSize)
        }
    }
    
    private func settingSlider(title: String, setting: Binding<ConfigurableSetting>) -> some View {
        HStack {
            Text("\(title):").frame(width: 70, alignment: .trailing)
                .foregroundColor(labelColor)
            Text("\(setting.wrappedValue.value, specifier: setting.wrappedValue.format)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .frame(width: 35, alignment: .leading)
                .padding(.trailing, 3)
            Slider(value: setting.value, in: setting.wrappedValue.min...setting.wrappedValue.max, step: setting.wrappedValue.step)
                .frame(width: 166)
        }
        
        .padding(.horizontal, 16)
        .disabled(renderer.isPaused)
    }
}

struct LogoView: View {
    var body: some View {
        Image("particle-life-logo")
            .resizable()
            .scaledToFit()
            .opacity(0.7)
            .frame(width: 120)
    }
}

struct PhysicsSettingsView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    @State private var isExpanded = true

    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Physics Settings")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        .font(.title2)
                }
                .padding(6)
                .cornerRadius(8)
                .contentShape(Rectangle())
            }
            .frame(width: pickerViewWidth)

            if isExpanded {
                SimulationSlidersView(settings: settings, renderer: renderer)
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
}

struct FooterView: View {
    @ObservedObject var renderer: Renderer
    @Binding var isPinned: Bool
    
    var body: some View {
        HStack {
            
            Text(renderer.isPaused ? "PAUSED" : "FPS: \(renderer.fps)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(renderer.isPaused || renderer.fps < 30 ? .red : .green)

            Spacer()
            LogoView()
            Spacer()

            Text("v\(AppInfo.version)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .padding(.horizontal, 8)
        .frame(width: 300)
    }
}

struct SavePresetSheet: View {
    @Binding var isShowingSaveSheet: Bool
    @Binding var presetName: String
    @State private var showOverwriteAlert = false
    @State private var tempPresetName: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Preset Name")
                .font(.title2)
                .bold()

            TextField("Preset Name", text: $tempPresetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .padding(.horizontal, 10)
                .onSubmit {
                    handleSaveAttempt()
                }

            HStack {
                Button("Cancel") {
                    isShowingSaveSheet = false
                }
                .buttonStyle(.bordered)
                .frame(width: 120)

                Button("Save") {
                    handleSaveAttempt()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 120)
                .disabled(tempPresetName.isEmpty)
            }
            .padding(.top, 5)
        }
        .padding(15)
        .frame(width: 250)
        .alert("Preset Exists", isPresented: $showOverwriteAlert) {
            Button("Cancel", role: .cancel) {
                isShowingSaveSheet = true
            }
            Button("Replace") {
                savePreset(overwrite: true)
            }
        } message: {
            Text("A preset with this name already exists. Do you want to replace it?")
        }
        .onAppear {
            tempPresetName = presetName
        }
    }

    private func handleSaveAttempt() {
        let allPresets = SimulationSettings.shared.userPresets
        let builtInPresets = PresetDefinitions.getAllBuiltInPresets().map { $0.name }

        if builtInPresets.contains(tempPresetName) {
            Logger.log("Attempted to overwrite a built-in preset", level: .error)
            return
        }

        if allPresets.contains(where: { $0.name == tempPresetName }) {
            showOverwriteAlert = true
        } else {
            savePreset(overwrite: false)
        }
    }

    private func savePreset(overwrite: Bool) {
        if !tempPresetName.isEmpty {
            SimulationSettings.shared.saveCurrentPreset(named: tempPresetName,
                interactionMatrix: ParticleSystem.shared.interactionMatrix,
                replaceExisting: overwrite)
            
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
            Text("Delete Preset")
                .font(.title2)
                .bold()
            
            Text("Are you sure you want to delete **\(presetToDelete.name)**?")
                .multilineTextAlignment(.center)
                .font(.title3)
            
            HStack {
                Button("Cancel") {
                    isShowingDeleteSheet = false
                }
                .buttonStyle(.bordered)
                .frame(width: 120)
                
                Button("Delete") {
                    PresetManager.shared.deleteUserPreset(named: presetToDelete.name)
                    SimulationSettings.shared.userPresets = PresetManager.shared.getUserPresets()
                    SimulationSettings.shared.selectPreset(PresetDefinitions.getDefaultPreset())
                    isShowingDeleteSheet = false
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 120)
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
        .frame(width: 135, height: 30)
        .background(Color(red: 0.3, green: 0.3, blue: 0.3).opacity(0.85)) // Darker background
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .compositingGroup()
        .drawingGroup()
        .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1.0 : 0.6))
    }
}

struct CustomDivider: View {
    var body: some View {
        Divider()
            .background(Color(white: 0.33))
            .padding(.vertical, 4)
    }
}

#Preview {
    let mtkView = MTKView()
    let renderer = Renderer(mtkView: mtkView)
    
    NSHostingView(
        rootView: SimulationSettingsView(
            renderer: renderer
        )
    )
}
