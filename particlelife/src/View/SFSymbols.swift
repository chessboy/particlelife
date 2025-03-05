//
//  SFSymbols.swift
//  particlelife
//
//  Created by Rob Silverman on 3/5/25.
//

import Foundation

struct SFSymbols {

    struct Name {
        static let close = "xmark.circle.fill"
        static let randomize = "shuffle"
        static let reset = "arrowshape.turn.up.backward.fill"
        static let respawn = if #available(macOS 15, *) { "arrow.trianglehead.2.clockwise.rotate.90" } else { "arrow.triangle.2.circlepath" }
        static let settings = "gearshape.fill"
        static let colorEffect = if #available(macOS 15, *) { "circle.bottomrighthalf.pattern.checkered" } else { "paintbrush.pointed.fill" }
        static let presets = "star.fill"
        static let dice = if #available(macOS 15, *) { "die.face.5" } else { "dice.fill" }
        static let warning = "exclamationmark.triangle.fill"
        static let new = if #available(macOS 15, *) { "plus.circle.fill" } else { "plus.circle" }
        static let stored = if #available(macOS 15, *) { "archivebox.fill" } else { "archivebox" }
        static let save = if #available(macOS 15, *) { "square.and.arrow.down.fill" } else { "square.and.arrow.down" }
        static let delete = if #available(macOS 15, *) { "trash.fill" } else { "trash" }
    }
}
