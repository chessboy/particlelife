//
//  TooltipView.swift
//  particlelife
//
//  Created by Rob Silverman on 2/18/25.
//

import SwiftUI

struct TooltipView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.headline)
            .frame(width: 50)
            .padding(5)
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(5)
    }
}
