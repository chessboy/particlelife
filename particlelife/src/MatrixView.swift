//
//  MatrixView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/14/25.
//

import SwiftUI

struct MatrixView: View {
    let interactionMatrix: [[Float]]
    let speciesColors: [Color]

    @State private var hoveredCell: (row: Int, col: Int)? = nil
    @State private var tooltipPosition: CGPoint = .zero
    @State private var tooltipText: String = ""

    var body: some View {
        VStack {
            // 🔹 Species Header Row
            SpeciesHeaderRow(speciesColors: speciesColors)

            // 🔹 Interaction Matrix Grid
            GeometryReader { proxy in
                let gridOrigin = proxy.frame(in: .global).origin

                VStack {
                    InteractionMatrixGrid(
                        interactionMatrix: interactionMatrix,
                        speciesColors: speciesColors,
                        hoveredCell: $hoveredCell,
                        tooltipText: $tooltipText,
                        tooltipPosition: $tooltipPosition,
                        gridOrigin: gridOrigin)
                }
            }
        }
        .frame(width: 240, height: CGFloat(interactionMatrix.count + 1) * 22 - 4)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .cornerRadius(8)
        .overlay(tooltipView, alignment: .topLeading) // 🔥 Floating tooltip
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
    let interactionMatrix: [[Float]]
    let speciesColors: [Color]

    @Binding var hoveredCell: (row: Int, col: Int)?
    @Binding var tooltipText: String
    @Binding var tooltipPosition: CGPoint
    var gridOrigin: CGPoint

    var body: some View {
            LazyVStack(spacing: 2) {
                ForEach(interactionMatrix.indices, id: \.self) { row in
                    rowView(row: row, gridOrigin: gridOrigin)
                }
            }
    }

    /// Extracted row rendering logic into a separate function
    @ViewBuilder
    private func rowView(row: Int, gridOrigin: CGPoint) -> some View {
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
                cellView(row: row, col: col, gridOrigin: gridOrigin)
            }
        }
    }
    /// Extracted cell rendering logic into a separate function
    @ViewBuilder
    private func cellView(row: Int, col: Int, gridOrigin: CGPoint) -> some View {
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
                    
                    // ✅ Dynamically calculate tooltip position
                    tooltipPosition = computeTooltipPosition(row: row, col: col, gridOrigin: gridOrigin)
                } else {
                    hoveredCell = nil
                }
            }
    }
    
    private func computeTooltipPosition(row: Int, col: Int, gridOrigin: CGPoint) -> CGPoint {
        guard speciesColors.count > 0 else { return .zero }
        
        let cellSize: CGFloat = 22
        let maxViewWidth: CGFloat = 240
        let gridWidth: CGFloat = CGFloat(speciesColors.count) * cellSize
        let padding = (maxViewWidth - gridWidth) / 2
        let xOffset = padding + CGFloat(col - 1) * cellSize + (cellSize / 2) + 36

        let yOffset: CGFloat = CGFloat(row) * cellSize + 20
        
        print("")
        
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
