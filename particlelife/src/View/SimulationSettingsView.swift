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
    @ObservedObject var simulationManager: SimulationManager
    
    @State private var isShowingSaveSheet = false
    @State private var isShowingDeleteSheet = false
    @State private var presetName: String = "New Preset"
    
    @State var isExpanded: Bool
    @State private var isCloseButtonHovered = false
    
    private let maxAllowedParticleCount: ParticleCount

    init(simulationManager: SimulationManager) {
        self.simulationManager = simulationManager

        let gpuCoreCount = SystemCapabilities.shared.gpuCoreCount
        let gpuType = SystemCapabilities.shared.gpuType
        maxAllowedParticleCount = ParticleCount.maxAllowedParticleCount(for: gpuCoreCount, gpuType: gpuType, allowExtra: true)
        isExpanded = UserSettings.shared.bool(forKey: UserSettingsKeys.showingPhysicsPane, defaultValue: false)
    }

    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .topLeading) {
                MatrixView(
                    matrix: $particleSystem.matrix,
                    speciesDistribution: $particleSystem.speciesDistribution,
                    simulationManager: simulationManager,
                    speciesColors: particleSystem.speciesColors

                )
                .frame(width: 300, height: 295)
                .padding(.top, 16)
                
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
                .offset(x: -3, y: 14)
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
                CustomDivider()
                PresetPickerView(settings: settings, simulationManager: simulationManager, isShowingSaveSheet: $isShowingSaveSheet, isShowingDeleteSheet: $isShowingDeleteSheet)
                SpeciesPickerView(settings: settings, simulationManager: simulationManager)
                MatrixPickerView(settings: settings, simulationManager: simulationManager)
                CustomDivider()
                ParticleCountPickerView(settings: settings, simulationManager: simulationManager, maxAllowedParticleCount: maxAllowedParticleCount)
                DistributionPickerView(settings: settings, simulationManager: simulationManager)
                CustomDivider()
                PalettePickerView(settings: settings, simulationManager: simulationManager)
                ColorEffectPickerView(settings: settings, simulationManager: simulationManager)
                CustomDivider()
            }
            .padding(.top, 15)
            
            // Controls: A little more room for clarity
            SimulationButtonsView(simulationManager: simulationManager)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            PhysicsSettingsView(settings: settings, simulationManager: simulationManager, isExpanded: $isExpanded)
            FooterView(simulationManager: simulationManager)
            
            Spacer()
        }
        .frame(width: 340, height: isExpanded ? 993 : 775)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .background(simulationManager.isPaused ? Color(red: 0.2, green: 0, blue: 0).opacity(0.9) : Color(white: 0.07).opacity(0.9))
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
    @ObservedObject var simulationManager: SimulationManager
    
    @Binding var isShowingSaveSheet: Bool
    @Binding var isShowingDeleteSheet: Bool
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
            .disabled(simulationManager.isPaused)
            .help("Use P key to select a random built-in preset")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    if !simulationManager.isPaused {
                        isHovered = hovering
                    }
                }
            }
            
            Text("File:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth - 31, alignment: .trailing)
            
            Menu {
                // New and Random
                Button {
                    ParticleSystem.shared.selectPreset(PresetDefinitions.emptyPreset)
                } label: {
                    HStack {
                        Image(systemName: SFSymbols.Name.new)
                        Text("New")
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button {
                    ParticleSystem.shared.selectPreset(PresetDefinitions.randomPreset)
                } label: {
                    HStack {
                        Image(systemName: SFSymbols.Name.dice)
                        Text("Random")
                    }
                }
                .keyboardShortcut("?", modifiers: .command)
                
                // Built-in Presets
                Divider()
                Menu {
                    if PresetDefinitions.specialPresets.isEmpty {
                        Text("None Stored").foregroundColor(.secondary) // Show placeholder
                    } else {
                        ForEach(PresetDefinitions.specialPresets, id: \.id) { preset in
                            Button(preset.name) { ParticleSystem.shared.selectPreset(preset) }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: SFSymbols.Name.presets)
                        Text("Presets")
                    }
                }
                
                // User Presets
                Menu {
                    if settings.userPresets.isEmpty {
                        Text("None Stored").foregroundColor(.secondary) // Show placeholder
                    } else {
                        ForEach(settings.userPresets, id: \.id) { preset in
                            Button(preset.name) { ParticleSystem.shared.selectPreset(preset) }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: SFSymbols.Name.stored)
                        Text("Mine")
                    }
                }
                
                // File IO
                Divider()
                Button(action: {
                    if !isShowingDeleteSheet {
                        isShowingSaveSheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: SFSymbols.Name.save)
                        Text("Save")
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button(action: {
                    if !settings.selectedPreset.isBuiltIn {
                        isShowingDeleteSheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: SFSymbols.Name.delete)
                        Text("Delete")
                    }
                }
                .disabled(settings.selectedPreset.isBuiltIn)
                
            } label: {
                Text(settings.selectedPreset.name)
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(simulationManager.isPaused)
            .onReceive(NotificationCenter.default.publisher(for: .saveTriggered)) { _ in
                Logger.log("received save notification: isShowingDeleteSheet: \(isShowingDeleteSheet)")
                if !isShowingDeleteSheet {
                    isShowingSaveSheet = true
                }
            }
            .sheet(isPresented: $isShowingSaveSheet) {
                SavePresetSheet(isShowingSaveSheet: $isShowingSaveSheet, presetName: .constant(settings.selectedPreset.name))
            }
            .sheet(isPresented: $isShowingDeleteSheet) {
                DeletePresetSheet(isShowingDeleteSheet: $isShowingDeleteSheet)
            }
        }
        .frame(width: pickerViewWidth)
    }
}

struct MatrixPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 0) {
            
            if settings.selectedPreset.matrixType.isRandom {
                Button(action: {
                    ParticleSystem.shared.respawn(shouldGenerateNewMatrix: true)
                }) {
                    Image(systemName: SFSymbols.Name.dice)
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                        .padding(2)
                        .background(isHovered ? Color.gray.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(simulationManager.isPaused)
                .help("Use M key to generate a new random matrix")
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if !simulationManager.isPaused {
                            isHovered = hovering
                        }
                    }
                }
            }
            
            Text("Matrix:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth - (settings.selectedPreset.matrixType.isRandom ? 20 : 0), alignment: .trailing)
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
            .disabled(simulationManager.isPaused)
        }
        .frame(width: pickerViewWidth)
    }
}

struct DistributionPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager
    
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
            .disabled(simulationManager.isPaused)
        }
        .frame(width: pickerViewWidth)
    }
}

struct PalettePickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager
    
    var body: some View {
        HStack(spacing: 0) {
            
            Text("Palette:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth, alignment: .trailing)
            
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
                ForEach(ColorPalette.allCases.indices, id: \.self) { index in
                    Text(ColorPalette.allCases[index].name).tag(index)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(simulationManager.isPaused)
        }
        .frame(width: pickerViewWidth)
    }
    
    private func updateSpeciesColors() {
        ParticleSystem.shared.updateSpeciesColors(
            speciesCount: SimulationSettings.shared.selectedPreset.speciesCount,
            colorOffset: SimulationSettings.shared.colorOffset,
            paletteIndex: SimulationSettings.shared.paletteIndex
        )
    }
}

struct ColorEffectPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager
    
    var body: some View {
        HStack(spacing: 0) {
            
            Text("Effect:")
                .foregroundColor(labelColor)
                .frame(width: pickerLabelWidth, alignment: .trailing)
            
            Picker("", selection: Binding(
                get: { settings.colorEffect },
                set: { newEffect in
                    if newEffect != settings.colorEffect {
                        settings.colorEffect = newEffect
                    }
                }
            )) {
                ForEach(ColorEffect.allCases, id: \.self) { effect in
                    Text(effect.displayName).tag(effect)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(simulationManager.isPaused)
        }
        .frame(width: pickerViewWidth)
    }
}

struct SimulationButtonsView: View {
    @ObservedObject var simulationManager: SimulationManager
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
            .disabled(simulationManager.isPaused)
            
            HoverButton(title: "Respawn", systemImage: SFSymbols.Name.respawn) {
                ParticleSystem.shared.respawn(shouldGenerateNewMatrix: false)
            }
            .disabled(simulationManager.isPaused)
        }
    }
}

struct SpeciesPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager
    
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
            .disabled(simulationManager.isPaused)
            
        }
        .frame(width: pickerViewWidth)
    }
}

struct ParticleCountPickerView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager

    var maxAllowedParticleCount: ParticleCount

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
                ForEach(ParticleCount.allCases.filter {
                    return $0 <= maxAllowedParticleCount
                }, id: \.self) { count in
                    Text(count.displayString)
                        .tag(count)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .disabled(simulationManager.isPaused)
        }
        .frame(width: pickerViewWidth)
    }
}

struct SimulationSlidersView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager
    
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
        .disabled(simulationManager.isPaused)
    }
}

struct LogoView: View {
    var body: some View {
        Image("particle-life-logo")
            .resizable()
            .scaledToFit()
            .opacity(0.7)
            .frame(width: SystemCapabilities.shared.gpuType == .dedicatedGPU ? 120 : 100)
    }
}

struct PhysicsSettingsView: View {
    @ObservedObject var settings: SimulationSettings
    @ObservedObject var simulationManager: SimulationManager
    @Binding var isExpanded: Bool
    @State private var isButtonHovered = false

    var body: some View {
        VStack {
            // Expand/collapse button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
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
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
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
            
            // Smooth Expand/Collapse - Always in View, Just Fades and Moves
            SimulationSlidersView(settings: settings, simulationManager: simulationManager)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .frame(height: isExpanded ? 216 : 0) // Animate Height
                .opacity(isExpanded ? 1 : 0)        // Animate Opacity
                .offset(y: isExpanded ? 0 : -10)    // Smooth Collapse Movement
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
                .clipped() // Prevents overflow
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
}

struct SmoothHeightModifier: AnimatableModifier {
    var targetHeight: CGFloat
    var animatableData: CGFloat {
        get { targetHeight }
        set { targetHeight = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .frame(height: targetHeight)
            .clipped()
    }
}

struct FooterView: View {
    @State private var fps: Int = 0
    @ObservedObject var simulationManager: SimulationManager
    @State private var isHovered = false

    var body: some View {
        HStack {
            
            Text(simulationManager.isPaused ? "PAUSED" : "FPS: \(fps)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(simulationManager.isPaused || fps < 30 ? .red : .green)
            
            Spacer()
            LogoView()
            Spacer()
            
            Text("v\(AppInfo.version)(\(AppInfo.build))")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            
            if SystemCapabilities.shared.gpuType != .dedicatedGPU {
                Button(action: {
                    NotificationCenter.default.post(name: .lowPerformanceWarning, object: nil)
                }) {
                    Image(systemName: SFSymbols.Name.warning)
                        .foregroundColor(.yellow)
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
//                .onAppear() {
//                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
//                        guard isShowingSaveSheet else { return event }
//                        if event.keyCode == 36, !tempPresetName.isEmpty { // 36 = Return/Enter
//                            handleSaveAttempt()
//                            return nil // Swallow the event to prevent propagation
//                            
//                        } else if event.keyCode == 53 { // 52 = ESC
//                            isShowingSaveSheet = false
//                            return nil // Swallow the event to prevent propagation
//                        }
//
//                        return event
//                    }
//                }
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
                speciesDistribution: ParticleSystem.shared.speciesDistribution,
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
                .onAppear() {
//                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
//                        guard isShowingDeleteSheet else { return event }
//                        if event.keyCode == 53 { // 52 = ESC
//                            isShowingDeleteSheet = false
//                            return nil // Swallow the event to prevent propagation
//                        }
//
//                        return event
//                    }
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

struct CustomDivider: View {
    var body: some View {
        Divider()
            .background(Color(white: 0.2))
            .padding(.vertical, 4)
            .frame(width: 290)
    }
}

#Preview {
    NSHostingView(
        rootView: SimulationSettingsView(
            simulationManager: SimulationManager()
        )
    )
}
