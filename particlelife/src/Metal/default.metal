#include <metal_stdlib>
using namespace metal;

#include "ColorUtils.metal"
#include "ColorPalettes.metal"
#include "Random.metal"

constant float ASPECT_RATIO = 1.7778;
constant float ASPECT_RATIO_INVERSE = 1.0 / 1.7778;
constant int TOTAL_SPECIES = 9;
constant float FADE_IN_FRAMES = 60.0;

struct Particle {
    float2 position;
    float2 velocity;
    int species;
};

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

struct ClickData {
    float2 position;  // x, y of click
    float force;     // Effect force
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

    if (colorEffectIndex >= 1) {
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
        
    // --- FADE-IN EFFECT ---
    const float fadeDuration = FADE_IN_FRAMES;  // Number of frames to reach full visibility
    float fadeFactor = saturate(frameCount / fadeDuration); // Gradually increases from 0 to 1
    
    return baseColor * fadeFactor;  // Darker at start, full color at fadeDuration
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

float2 handleBoundary(float2 pos, float worldSize) {
    const float boundaryX = worldSize * ASPECT_RATIO;
    const float boundaryY = worldSize;
    const float wrapDistanceX = 2.0 * boundaryX;
    const float wrapDistanceY = 2.0 * boundaryY;

    while (pos.x > boundaryX) pos.x -= wrapDistanceX;
    while (pos.x < -boundaryX) pos.x += wrapDistanceX;
    while (pos.y > boundaryY) pos.y -= wrapDistanceY;
    while (pos.y < -boundaryY) pos.y += wrapDistanceY;

    return pos;
}

float2 computeWrappedDistance(float2 posA, float2 posB, float worldSize) {
    const float boundaryX = worldSize * ASPECT_RATIO;
    const float boundaryY = worldSize;
    const float wrapDistanceX = 2.0 * boundaryX;
    const float wrapDistanceY = 2.0 * boundaryY;

    float2 delta = posB - posA;

    if (fabs(delta.x) > boundaryX) delta.x -= copysign(wrapDistanceX, delta.x);
    if (fabs(delta.y) > boundaryY) delta.y -= copysign(wrapDistanceY, delta.y);

    return delta;
}

kernel void compute_particle_movement(
    device Particle* particles [[buffer(0)]],
    constant float* interactionMatrix [[buffer(1)]],
    constant uint* speciesCount [[buffer(2)]],
    constant float* dt [[buffer(3)]],
    constant float* maxDistance [[buffer(4)]],
    constant float* minDistance [[buffer(5)]],
    constant float* beta [[buffer(6)]],
    constant float* friction [[buffer(7)]],
    constant float* repulsion [[buffer(8)]],
    constant float2* cameraPosition [[buffer(9)]],
    constant float* zoomLevel [[buffer(10)]],
    constant float* worldSize [[buffer(11)]],
    constant ClickData* clickData [[buffer(12)]],
    constant uint &frameCount [[buffer(13)]],
    uint id [[thread_position_in_grid]],
    uint totalParticles [[threads_per_grid]]) {

    if (id >= totalParticles) return;

    // Load values once (avoid redundant memory access)
    const int c_speciesCount = *speciesCount;
    const float c_maxDistance = *maxDistance;
    const float c_minDistance = *minDistance;
    const float c_worldSize = *worldSize;
    const float c_repulsion = *repulsion;
    const float c_beta = *beta;
    const float c_dt = *dt;

    float2 force = float2(0.0, 0.0);
    Particle selfParticle = particles[id];
    
    if (selfParticle.species < 0 || selfParticle.species >= int(c_speciesCount)) {
        selfParticle.species = 0;  // Debug: Prevent invalid species values
    }
    
    particles[id] = selfParticle;

    for (uint i = 0; i < totalParticles; i++) {
        if (i == id) continue;

        device Particle &other = particles[i];
        const float2 direction = computeWrappedDistance(selfParticle.position, other.position, c_worldSize);
        const float distance = fast::length(direction);

        // Compute force interactions between particles
        if (distance > c_minDistance && distance < c_maxDistance) {
            const int selfSpecies = selfParticle.species;
            const int otherSpecies = other.species;
            const float influence = interactionMatrix[selfSpecies * (c_speciesCount) + otherSpecies];

            // Attraction/repulsion based on species interaction matrix.
            // Influence is scaled so that force is strongest at minDistance and weakens at maxDistance.
            float forceValue = influence * (1.0 - (distance / c_maxDistance));

            // Gradually weakens short-range attraction instead of applying a fixed multiplier.
            // Ensures force starts at zero when distance is 0 and reaches full strength at beta.
            if (distance < c_beta) {
                forceValue *= distance / c_beta;
            }
            
            // Smoothly reduces force near maxDistance to prevent abrupt cutoffs.
            // `smoothstep` ensures a gradual transition from full force (minDistance) to zero force (maxDistance).
            // This improves stability and prevents unnatural force drops.
            const float falloff = smoothstep(c_maxDistance, c_minDistance, distance);
            forceValue *= falloff * c_dt;

            // Normalize force and apply safely to avoid extreme values
            force += fast::normalize(direction) * forceValue;
            const float maxForce = 30.0;
            force = fast::clamp(force, -maxForce, maxForce);
        }
        
        // Apply universal repulsion between any two particles at very close range.
        // Prevents particles from overlapping by generating a short-range repulsive force.
        const float minDistScaled = c_minDistance * 1.5;
        if (c_repulsion > 0.0 && distance < minDistScaled) {
            const float repulsionStrength = (c_repulsion) * (1.0 - (distance / minDistScaled));
            force -= fast::normalize(direction) * repulsionStrength;
        }
        
        // Apply a perturbation force within a specified radius around the click position.
        float2 clickPos = clickData[0].position;

        if (clickPos.x != 0.0 || clickPos.y != 0.0) {
            const float effectRadius = 0.05 * c_worldSize;
            const float clickForce = clickData[0].force;

            float2 delta = selfParticle.position - clickPos;
            const float distance = fast::length(delta);

            if (distance < effectRadius) {
                // Generate a uniform random angle in [0, 2π]
                const float angle = rand(id, 1, 123) * 6.2831853;
                float2 randomDirection = float2(cos(angle), sin(angle));

                // Compute aspect ratio correction properly
                float aspectRatio = ASPECT_RATIO_INVERSE;  // Invert aspect ratio
                float2 correctedDirection = float2(randomDirection.x, randomDirection.y * aspectRatio);

                // Re-normalize after applying aspect correction
                correctedDirection = fast::normalize(correctedDirection);

                // Generate a random force magnitude in [-0.0002, 0.0002] and scale by clickForce
                const float randomMagnitude = (rand(id, 2, 456) - 0.5) * 0.0002 * clickForce;

                // Apply final perturbation force
                selfParticle.velocity += correctedDirection * randomMagnitude;
            }
        }
    }

        // Precompute friction factor
        const float frictionFactor = 1.0 - (*friction * 1.1);

        // Apply final force
        selfParticle.velocity += force * 0.15;

        // Apply friction
        selfParticle.velocity *= frictionFactor;

        // Move the particle by velocity with respect to delta time
        selfParticle.position += selfParticle.velocity * c_dt;

        // Keep it in bounds
        selfParticle.position = handleBoundary(selfParticle.position, c_worldSize);
        
    particles[id] = selfParticle;
}
