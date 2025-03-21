//
//  Render.metal
//  particlelife
//
//  Created by Rob Silverman on 3/21/25.
//

#include <metal_stdlib>
using namespace metal;

#include "ColorPalettes.metal"
#include "Random.metal"
#include "Constants.metal"
#include "Structs.metal"

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

// draw a particle
fragment float4 fragment_main(VertexOut in [[stage_in]], float2 pointCoord [[point_coord]],
                              constant uint &colorEffectIndex [[buffer(0)]]) {
    
    float2 coord = pointCoord - 0.5;
    float distSquared = dot(coord, coord);

    // Use colorEffectIndex to modify behavior
    float alpha = 1.0 - smoothstep(0.2, 0.25, distSquared);  // Default smooth transition

    if (colorEffectIndex >= 1) {
        alpha *= 0.75;
        return float4(in.color.rgb * alpha * 1.25, alpha);
   }
    
    return float4(in.color.rgb, alpha);
}

// Species colors are tweaked by blending its color with neighboring colors
float3 speciesColor(Particle particle, int speciesColorOffset, int paletteIndex, int colorEffectIndex,
                    uint frameCount, uint id, int speciesCount) {
    
    int adjustedSpecies = ((particle.species % speciesCount) + speciesColorOffset) % TOTAL_SPECIES;
    int palette = fast::clamp(paletteIndex, 0, int(sizeof(colorPalettes) / sizeof(colorPalettes[0])) - 1);
    
    // Get primary color
    float3 baseColor = colorPalettes[palette][adjustedSpecies];

    if (colorEffectIndex == 1) {
        // --- TEXTURE EFFECT ---
        int neighborOffset = (rand(particle.species, speciesColorOffset, id) > 0.5 ? 1 : -1);
        int neighborSpecies = ((particle.species + neighborOffset) % speciesCount + speciesCount) % speciesCount;
        neighborSpecies = (neighborSpecies + speciesColorOffset) % TOTAL_SPECIES;
        
        float3 neighborColor = colorPalettes[palette][neighborSpecies];
        
        // Blend base & neighbor between 0 and 20%
        float blendAmount = rand(id, speciesColorOffset, particle.species) * 0.2;
        baseColor = mix(baseColor, neighborColor, blendAmount);
        
        // Apply subtle brightness variation (from 1.4 to 1.6)
        float brightnessFactor = 1.4 + rand(id, speciesColorOffset, particle.species) * 0.2;
        baseColor *= brightnessFactor;
    }
    else if (colorEffectIndex >= 2) {
        float speed = length(particle.velocity); // Compute speed magnitude
        float speedFactor = fast::clamp(speed * 2.0, 0.0, 1.0); // Normalize speed to [0,1]

        if (colorEffectIndex == 2) {
            // --- VELOCITY-BASED COLOR ---
            // Brightness scaling of base color (white at high speed)
            float3 highlightColor = min(baseColor * 2.0, float3(1.2, 1.2, 1.2)); // Boost saturation while keeping it under control
            baseColor = mix(baseColor * 0.3, highlightColor, speedFactor * speedFactor);
        } else { // colorEffectIndex == 3
            // --- VELOCITY-BASED GRAY ---
            // Scale brightness from dark gray to hhite (0.2 → 1.0)
            baseColor = float3(mix(0.2, 1.0, speedFactor));
        }
    }
        
    // --- FADE-IN EFFECT ---
    const float fadeFactor = saturate(frameCount / FADE_IN_FRAMES);
    const float adjustedFactor = max(fadeFactor, 0.1);
    return baseColor * adjustedFactor;
}

// draw particles in the world
vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]],
                             const device float2* cameraPosition [[buffer(1)]],
                             const device float* zoomLevel [[buffer(2)]],
                             constant float* pointSize [[buffer(3)]],
                             constant uint &speciesColorOffset [[buffer(4)]],
                             constant uint &paletteIndex [[buffer(5)]],
                             constant float2* windowSize [[buffer(6)]],
                             constant uint &frameCount [[buffer(7)]],
                             constant uint &colorEffectIndex [[buffer(8)]],
                             constant uint &speciesCount [[buffer(9)]],
                             uint id [[vertex_id]]) {

    VertexOut out;

    // Load values once (avoid redundant memory access)
    const float2 c_cameraPosition = *cameraPosition;
    const float c_zoom = *zoomLevel;
    const float c_pointSize = *pointSize;
    const float2 c_windowSize = *windowSize;

    // Compute world position in normalized space
    float2 worldPosition = particles[id].position - c_cameraPosition;
    worldPosition *= c_zoom;
    worldPosition.x /= ASPECT_RATIO;

    // Scale point size dynamically with window size (and keep zoom & user size adjustments)
    const float scaleFactor = c_windowSize.y / 3000.0;
    float scaledPointSize = c_pointSize * c_zoom * scaleFactor;
    scaledPointSize = fast::clamp(scaledPointSize, 2.0, 200.0);

    // Assign outputs
    out.position = float4(worldPosition, 0.0, 1.0);
    out.pointSize = scaledPointSize;

    // Compute color using species mapping
    out.color = float4(speciesColor(particles[id], speciesColorOffset, paletteIndex, colorEffectIndex, frameCount, id, speciesCount), 1);
    
    return out;
}
