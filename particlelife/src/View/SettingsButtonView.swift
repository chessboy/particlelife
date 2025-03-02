//
//  SettingsButtonView.swift
//  particlelife
//
//  Created by Rob Silverman on 3/1/25.
//

import SwiftUI

struct SettingsButtonView: View {
    var action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: SFSymbols.Name.settings)
                    .font(.system(size: 18, weight: .bold))

                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 130, height: 36)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(.white)
            .background(isHovered ? Color.black : Color.black.opacity(0.8))
            .clipShape(Capsule())
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
    }
}
