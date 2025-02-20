//
//  MatrixView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI

struct MatrixView: View {
    @Binding var interactionMatrix: [[Float]]
    @Binding var isVisible: Bool
    
    @State private var hoveredCell: (row: Int, col: Int)? = nil
    @State private var tooltipPosition: CGPoint = .zero
    @State private var tooltipText: String = ""
    
    let speciesColors: [Color]

    var body: some View {
        VStack {
            SpeciesHeaderRow(speciesColors: speciesColors)
            
            VStack {
                InteractionMatrixGrid(
                    isVisible: $isVisible,
                    speciesColors: speciesColors,
                    interactionMatrix: $interactionMatrix,
                    hoveredCell: $hoveredCell,
                    tooltipText: $tooltipText,
                    tooltipPosition: $tooltipPosition
                )
            }
        }
        .frame(width: 240, height: CGFloat(interactionMatrix.count + 1) * 22 - 4)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(Color.black)
        .cornerRadius(8)
        .overlay(tooltipView, alignment: .topLeading)
    }
    
    // Floating tooltip positioned dynamically
    @ViewBuilder
    private var tooltipView: some View {
        if hoveredCell != nil {
            TooltipView(text: tooltipText)
                .position(tooltipPosition)
        }
    }
}

struct SpeciesHeaderRow: View {
    let speciesColors: [Color]

    var body: some View {
        HStack(spacing: 2) {
            Color.clear.frame(width: 20, height: 20) // Placeholder for top-left corner
            ForEach(speciesColors.indices, id: \.self) { index in
                speciesColors[index]
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }
        }
    }
}

struct InteractionMatrixGrid: View {
    @State private var lastMouseButton: Int = 0
    @Binding var isVisible: Bool

    let speciesColors: [Color]
    @Binding var interactionMatrix: [[Float]] // Allows modification
    @Binding var hoveredCell: (row: Int, col: Int)?
    @Binding var tooltipText: String
    @Binding var tooltipPosition: CGPoint
    
    var body: some View {
        LazyVStack(spacing: 2) {
            ForEach(interactionMatrix.indices, id: \.self) { row in
                rowView(row: row)
            }
        }
    }
    
    /// Extracted row rendering logic into a separate function
    @ViewBuilder
    private func rowView(row: Int) -> some View {
        LazyHStack(spacing: 2) {
            // Ensure index is within range before accessing speciesColors
            if row < speciesColors.count {
                speciesColors[row]
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            } else {
                Color.gray // Fallback for missing species colors
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
            }
            
            // Matrix cells for this row
            ForEach(interactionMatrix[row].indices, id: \.self) { col in
                cellView(row: row, col: col)
            }
        }
    }
    /// Extracted cell rendering logic into a separate function
    @ViewBuilder
    private func cellView(row: Int, col: Int) -> some View {
        let value = interactionMatrix[row][col]
        
        Rectangle()
            .fill(colorForValue(value))
            .frame(width: 20, height: 20)
            .overlay(
                hoveredCell.map { hovered in
                    hovered == (row, col) ? Rectangle().stroke(Color.white, lineWidth: 2) : nil
                }
            )
            .onHover { isHovering in
                if isHovering {
                    hoveredCell = (row, col)
                    tooltipText = String(format: "%.2f", value)
                    tooltipPosition = computeTooltipPosition(row: row, col: col)
                } else {
                    hoveredCell = nil
                }
            }
            .onTapGesture {
                if let hovered = hoveredCell {
                    cycleMatrixValue(row: hovered.row, col: hovered.col)
                }
            }
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
                    guard isVisible else { return event }

                    let scrollSensitivity: Float = 0.001  // Adjust sensitivity (lower = slower)
                    let deltaY = Float(event.scrollingDeltaY) * scrollSensitivity

                    if let hovered = hoveredCell {
                        let adjustment = max(-0.1, min(0.1, deltaY)) // Prevent large jumps
                        adjustMatrixValue(row: hovered.row, col: hovered.col, amount: adjustment)
                    }

                    return event
                }
            }
    }
    
    let cycleValues: [Float] = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]
    
    /// Cycles the matrix value to the next step in cycleValues
    private func cycleMatrixValue(row: Int, col: Int) {
        guard row >= 0, col >= 0, row < interactionMatrix.count, col < interactionMatrix[row].count else { return }

        let currentValue = interactionMatrix[row][col]
        
        // Find the closest cycle value
        if let index = cycleValues.enumerated().min(by: { abs($0.1 - currentValue) < abs($1.1 - currentValue) })?.offset {
            let nextIndex = (index + 1) % cycleValues.count
            let newValue = cycleValues[nextIndex]
            
            setMatrixValue(row: row, col:  col, newValue: newValue)
        }
    }
        
    /// Adjusts the interaction matrix value
    private func adjustMatrixValue(row: Int, col: Int, amount: Float) {
        guard row >= 0, col >= 0, row < interactionMatrix.count, col < interactionMatrix[row].count else { return }
        
        let oldValue = interactionMatrix[row][col]
        var newValue = oldValue + amount

        //newValue = round(newValue * 10) / 10 // round to nearest tenth
        newValue = max(-1, min(1, newValue))

        setMatrixValue(row: row, col: col, newValue: newValue)
    }
    
//    private func setMatrixValue(row: Int, col: Int, newValue: Float) {
//        interactionMatrix[row][col] = newValue
//        BufferManager.shared.updateInteractionBuffer(interactionMatrix: interactionMatrix)
//        tooltipText = String(format: "%.2f", newValue)
//    }
    
    private func setMatrixValue(row: Int, col: Int, newValue: Float) {
        interactionMatrix[row][col] = newValue
        BufferManager.shared.updateInteractionBuffer(interactionMatrix: interactionMatrix)

        // Always store as `.custom`, regardless of starting type
        SimulationSettings.shared.selectedPreset = SimulationPreset(
            name: SimulationSettings.shared.selectedPreset.name,
            numSpecies: SimulationSettings.shared.selectedPreset.numSpecies,
            numParticles: SimulationSettings.shared.selectedPreset.numParticles,
            forceMatrixType: .custom(interactionMatrix), // Always persist as custom
            distributionType: SimulationSettings.shared.selectedPreset.distributionType,
            maxDistance: SimulationSettings.shared.selectedPreset.maxDistance,
            minDistance: SimulationSettings.shared.selectedPreset.minDistance,
            beta: SimulationSettings.shared.selectedPreset.beta,
            friction: SimulationSettings.shared.selectedPreset.friction,
            repulsion: SimulationSettings.shared.selectedPreset.repulsion,
            pointSize: SimulationSettings.shared.selectedPreset.pointSize,
            worldSize: SimulationSettings.shared.selectedPreset.worldSize
        )

        tooltipText = String(format: "%.2f", newValue)
    }
    
    private func computeTooltipPosition(row: Int, col: Int) -> CGPoint {
        guard speciesColors.count > 0 else { return .zero }
        
        let cellSize: CGFloat = 22
        let maxViewWidth: CGFloat = 240
        let gridWidth: CGFloat = CGFloat(speciesColors.count) * cellSize
        let padding = (maxViewWidth - gridWidth) / 2
        let xOffset = padding + CGFloat(col - 1) * cellSize + (cellSize / 2) + 36
        
        let yOffset: CGFloat = CGFloat(row) * cellSize + 20
        
        return CGPoint(x: xOffset, y: yOffset)
    }
    
    /// Determines color based on interaction value
    func colorForValue(_ value: Float) -> Color {
        if value > 0 {
            return Color(hue: 1/3, saturation: 1.0, brightness: 0.2 + 0.8 * Double(value)) // 🟢 Green for attraction
        } else if value < 0 {
            return Color(hue: 0, saturation: 1.0, brightness: 0.2 + 0.8 * Double(-value)) // 🔴 Red for repulsion
        } else {
            return .black // Neutral (0) is black
        }
    }
}
