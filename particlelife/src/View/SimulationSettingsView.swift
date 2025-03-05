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
    
    @State private var isShowingSaveSheet = false
    @State private var isShowingDeleteSheet = false
    @State private var presetName: String = "New Preset"
    
    @State private var isExpanded = true
    @State private var isCloseButtonHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .topLeading) {
                MatrixView(
                    matrix: $particleSystem.matrix,
                    renderer: renderer,
                    speciesColors: particleSystem.speciesColors
                )
                .frame(width: 300, height: 300)
                .padding(.top, 10)
                
                // Close Button in the Empty Top-Left Space
                Button(action: {
                    Logger.log("Close button tapped", level: .debug)
                    NotificationCenter.default.post(name: .closeSettingsPanel, object: nil)
                }) {
                    Image(systemName: SFSymbols.Name.close)
                        .foregroundColor(isCloseButtonHovered ? .white : .gray)
                        .font(.system(size: 16))
                        .padding(6)
                        .background(isCloseButtonHovered ? Color.gray.opacity(0.3) : Color.black)
                        .clipShape(Circle())
                }
                .offset(x: -3, y: 7)
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCloseButtonHovered = hovering
                    }
                }
                .help("Use Tab key to toggle settings")  // Native macOS tooltip
            }
            
            // Preset, Matrix, Distribution: Grouped neatly
            VStack(spacing: 12) {
                PresetPickerView(settings: settings, renderer: renderer)
                SpeciesPickerView(settings: settings, renderer: renderer)
                MatrixPickerView(settings: settings, renderer: renderer)
                ParticleCountPickerView(settings: settings, renderer: renderer)
                DistributionPickerView(settings: settings, renderer: renderer)
                PalettePickerView(settings: settings, renderer: renderer)
            }
            .padding(.top, 15)
            
            // Controls: A little more room for clarity
            SimulationButtonsView(renderer: renderer)
                .padding(.top, 20)
                .padding(.bottom, 8)
            
            PhysicsSettingsView(settings: settings, renderer: renderer)
            FooterView(renderer: renderer)
            
            Spacer()
        }
        .frame(width: 340)
        .background(renderer.isPaused ? Color(red: 0.2, green: 0, blue: 0)/*.opacity(0.9)*/ : Color(white: 0.07)/*.opacity(0.9)*/)
        .clipShape(RoundedCornerShape(corners: [.topRight, .bottomRight], radius: 20))
        .overlay(
            RoundedCornerShape(corners: [.topRight, .bottomRight], radius: 20)
                .stroke(Color(white: 0.33), lineWidth: 1.5)
        )
        .shadow(radius: 10)
    }
}

struct PresetPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    
    @State private var isShowingSaveSheet = false
    @State private var isShowingDeleteSheet = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: {
                ParticleSystem.shared.selectRandomBuiltInPreset()
            }) {
                Image(systemName: SFSymbols.Name.randomize)
                    .foregroundColor(isHovered ? .white : Color(white: 0.8))
                    .font(.system(size: 14))
                    .padding(2)
                    .background(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .help("Use P key to select a random built-in preset")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            Text("File:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth - 31, alignment: .trailing)
            
            Menu {
                // 􀚈 New and random
                Button("\(SFSymbols.Symbol.new)  New") { ParticleSystem.shared.selectPreset(PresetDefinitions.emptyPreset) }
                Button("\(SFSymbols.Symbol.random)  Random") { ParticleSystem.shared.selectPreset(PresetDefinitions.randomPreset) }
                
                // 􀋃 Built-in Presets
                Divider()
                Menu("\(SFSymbols.Symbol.presets)  Presets") {
                    if PresetDefinitions.specialPresets.isEmpty {
                        Text("None Stored").foregroundColor(.secondary) // Show placeholder
                    } else {
                        ForEach(PresetDefinitions.specialPresets, id: \.id) { preset in
                            Button(preset.name) { ParticleSystem.shared.selectPreset(preset) }
                        }
                    }
                }
                
                // 􀈖 User Presets
                Menu("\(SFSymbols.Symbol.stored)  Mine") {
                    if settings.userPresets.isEmpty {
                        Text("None Stored").foregroundColor(.secondary) // Show placeholder
                    } else {
                        ForEach(settings.userPresets, id: \.id) { preset in
                            Button(preset.name) { ParticleSystem.shared.selectPreset(preset) }
                        }
                    }
                }
                
                // 􀈸 File IO
                Divider()
                Button("\(SFSymbols.Symbol.save)  Save", action: {
                    isShowingSaveSheet = true
                }).keyboardShortcut("s", modifiers: .command)
                
                Button("\(SFSymbols.Symbol.delete)  Delete", action: {
                    if !settings.selectedPreset.isBuiltIn {
                        isShowingDeleteSheet = true
                    }
                })
                .disabled(settings.selectedPreset.isBuiltIn)
                
            } label: {
                Text(settings.selectedPreset.name)
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)
            .onReceive(NotificationCenter.default.publisher(for: .saveTriggered)) { _ in
                Logger.log("received save notification")
                isShowingSaveSheet = true
            }
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

struct MatrixPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            
            if settings.selectedPreset.matrixType.isRandom {
                Button(action: {
                    ParticleSystem.shared.respawn(shouldGenerateNewMatrix: true)
                }) {
                    Image(systemName: SFSymbols.Name.dice)
                        .foregroundColor(isHovered ? .white : Color(white: 0.8))
                        .font(.system(size: 14))
                        .padding(2)
                        .background(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("Use M key to generate a new random matrix")
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
            } else {
                Rectangle()
                    .foregroundColor(Color.clear)
                    .frame(width: 23, height: 10)
            }
            
            Text("Matrix:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth - 23, alignment: .trailing)
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

struct PalettePickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            
            Button(action: {
                // for now we only support 0 (no effect) & 1 (texturizing effect)
                SimulationSettings.shared.toggleColorEffect()
            }) {
                Image(systemName: SFSymbols.Name.colorEffect)
                    .foregroundColor(SimulationSettings.shared.colorEffectIndex == 0 ? .white : .yellow)
                    .font(.system(size: 14))
                    .padding(2)
                    .background(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .help("Use T key to toggle color effect")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            
            Text("Palette:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth - 20, alignment: .trailing)
            
            Picker("", selection: Binding(
                get: { settings.paletteIndex },
                set: { newIndex in
                    if newIndex != settings.paletteIndex {
                        settings.paletteIndex = newIndex
                        UserSettings.shared.set(newIndex, forKey: UserSettingsKeys.colorPaletteIndex)
                        updateSpeciesColors()
                    }
                }
            )) {
                ForEach(SpeciesPalette.allCases.indices, id: \.self) { index in
                    Text(SpeciesPalette.allCases[index].name).tag(index)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(renderer.isPaused)
        }
        .frame(width: pickerViewWidth)
    }
    
    private func updateSpeciesColors() {
        ParticleSystem.shared.updateSpeciesColors(
            speciesCount: SimulationSettings.shared.selectedPreset.speciesCount,
            speciesColorOffset: SimulationSettings.shared.speciesColorOffset,
            paletteIndex: SimulationSettings.shared.paletteIndex
        )
    }
}

struct SimulationButtonsView: View {
    @ObservedObject var renderer: Renderer
    @State private var isResetHovered = false
    @State private var isRespawnHovered = false
    
    var body: some View {
        
        HStack(spacing: 16) {
            HoverButton(title: "Reset", systemImage: SFSymbols.Name.reset) {
                let commandDown = NSEvent.modifierFlags.contains(.command)
                if commandDown {
                    ParticleSystem.shared.dumpCurrentPresetAsJson()
                }
                else {
                    ParticleSystem.shared.selectPreset(SimulationSettings.shared.selectedPreset)
                }
            }
            
            HoverButton(title: "Respawn", systemImage: SFSymbols.Name.respawn) {
                renderer.respawnParticles()
            }
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
                ForEach(ParticleCount.allCases.filter { SystemCapabilities.isRunningOnProperGPU || $0 <= .maxGimpedCount }, id: \.self) { count in
                    Text(count.displayString)
                        .tag(count)
                        .foregroundColor(count.rawValue > ParticleCount.k20.rawValue && !SystemCapabilities.isRunningOnProperGPU ? .gray : .primary)
                        .opacity(count.rawValue > ParticleCount.k20.rawValue && !SystemCapabilities.isRunningOnProperGPU ? 0.5 : 1.0)
                        .disabled(count.rawValue > ParticleCount.k20.rawValue && !SystemCapabilities.isRunningOnProperGPU)
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
                .onTapGesture {
                    setting.wrappedValue.returnToDefault()
                }
            Slider(value: setting.value, in: setting.wrappedValue.min...setting.wrappedValue.max, step: setting.wrappedValue.step)
                .frame(width: 166)
        }
        
        .padding(.horizontal, 16)
        .disabled(renderer.isPaused)
    }
}

struct LogoView: View {
    
    @State private var hovering = false // Track hover state
    
    var body: some View {
        Image("particle-life-logo")
            .resizable()
            .scaledToFit()
            .opacity(hovering ? 1.0 : 0.7)
            .frame(width: SystemCapabilities.isRunningOnProperGPU ? 120 : 100)
            .scaleEffect(hovering ? 1.15 : 1.0) // Scale on hover
            .animation(.easeInOut(duration: 0.15), value: hovering)
            .onTapGesture {
                openGitHubRepo()
            }
            .onHover { isHovering in
                hovering = isHovering
            }
    }
    
    private func openGitHubRepo() {
        if let url = URL(string: "https://github.com/chessboy/particlelife") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct PhysicsSettingsView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var renderer: Renderer
    @State private var isExpanded: Bool = UserSettings.shared.bool(forKey: UserSettingsKeys.showingPhysicsPane, defaultValue: true)
    @State private var isButtonHovered = false
    
    var body: some View {
        VStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                    UserSettings.shared.set(isExpanded, forKey: UserSettingsKeys.showingPhysicsPane)
                }
            }) {
                HStack {
                    Text("Physics Settings")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                        .font(.title2)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isButtonHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isButtonHovered = hovering
                }
            }
            .contentShape(Rectangle())
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
    @State private var fps: Int = 0
    @ObservedObject var renderer: Renderer
    @State private var isHovered = false

    var body: some View {
        HStack {
            
            Text(renderer.isPaused ? "PAUSED" : "FPS: \(fps)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(renderer.isPaused || fps < 30 ? .red : .green)
            
            Spacer()
            LogoView()
            Spacer()
            
            Text("v\(AppInfo.version)(\(AppInfo.build))")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            
            if !SystemCapabilities.isRunningOnProperGPU {
                Button(action: {
                    NotificationCenter.default.post(name: .lowPerformanceWarning, object: nil)
                }) {
                    Image(systemName: SFSymbols.Name.warning)
                        .foregroundColor(SimulationSettings.shared.colorEffectIndex == 0 ? .white : .yellow)
                        .font(.system(size: 14))
                        .padding(2)
                        .background(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovered = hovering
                    }
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .padding(.horizontal, 8)
        .frame(width: 300)
        .onAppear {
            NotificationCenter.default.addObserver(forName: .fpsDidUpdate, object: nil, queue: .main) { notification in
                if let newFPS = notification.userInfo?["fps"] as? Int {
                    self.fps = newFPS
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .fpsDidUpdate, object: nil)
        }
    }
}

struct SavePresetSheet: View {
    @Binding var isShowingSaveSheet: Bool
    @Binding var presetName: String
    
    @State private var showOverwriteAlert = false
    @State private var tempPresetName: String = ""
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Save Preset")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
            TextField("Enter preset name", text: $tempPresetName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 220)
                .padding(.horizontal, 8)
                .focused($isTextFieldFocused)
                .onSubmit {
                    handleSaveAttempt()
                }
            HStack(spacing: 12) {
                Button("Cancel") {
                    isShowingSaveSheet = false
                }
                .buttonStyle(.bordered)
                .frame(width: 100)
                
                Button("Save") {
                    handleSaveAttempt()
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 100)
                .disabled(tempPresetName.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .frame(width: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
        .onAppear {
            tempPresetName = presetName
            isTextFieldFocused = true  // Autofocus
        }
        .onExitCommand {
            isShowingSaveSheet = false  // Escape key to close
        }
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
            isTextFieldFocused = true  // Focus text field
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Select all text after a short delay to ensure the field is ready
                isTextFieldFocused = true
            }
        }
    }
    
    private func handleSaveAttempt() {
        let allPresets = SimulationSettings.shared.userPresets
        
        if allPresets.contains(where: { $0.name == tempPresetName }) {
            showOverwriteAlert = true
        } else {
            savePreset(overwrite: false)
        }
    }
    
    private func savePreset(overwrite: Bool) {
        if !tempPresetName.isEmpty {
            SimulationSettings.shared.saveCurrentPreset(
                named: tempPresetName,
                matrix: ParticleSystem.shared.matrix,
                replaceExisting: overwrite
            )
            
            presetName = "Untitled"
            isShowingSaveSheet = false
        }
    }
}

struct DeletePresetSheet: View {
    @Binding var isShowingDeleteSheet: Bool
    
    let presetToDelete = SimulationSettings.shared.selectedPreset
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Delete Preset")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 5)
            
            Text("Are you sure you want to delete **\(presetToDelete.name)**?")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    isShowingDeleteSheet = false
                }
                .buttonStyle(.bordered)
                .frame(width: 100)
                
                Button("Delete") {
                    PresetManager.shared.deleteUserPreset(named: presetToDelete.name)
                    SimulationSettings.shared.userPresets = PresetManager.shared.getUserPresets()
                    ParticleSystem.shared.selectPreset(PresetDefinitions.getDefaultPreset())
                    isShowingDeleteSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .frame(width: 100)
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8)
        .onExitCommand {
            isShowingDeleteSheet = false  // Escape key closes it
        }
    }
}

struct HoverButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 16, weight: .medium))
                .frame(minWidth: 100)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.08)) // Slight brightness increase on hover
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaleEffect(isHovered ? 1.05 : 1.0) // Slight scale-up effect on hover
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        
        .buttonStyle(PlainButtonStyle())
        
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    let mtkView = MTKView()
    let renderer = Renderer(metalView: mtkView, fpsMonitor: FPSMonitor())
    
    NSHostingView(
        rootView: SimulationSettingsView(
            renderer: renderer
        )
    )
}
