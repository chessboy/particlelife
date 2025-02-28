//
//  TooltipView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/18/25.
//

import SwiftUI

struct TooltipView: View {
    
    enum TooltipViewStyle {
        case fill
        case shadow
    }
    
    let text: String
    let style: TooltipViewStyle
    
    var body: some View {
        Text(text)
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(width: 50)
            .padding(5)
            .background(style == .fill ? Color.black.opacity(0.8) : Color.clear) // Apply background conditionally
            .shadow(color: .black.opacity(0.8), radius: style == .shadow ? 4 : 0) // Apply shadow conditionally
            .cornerRadius(5)
    }
}
