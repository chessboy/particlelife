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
fragment float4 fragment_main(VertexOut in
                              [[stage_in]], float2 pointCoord [[point_coord]],
                              constant RenderSettings &renderSettings [[buffer(0)]]) {
    
    float2 coord = pointCoord - 0.5;
    float distSquared = dot(coord, coord);

    // Use colorEffectIndex to modify behavior
    float alpha = 1.0 - smoothstep(0.2, 0.25, distSquared);  // Default smooth transition

    if (renderSettings.colorEffect >= 1) {
        alpha *= 0.75;
        return float4(in.color.rgb * alpha * 1.25, alpha);
   }
    
    return float4(in.color.rgb, alpha);
}

// Species colors are tweaked by blending its color with neighboring colors
float4 speciesColor(Particle particle, RenderSettings renderSettings, uint frameCount, uint id, int speciesCount) {
    
    const uint c_colorOffset = renderSettings.colorOffset;
    const uint c_paletteIndex = renderSettings.paletteIndex;
    const uint c_colorEffect = renderSettings.colorEffect;

    int adjustedSpecies = ((particle.species % speciesCount) + c_colorOffset) % TOTAL_SPECIES;
    int palette = fast::clamp(c_paletteIndex, 0, int(sizeof(colorPalettes) / sizeof(colorPalettes[0])) - 1);
    
    // Get primary color
    float3 baseColor = colorPalettes[palette][adjustedSpecies];

    if (c_colorEffect == 1) {
        // --- TEXTURE EFFECT ---
        int neighborOffset = (rand(particle.species, c_colorOffset, id) > 0.5 ? 1 : -1);
        int neighborSpecies = ((particle.species + neighborOffset) % speciesCount + speciesCount) % speciesCount;
        neighborSpecies = (neighborSpecies + c_colorOffset) % TOTAL_SPECIES;
        
        float3 neighborColor = colorPalettes[palette][neighborSpecies];
        
        // Blend base & neighbor between 0 and 20%
        float blendAmount = rand(id, c_colorOffset, particle.species) * 0.2;
        baseColor = mix(baseColor, neighborColor, blendAmount);
        
        // Apply subtle brightness variation (from 1.4 to 1.6)
        float brightnessFactor = 1.4 + rand(id, c_colorOffset, particle.species) * 0.2;
        baseColor *= brightnessFactor;
    }
    else if (c_colorEffect >= 2) {
        float speed = length(particle.velocity); // Compute speed magnitude
        float speedFactor = fast::clamp(speed * 2.0, 0.0, 1.0); // Normalize speed to [0,1]

        if (c_colorEffect == 2) {
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
    return float4(baseColor * adjustedFactor, 1);
}

// draw particles in the world
vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]],
                             constant uint &frameCount [[buffer(1)]],
                             constant uint &speciesCount [[buffer(2)]],
                             constant RenderSettings &renderSettings [[buffer(3)]],
                             uint id [[vertex_id]]
) {

    VertexOut out;

    // Load values once (avoid redundant memory access)
    const float2 c_cameraPosition = renderSettings.cameraPosition;
    const float c_zoom = renderSettings.zoomLevel;
    const float2 c_windowSize = renderSettings.windowSize;
    const float c_pointSize = renderSettings.pointSize;

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
     out.color = speciesColor(particles[id], renderSettings, frameCount, id, speciesCount);
    
    return out;
}
