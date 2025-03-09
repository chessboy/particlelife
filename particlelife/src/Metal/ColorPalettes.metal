//
//  ColorPalettes.metal
//  particlelife
//
//  Created by Rob Silverman on 3/3/25.
//

#include <metal_stdlib>
using namespace metal;

constant float3 colorPalettes[8][9] = {
    {   // Default Bright Palette
        float3(1.0, 0.2, 0.2),   // 🔴 Soft Red
        float3(1.0, 0.6, 0.0),   // 🟠 Orange
        float3(0.95, 0.95, 0.0), // 🟡 Warm Yellow
        float3(0.0, 0.8, 0.2),   // 🟢 Green
        float3(0.0, 0.4, 1.0),   // 🔵 Bright Blue
        float3(0.6, 0.2, 1.0),   // 🟣 Purple
        float3(0.0, 1.0, 1.0),   // 🔵 Cyan
        float3(1.0, 0.0, 0.6),   // 💖 Hot Pink
        float3(0.2, 0.8, 0.6)    // 🌊 Teal
    },
    {   // Muted Nature-Inspired Palette
        float3(0.9, 0.5, 0.4),   // 🍂 Rust
        float3(0.8, 0.7, 0.5),   // 🌾 Wheat
        float3(0.4, 0.6, 0.3),   // 🌲 Forest Green
        float3(0.2, 0.5, 0.7),   // 🌊 Deep Teal
        float3(0.8, 0.3, 0.4),   // 🍓 Soft Berry
        float3(0.6, 0.4, 0.2),   // 🪵 Walnut Brown
        float3(0.7, 0.7, 0.5),   // 🌰 Olive
        float3(0.4, 0.3, 0.6),   // 🍇 Plum
        float3(0.3, 0.4, 0.5)    // ⛈ Stormy Blue
    },
    {   // Dark Cosmic Palette
        float3(0.2, 0.5, 0.3),    // 🍞 Moldy Green-Blue
        float3(0.25, 0.05, 0.5),  // 🔮 Dark Purple (slightly brighter, more visible)
        float3(0.4, 0.05, 0.75),  // 🟣 Electric Violet (enhanced separation)
        float3(0.0, 0.4, 0.8),    // 🔵 Deep Ocean Blue
        float3(0.1, 0.6, 0.3),    // 🌿 Muted Teal Green
        float3(0.6, 0.8, 0.2),    // 💛 Vibrant Chartreuse
        float3(0.9, 0.9, 0.2),    // ⚡ Soft Glow Yellow
        float3(0.6, 0.3, 0.7),    // 🔮 Dim Lavender
        float3(0.2, 0.2, 0.2)     // ⚫ Charcoal Grey
    },
    {   // **SpeciesColorAlt Palette**
        float3(0.95, 0.35, 0.35),  // 🍓 Soft Strawberry
        float3(1.0, 0.55, 0.15),   // 🍊 Sunset Orange
        float3(1.0, 0.85, 0.3),    // 🍋 Lemon Gold
        float3(0.3, 0.8, 0.4),     // 🌿 Leaf Green
        float3(0.3, 0.6, 1.0),     // 🌊 Sky Blue
        float3(0.7, 0.4, 1.0),     // 🎆 Soft Lavender
        float3(0.2, 0.9, 0.9),     // 🌴 Aqua Green
        float3(1.0, 0.3, 0.7),     // 🌸 Cherry Blossom
        float3(0.3, 0.85, 0.7)     // 🦜 Mint Teal
    },
    {   // **SpeciesColorWild Palette**
        float3(1.0, 0.0, 0.0),   // 🔥 Pure Red
        float3(1.0, 0.5, 0.0),   // 🧡 Neon Orange
        float3(1.0, 1.0, 0.0),   // ⚡ Electric Yellow
        float3(0.0, 1.0, 0.0),   // 🍀 Vivid Green
        float3(0.0, 1.0, 1.0),   // 💎 Neon Cyan
        float3(0.0, 0.0, 1.0),   // 🔵 Ultra Blue
        float3(0.6, 0.0, 1.0),   // 🔮 Deep Violet
        float3(1.0, 0.0, 1.0),   // 💜 Hyper Magenta
        float3(1.0, 0.0, 0.5)    // 💖 Hot Raspberry
    },
    {   // **Sunset Palette 🌅**
        float3(1.0, 0.5, 0.2),   // 🌅 Warm Tangerine
        float3(1.0, 0.3, 0.3),   // 🍓 Deep Strawberry Red
        float3(1.0, 0.75, 0.3),  // 🍑 Golden Peach
        float3(0.8, 0.5, 0.2),   // 🌄 Burnt Sienna
        float3(0.6, 0.3, 0.6),   // 🌌 Dusk Purple
        float3(0.3, 0.3, 0.7),   // 🌃 Twilight Blue
        float3(0.15, 0.15, 0.5), // 🌙 Deep Night Indigo
        float3(1.0, 0.85, 0.4),  // ☀️ Soft Golden Glow
        float3(0.8, 0.6, 0.2)    // 🌾 Earthy Amber
    },
    {   // **Ocean Palette 🌊**
        float3(0.0, 0.2, 0.6),   // 🌊 Deep Ocean Blue
        float3(0.0, 0.5, 0.8),   // 🟦 Bright Cerulean
        float3(0.0, 0.7, 1.0),   // 💎 Electric Aqua
        float3(0.0, 0.4, 0.3),   // 🦑 Deep Sea Green
        float3(0.2, 0.8, 0.6),   // 🐬 Turquoise
        float3(0.6, 1.0, 0.8),   // 🏝️ Soft Mint Green
        float3(0.8, 0.9, 1.0),   // ☁️ Pale Sky Blue
        float3(1.0, 1.0, 1.0),   // 🌊 Foam White
        float3(0.1, 0.3, 0.5)    // 🌑 Midnight Tide
    },
    {   // Gray Palette
        float3(0.3, 0.3, 0.3),   // ⚫ Dark Gray
        float3(0.4, 0.4, 0.4),   // 🌑 Charcoal Gray
        float3(0.5, 0.5, 0.5),   // 🌗 Mid Gray
        float3(0.6, 0.6, 0.6),   // 🌖 Soft Gray
        float3(0.7, 0.7, 0.7),   // 🌕 Light Gray
        float3(0.75, 0.75, 0.75), // 🌫️ Misty Gray
        float3(0.8, 0.8, 0.8),   // ☁ Pale Gray
        float3(0.85, 0.85, 0.85), // ⚪ Almost White Gray
        float3(0.9, 0.9, 0.9)    // ❄ Near-White
    },
};
