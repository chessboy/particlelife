//
//  MatrixView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI

struct SelectedCell: Identifiable, Equatable {
    let id = UUID()
    let row: Int
    let col: Int

    static func == (lhs: SelectedCell, rhs: SelectedCell) -> Bool {
        return lhs.row == rhs.row && lhs.col == rhs.col
    }
}

struct MatrixView: View {
        
    @Binding var matrix: [[Float]]
    
    @State private var hoveredCell: (row: Int, col: Int)? = nil
    @State private var tooltipPosition: CGPoint? = nil
    @State private var tooltipText: String = ""
    @State private var selectedCell: SelectedCell? = nil
    @State private var sliderPosition: UnitPoint = .zero
    @State private var sliderValue: Float = 0.0
    
    @ObservedObject var renderer: Renderer
        
    let speciesColors: [Color]
    
    var body: some View {
        VStack {
            ZStack {
                
                MatrixGrid(
                    speciesColors: speciesColors,
                    matrix: $matrix,
                    hoveredCell: $hoveredCell,
                    tooltipText: $tooltipText,
                    tooltipPosition: $tooltipPosition,
                    selectedCell: $selectedCell,
                    sliderPosition: $sliderPosition,
                    sliderValue: $sliderValue,
                    renderer: renderer
                )
                .overlay(tooltipView, alignment: .topLeading)
                .popover(
                    item: $selectedCell,
                    attachmentAnchor: .point(sliderPosition),
                    arrowEdge: .top
                ) { selected in
                    SliderPopupView(
                        value: $sliderValue,
                        onValueChange: { newValue in
                            if selectedCell == selected {
                                setMatrixValue(row: selected.row, col: selected.col, newValue: newValue)
                            }
                        },
                        onDismiss: {
                            clearSelection()
                        }
                    )
                }
                .onChange(of: selectedCell) { oldValue, newValue in
                    if let newValue = newValue {
                        hoveredCell = (newValue.row, newValue.col) // Ensure the outline is applied immediately
                    } else {
                        hoveredCell = nil
                    }
                }
                .onAppear {
                    NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                        if event.keyCode == 53 || event.keyCode == 36 || event.keyCode == 76 {
                            // 53 = ESC, 36 = Return, 76 = Enter
                            clearSelection()
                            return nil
                        }
                        return event
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: matrix)
        }
    }
    
    func clearSelection() {
        guard selectedCell != nil else { return }
        selectedCell = nil
        hoveredCell = nil
    }

    // Floating tooltip positioned dynamically
    @ViewBuilder
    private var tooltipView: some View {
        if hoveredCell != nil, selectedCell == nil, let tooltipPosition = tooltipPosition {
            TooltipView(text: tooltipText, style: .fill)
                .position(tooltipPosition)
        }
    }
        
    private func setMatrixValue(row: Int, col: Int, newValue: Float) {
        matrix[row][col] = newValue
        BufferManager.shared.updateMatrixBuffer(matrix: matrix)
        tooltipText = newValue.formattedTo2Places

        // update the current preset's matrix
        SimulationSettings.shared.selectedPreset = SimulationSettings.shared.selectedPreset.copy(withName: nil, newMatrixType: .custom(matrix))
    }
}

struct MatrixGrid: View {
    
    static let switchToTooltips = 3
    
    let speciesColors: [Color]
    
    @Binding var matrix: [[Float]]
    
    @Binding var hoveredCell: (row: Int, col: Int)?
    @Binding var tooltipText: String
    @Binding var tooltipPosition: CGPoint?
    
    @Binding var selectedCell: SelectedCell?
    @Binding var sliderPosition: UnitPoint
    @Binding var sliderValue: Float
    
    @ObservedObject var renderer: Renderer

    @State private var lastMouseButton: Int = 0
    @State private var hoverIndex: Int? = nil
    
    private var spacing: CGFloat {
        let count = max(1, speciesColors.count)
        return max(3, 16 / CGFloat(count))
    }
    
    private var cornerRadiusMatrix: CGFloat {
        let count = max(1, speciesColors.count)
        return max(2, 16 / CGFloat(count))
    }
    
    private var circleScale: CGFloat {
        let count = max(1, min(9, speciesColors.count))
        return 0.7 + (CGFloat(count - 1) / 8) * 0.15 // 0.7 to 0.85
    }
    
    // Helper function for overlaying arrows
    @ViewBuilder
    private func arrowOverlay(for index: Int, cellSize: CGFloat) -> some View {
        if hoverIndex == index {
            let arrowName = (index == 0) ? "arrow.right" : "arrow.left"
            Image(systemName: arrowName)
                .resizable()
                .scaledToFit()
                .frame(width: cellSize * circleScale * 0.7, height: cellSize * circleScale * 0.7)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
                .help("Use Page Up and Down to cycle through colors in this palette")  // Native macOS tooltip

        }
    }
    
    // Helper function for scale effect
    private func scaleEffectForIndex(_ index: Int) -> CGFloat {
        (index == 0 || index == speciesColors.count - 1) && hoverIndex == index ? 1.15 : 1.0
    }
    
    var body: some View {
        GeometryReader { geometry in
            let speciesCount = max(1, matrix.count)
            let totalWidth = max(10, geometry.size.width - CGFloat(speciesCount + 1) * spacing)
            let cellSize = max(5, totalWidth / CGFloat(speciesCount + 1))
            
            VStack(spacing: spacing) {
                // Header row with species colors
                HStack(spacing: spacing) {
                    Color.clear.frame(width: cellSize, height: cellSize) // Placeholder for alignment
                    ForEach(speciesColors.indices, id: \.self) { index in
                        ShadedCircleView(color: speciesColors[index], cellSize: cellSize, circleScale: circleScale)
                            .overlay(arrowOverlay(for: index, cellSize: cellSize))
                            .scaleEffect((index == 0 || index == speciesColors.count - 1) && hoverIndex == index ? 1.15 : 1.0) // Slight pop effect
                            .animation(.easeInOut(duration: 0.2), value: hoverIndex)
                            .onHover { hovering in
                                if hovering && (index == 0 || index == speciesColors.count - 1) {
                                    hoverIndex = index
                                } else if hoverIndex == index {
                                    hoverIndex = nil
                                }
                            }
                            .onTapGesture {
                                if index == 0 {
                                    ParticleSystem.shared.incrementSpeciesColorOffset()
                                } else if index == speciesColors.count - 1 {
                                    ParticleSystem.shared.decrementSpeciesColorOffset()
                                }
                            }
                    }
                }
                .frame(height: cellSize)
                
                // Matrix rows with species color indicators
                VStack(spacing: spacing) {
                    ForEach(matrix.indices, id: \.self) { row in
                        rowView(row: row, totalWidth: totalWidth, cellSize: cellSize)
                    }
                }
            }
        }
    }
        
    @ViewBuilder
    private func rowView(row: Int, totalWidth: CGFloat, cellSize: CGFloat) -> some View {
        HStack(spacing: spacing) {
            // Species color indicator (aligned with header)
            if speciesColors.indices.contains(row) {
                ShadedCircleView(color: speciesColors[row], cellSize: cellSize, circleScale: circleScale)
            } else {
                Color.clear.frame(width: cellSize, height: cellSize) // Placeholder for alignment
            }
            // Matrix cells for this row
            ForEach(matrix[row].indices, id: \.self) { col in
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
        let value = matrix[row][col]
        
        RoundedRectangle(cornerRadius: cornerRadiusMatrix)
            .fill(colorForValue(value))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                abs(value) < 2 ? strokedRectangle(color: Color.white.opacity(0.2), lineWidth: 1, cornerRadius: cornerRadiusMatrix) : nil
            )
            .overlay(
                hoveredCell.map { hovered in
                    hovered == (row, col) ? strokedRectangle(color: Color.white.opacity(0.85), lineWidth: 2, cornerRadius: cornerRadiusMatrix) : nil
                }
            )
            .overlay(valueOverlay(value: value))
            .animation(.easeInOut(duration: 0.3), value: value)
            .onHover { isHovering in
                handleHover(isHovering: isHovering, row: row, col: col, value: value, cellSize: cellSize)
            }
            .onTapGesture {
                handleTap(row: row, col: col, value: value, cellSize: cellSize)
            }
    }
    
    @ViewBuilder
    private func valueOverlay(value: Float) -> some View {
        let shouldShow = speciesColors.count <= MatrixGrid.switchToTooltips
        
        TooltipView(text: value.formattedTo2Places, style: .shadow)
            .opacity(shouldShow ? 1 : 0)
            .animation(.smooth(duration: 0.3), value: shouldShow)
    }
    
    private func handleTap(row: Int, col: Int, value: Float, cellSize: CGFloat) {
        guard !renderer.isPaused else { return }
        
        if selectedCell == nil {
            DispatchQueue.main.async {
                selectedCell = SelectedCell(row: row, col: col)
                sliderValue = value
                sliderPosition = computeSliderPosition(
                    row: row, col: col,
                    cellSize: cellSize,
                    speciesCount: max(1, speciesColors.count)
                )
            }
        }
    }
    
    private func handleHover(isHovering: Bool, row: Int, col: Int, value: Float, cellSize: CGFloat) {
        guard selectedCell == nil else { return } // Don't reset hover state if a cell is selected
        
        if isHovering {
            hoveredCell = (row, col)
            
            if speciesColors.count > MatrixGrid.switchToTooltips {
                tooltipText = value.formattedTo2Places
                tooltipPosition = computeTooltipPosition(row: row, col: col, cellSize: cellSize)
            } else {
                // Fully suppress tooltip while keeping hover effect
                tooltipText = ""
                tooltipPosition = nil
            }
        } else if let hovered = hoveredCell, hovered == (row, col) {
            hoveredCell = nil
        }
    }
}

extension MatrixGrid {
    
    private func computeTooltipPosition(row: Int, col: Int, cellSize: CGFloat) -> CGPoint {
        let xPadding: CGFloat = cellSize / 2 // center horizontally
        let yPadding: CGFloat = -16 // don't overlap the cell
        
        let x = CGFloat(col + 1) * (cellSize + spacing) + xPadding
        let y = CGFloat(row + 1) * (cellSize + spacing) + yPadding
        
        return CGPoint(x: x, y: y)
    }
    
    private func computeSliderPosition(row: Int, col: Int, cellSize: CGFloat, speciesCount: Int) -> UnitPoint {
        let totalCells = CGFloat(speciesCount + 1)

        let unitX = (CGFloat(col + 1) / totalCells) + (0.5 / (totalCells + 0.5))
        let unitY = (CGFloat(row + 1) / totalCells)

        return UnitPoint(x: unitX, y: unitY)
    }

    /// Determines color based on interaction value
    func colorForValue(_ value: Float) -> Color {
        switch value {
        case let v where v > 0:
            return Color(hue: 1/3, saturation: 1.0, brightness: 0.2 + 0.8 * Double(v)) // Green (Attraction)
        case let v where v < 0:
            return Color(hue: 0, saturation: 1.0, brightness: 0.2 + 0.8 * Double(-v)) // Red (Repulsion)
        default:
            return .black // Neutral
        }
    }
}

struct MatrixPreviewWrapper: View {
    @State private var n: Int
    @State private var matrix: [[Float]]

    let speciesColors: [Color]
    
    init(n: Int) {
        self._n = State(initialValue: n)
        self._matrix = State(initialValue: Array(repeating: Array(repeating: 0.99, count: n), count: n))
        
        let offset = 0
        let predefinedColors = ColorPalette.muted.colors // Directly access the palette via the enum
        self.speciesColors = (0..<n).map { predefinedColors[($0 + offset) % predefinedColors.count] }
    }
    
    var body: some View {
        
        MatrixView(
            matrix: $matrix,
            renderer: Renderer(fpsMonitor: FPSMonitor()),
            speciesColors: speciesColors
        )
        .frame(width: 300, height: 300)
        .background(Color.black)
    }
}

#Preview {
    MatrixPreviewWrapper(n: 2)
}
