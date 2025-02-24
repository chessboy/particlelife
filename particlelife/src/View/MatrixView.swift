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
    
    @ObservedObject var renderer: Renderer
        
    let speciesColors: [Color]

    var body: some View {
        
        InteractionMatrixGrid(
            isVisible: $isVisible,
            speciesColors: speciesColors,
            interactionMatrix: $interactionMatrix,
            hoveredCell: $hoveredCell,
            tooltipText: $tooltipText,
            tooltipPosition: $tooltipPosition,
            renderer: renderer
        )
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

struct InteractionMatrixGrid: View {
    @State private var lastMouseButton: Int = 0
    @Binding var isVisible: Bool
    
    let speciesColors: [Color]
    @Binding var interactionMatrix: [[Float]] // Allows modification
    @Binding var hoveredCell: (row: Int, col: Int)?
    @Binding var tooltipText: String
    @Binding var tooltipPosition: CGPoint
    
    @ObservedObject var renderer: Renderer
    
    private var spacing: CGFloat {
        let count = max(1, speciesColors.count)
        return max(3, 16 / CGFloat(count))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let speciesCount = speciesColors.count
            let totalWidth: CGFloat = geometry.size.width - CGFloat(speciesCount + 1) * spacing
            let cellSize = totalWidth / CGFloat(speciesCount + 1)
            
            VStack(spacing: spacing) {
                // Header row with species colors
                HStack(spacing: spacing) {
                    Color.clear.frame(width: cellSize, height: cellSize) // Placeholder for alignment
                    ForEach(speciesColors.indices, id: \.self) { index in
                        speciesColors[index]
                            .frame(width: cellSize, height: cellSize)
                            .clipShape(Circle())
                    }
                }
                .frame(height: cellSize)
                
                // Matrix rows with species color indicators
                LazyVStack(spacing: spacing) {
                    ForEach(interactionMatrix.indices, id: \.self) { row in
                        rowView(row: row, totalWidth: totalWidth, cellSize: cellSize)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func rowView(row: Int, totalWidth: CGFloat, cellSize: CGFloat) -> some View {
        LazyHStack(spacing: spacing) {
            // Species color indicator (aligned with header)
            if speciesColors.indices.contains(row) {
                speciesColors[row]
                    .frame(width: cellSize, height: cellSize) // Adjust size to match header
                    .clipShape(Circle())
            } else {
                Color.clear.frame(width: cellSize, height: cellSize) // Placeholder for alignment
            }
            
            // Matrix cells for this row
            ForEach(interactionMatrix[row].indices, id: \.self) { col in
                cellView(row: row, col: col, totalWidth: totalWidth, cellSize: cellSize)
            }
        }
        .frame(height: cellSize)
    }
    
    private func strokedRectangle(color: Color, lineWidth: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(color, lineWidth: lineWidth)
    }
    
    @ViewBuilder
    private func cellView(row: Int, col: Int, totalWidth: CGFloat, cellSize: CGFloat) -> some View {
        let value = interactionMatrix[row][col]
        
        RoundedRectangle(cornerRadius: 4)
            .fill(colorForValue(value))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                abs(value) < 2 ? strokedRectangle(color: Color.white.opacity(0.2), lineWidth: 1, cornerRadius: 4) : nil
            )
            .overlay(
                hoveredCell.map { hovered in
                    hovered == (row, col) ? strokedRectangle(color: Color.white, lineWidth: 2, cornerRadius: 4) : nil
                }
            )
            .onHover { isHovering in
                if isHovering {
                    hoveredCell = (row, col)
                    tooltipText = String(format: "%.2f", value)
                    tooltipPosition = computeTooltipPosition(row: row, col: col, totalWidth: totalWidth, cellSize: cellSize)
                } else {
                    hoveredCell = nil
                }
            }
            .onTapGesture {
                if let hovered = hoveredCell, !renderer.isPaused {
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
}

extension InteractionMatrixGrid {
    /// Cycles the matrix value to the next step in cycleValues
    private func cycleMatrixValue(row: Int, col: Int) {
        let cycleValues: [Float] = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]

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
    
    private func setMatrixValue(row: Int, col: Int, newValue: Float) {
        interactionMatrix[row][col] = newValue
        BufferManager.shared.updateInteractionBuffer(interactionMatrix: interactionMatrix)
        tooltipText = String(format: "%.2f", newValue)
        
        // update the current preset's matrix
        SimulationSettings.shared.selectedPreset = SimulationSettings.shared.selectedPreset.copy(withName: nil, newMatrixType: .custom(interactionMatrix))
    }
    
    private func computeTooltipPosition(row: Int, col: Int, totalWidth: CGFloat, cellSize: CGFloat) -> CGPoint {
        let xPadding: CGFloat = cellSize / 2 // center horizontally
        let yPadding: CGFloat = -16 // don't overlap the cell

        let y = CGFloat(row + 1) * (cellSize + spacing) + yPadding
        let x = CGFloat(col + 1) * (cellSize + spacing) + xPadding

        return CGPoint(x: x, y: y)
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

struct MatrixPreviewWrapper: View {
    @State private var n: Int
    @State private var matrix: [[Float]]
    @State private var isVisible: Bool = true
    let speciesColors: [Color]
    
    init(n: Int) {
        self._n = State(initialValue: n)
        self._matrix = State(initialValue: Array(repeating: Array(repeating: 0.0, count: n), count: n))
        let predefinedColors = Constants.speciesColors
        self.speciesColors = (0..<n).map { predefinedColors[$0 % predefinedColors.count] }
    }
    
    var body: some View {
        
        MatrixView(
            interactionMatrix: $matrix,
            isVisible: $isVisible,
            renderer: Renderer(),
            speciesColors: speciesColors
        )
        .frame(width: 300, height: 300)
        .background(Color.black)
    }
}

#Preview {
    MatrixPreviewWrapper(n: 3)
}
