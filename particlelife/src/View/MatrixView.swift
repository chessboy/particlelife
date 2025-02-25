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
    
    @Binding var interactionMatrix: [[Float]]
    @Binding var isVisible: Bool
    
    @State private var hoveredCell: (row: Int, col: Int)? = nil
    @State private var tooltipPosition: CGPoint = .zero
    @State private var tooltipText: String = ""
    
    @State private var selectedCell: SelectedCell? = nil
    @State private var sliderPosition: UnitPoint = .zero
    @State private var sliderValue: Float = 0.0
    
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
                    selectedCell = nil
                    hoveredCell = nil
                }
            )
        }
        .onChange(of: selectedCell) { oldValue, newValue in
            if newValue == nil {
                hoveredCell = nil // Reset when popover is dismissed
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.keyCode == 53 || event.keyCode == 36 || event.keyCode == 76 {
                    // 53 = ESC, 36 = Return, 76 = Enter
                    selectedCell = nil
                    hoveredCell = nil
                    return nil
                }
                return event
            }
        }
    }

    // Floating tooltip positioned dynamically
    @ViewBuilder
    private var tooltipView: some View {
        if hoveredCell != nil, selectedCell == nil {
            TooltipView(text: tooltipText)
                .position(tooltipPosition)
        }
    }
        
    private func setMatrixValue(row: Int, col: Int, newValue: Float) {
        interactionMatrix[row][col] = newValue
        BufferManager.shared.updateInteractionBuffer(interactionMatrix: interactionMatrix)
        tooltipText = String(format: "%.2f", newValue)
        
        // update the current preset's matrix
        SimulationSettings.shared.selectedPreset = SimulationSettings.shared.selectedPreset.copy(withName: nil, newMatrixType: .custom(interactionMatrix))
    }
}

struct InteractionMatrixGrid: View {
    @State private var lastMouseButton: Int = 0
    @Binding var isVisible: Bool
    
    let speciesColors: [Color]
    @Binding var interactionMatrix: [[Float]]
    
    @Binding var hoveredCell: (row: Int, col: Int)?
    @Binding var tooltipText: String
    @Binding var tooltipPosition: CGPoint
    
    @Binding var selectedCell: SelectedCell?
    @Binding var sliderPosition: UnitPoint
    @Binding var sliderValue: Float

    @ObservedObject var renderer: Renderer
        
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
    
    var body: some View {
        GeometryReader { geometry in
            let speciesCount = max(1, interactionMatrix.count)
            let totalWidth = max(10, geometry.size.width - CGFloat(speciesCount + 1) * spacing)
            let cellSize = max(5, totalWidth / CGFloat(speciesCount + 1))

            VStack(spacing: spacing) {
                // Header row with species colors
                HStack(spacing: spacing) {
                    Color.clear.frame(width: cellSize, height: cellSize) // Placeholder for alignment
                    ForEach(speciesColors.indices, id: \.self) { index in
                        speciesColors[index]
                            .frame(width: cellSize * circleScale, height: cellSize * circleScale)
                            .clipShape(Circle())
                            .frame(width: cellSize, height: cellSize)
                    }
                }
                .frame(height: cellSize)
                
                // Matrix rows with species color indicators
                VStack(spacing: spacing) {
                    ForEach(interactionMatrix.indices, id: \.self) { row in
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
                speciesColors[row]
                    .frame(width: cellSize * circleScale, height: cellSize * circleScale)
                    .clipShape(Circle())
                    .frame(width: cellSize, height: cellSize)
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
        
        RoundedRectangle(cornerRadius: cornerRadiusMatrix)
            .fill(colorForValue(value))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                abs(value) < 2 ? strokedRectangle(color: Color.white.opacity(0.2), lineWidth: 1, cornerRadius: cornerRadiusMatrix) : nil
            )
            .overlay(
                hoveredCell.map { hovered in
                    hovered == (row, col) ? strokedRectangle(color: Color.white, lineWidth: 2, cornerRadius: cornerRadiusMatrix) : nil
                }
            )
            .onHover { isHovering in
                guard selectedCell == nil else { return } // Don't reset hover state if a cell is selected
                
                if isHovering {
                    hoveredCell = (row, col)
                    tooltipText = String(format: "%.2f", value)
                    tooltipPosition = computeTooltipPosition(row: row, col: col, totalWidth: totalWidth, cellSize: cellSize)
                } else if let hovered = hoveredCell, hovered == (row, col) {
                    hoveredCell = nil // Only clear if it's the same hovered cell
                }
            }
            .onTapGesture {
                guard selectedCell == nil else { return } // Ignore if a cell is already selected
                
                selectedCell = SelectedCell(row: row, col: col)
                hoveredCell = (row, col)
                sliderValue = value
                sliderPosition = computeSliderPosition(row: row, col: col, totalWidth: totalWidth, cellSize: cellSize, speciesCount: max(1, speciesColors.count))
            }
    }
}

extension InteractionMatrixGrid {
    
    private func computeTooltipPosition(row: Int, col: Int, totalWidth: CGFloat, cellSize: CGFloat) -> CGPoint {
        let xPadding: CGFloat = cellSize / 2 // center horizontally
        let yPadding: CGFloat = -16 // don't overlap the cell
        
        let x = CGFloat(col + 1) * (cellSize + spacing) + xPadding
        let y = CGFloat(row + 1) * (cellSize + spacing) + yPadding
        
        return CGPoint(x: x, y: y)
    }
    
    private func computeSliderPosition(row: Int, col: Int, totalWidth: CGFloat, cellSize: CGFloat, speciesCount: Int) -> UnitPoint {
        let totalCells = CGFloat(speciesCount + 1)
        
        let x = (CGFloat(col + 1) / totalCells) * totalWidth + cellSize / 2
        let y = (CGFloat(row + 1) / totalCells) * totalWidth
        
        let unitX = x / totalWidth
        let unitY = y / totalWidth
        let unitPoint = UnitPoint(x: unitX, y: unitY)
        
        return unitPoint
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
