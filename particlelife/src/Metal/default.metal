#include <metal_stdlib>
using namespace metal;

// todo: pass window size buffer to compute shader and remove this
constant float ASPECT_RATIO = 1.7778;

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

// Fast deterministic random function for Metal shaders
float rand(int x, int y, int z) {
    int seed = x + y * 57 + z * 241;
    seed = (seed << 13) ^ seed;
    return ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}

constant float3 colorPalettes[5][9] = {
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
    }
};

float3 speciesColor(int species, int offset, int paletteIndex) {
    int adjustedSpecies = (species + offset) % 9; // Ensure within bounds
    int palette = clamp(paletteIndex, 0, int(sizeof(colorPalettes) / sizeof(colorPalettes[0])) - 1);
    return colorPalettes[palette][adjustedSpecies];
}

// draw particles
vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]],
                             const device float2* cameraPosition [[buffer(1)]],
                             const device float* zoomLevel [[buffer(2)]],
                             constant float* pointSize [[buffer(3)]],
                             constant int* speciesColorOffset [[buffer(4)]],
                             constant int* paletteIndex [[buffer(5)]],
                             constant float2* windowSize [[buffer(6)]],
                             uint id [[vertex_id]]) {
    VertexOut out;

    // Compute world position in normalized space
    float2 worldPosition = particles[id].position - *cameraPosition;
    worldPosition *= *zoomLevel;

    // Dynamically compute aspect ratio
    float aspectRatio = windowSize->x / windowSize->y;

    float2 adjustedScale = float2(1.0, 1.0); // Default scaling

    // Instead of blindly dividing/multiplying, normalize within the fixed aspect ratio
    if (aspectRatio > 1.0) {
        adjustedScale.x = 1.0 / aspectRatio;
    } else {
        adjustedScale.y = aspectRatio;
    }

    worldPosition *= adjustedScale;
    
    // Scale point size dynamically with window size (and keep zoom & user size adjustments)
    float scaleFactor = min(windowSize->x, windowSize->y) / 3000.0;
    float scaledPointSize = *pointSize * *zoomLevel * scaleFactor;
    scaledPointSize = clamp(scaledPointSize, 2.0, 200.0);

    out.position = float4(worldPosition, 0.0, 1.0);
    out.pointSize = scaledPointSize;
    
    out.color = float4(speciesColor(particles[id].species, *speciesColorOffset, *paletteIndex), 1.0);
    
    return out;
}

// draw a point
fragment float4 fragment_main(VertexOut in [[stage_in]], float2 pointCoord [[point_coord]]) {
    float2 coord = pointCoord - 0.5;
    float distSquared = dot(coord, coord);

    // Use smoothstep for soft edges instead of discard
    float alpha = 1.0 - smoothstep(0.2, 0.25, distSquared);  // Smooth transition at the edge
    return float4(in.color.rgb, alpha);
}

// draw boundary
vertex VertexOut vertex_boundary(
    uint id [[vertex_id]],
    const device float2* cameraPosition [[buffer(1)]],
    const device float* zoomLevel [[buffer(2)]],
    const device float* worldSize [[buffer(3)]]
) {
    VertexOut out;

    float halfSize = *worldSize;
    float2 boundaryVertices[5] = {
        float2(-halfSize, -halfSize), // Bottom-left
        float2( halfSize, -halfSize), // Bottom-right
        float2( halfSize,  halfSize), // Top-right
        float2(-halfSize,  halfSize), // Top-left
        float2(-halfSize, -halfSize)  // Closing the loop
    };

    float2 worldPosition = boundaryVertices[id] - *cameraPosition;
    worldPosition *= *zoomLevel;

    out.position = float4(worldPosition, 0.0, 1.0);
    out.color = float4(0.0, 0.33, 0.5, 1.0);

    return out;
}

float2 handleBoundary(float2 pos, float worldSize) {
    float boundaryX = worldSize * ASPECT_RATIO;
    float boundaryY = worldSize;

    float wrapDistanceX = 2.0 * boundaryX;
    float wrapDistanceY = 2.0 * boundaryY;

    if (pos.x > boundaryX) pos.x -= wrapDistanceX;
    if (pos.x < -boundaryX) pos.x += wrapDistanceX;
    if (pos.y > boundaryY) pos.y -= wrapDistanceY;
    if (pos.y < -boundaryY) pos.y += wrapDistanceY;

    return pos;
}

float2 computeWrappedDistance(float2 posA, float2 posB, float worldSize) {
    float wrapDistanceX = 2.0 * worldSize * ASPECT_RATIO; // Scale X wrapping
    float wrapDistanceY = 2.0 * worldSize;               // Y stays the same

    float2 delta = posB - posA;

    if (delta.x > worldSize * ASPECT_RATIO) delta.x -= wrapDistanceX;
    if (delta.x < -worldSize * ASPECT_RATIO) delta.x += wrapDistanceX;
    if (delta.y > worldSize) delta.y -= wrapDistanceY;
    if (delta.y < -worldSize) delta.y += wrapDistanceY;

    return delta;
}

kernel void compute_particle_movement(
    device Particle *particles [[buffer(0)]],
    constant float *interactionMatrix [[buffer(1)]],
    constant int *speciesCount [[buffer(2)]],
    constant float *dt [[buffer(3)]],
    constant float *maxDistance [[buffer(4)]],
    constant float *minDistance [[buffer(5)]],
    constant float *beta [[buffer(6)]],
    constant float *friction [[buffer(7)]],
    constant float *repulsion [[buffer(8)]],
    constant float2 *cameraPosition [[buffer(9)]],
    constant float *zoomLevel [[buffer(10)]],
    constant float *worldSize [[buffer(11)]],
    constant ClickData *clickData [[buffer(12)]],
    uint id [[thread_position_in_grid]],
    uint totalParticles [[threads_per_grid]]) {

    if (id >= totalParticles) return;

    float2 force = float2(0.0, 0.0);
    Particle selfParticle = particles[id];
    
    if (selfParticle.species < 0 || selfParticle.species >= *speciesCount) {
        selfParticle.species = 0;  // Debug: Prevent invalid species values
    }
    particles[id] = selfParticle;

    for (uint i = 0; i < totalParticles; i++) {
        if (i == id) continue;

        device Particle &other = particles[i];
        float2 direction = computeWrappedDistance(selfParticle.position, other.position, *worldSize);
        float distance = length(direction);

        // Compute force interactions between particles
        if (distance > *minDistance && distance < *maxDistance) {
            int selfSpecies = selfParticle.species;
            int otherSpecies = other.species;
            float influence = interactionMatrix[selfSpecies * (*speciesCount) + otherSpecies];

            // Attraction/repulsion based on species interaction matrix.
            // Influence is scaled so that force is strongest at minDistance and weakens at maxDistance.
            float forceValue = influence * (1.0 - (distance / *maxDistance));

            // Gradually weakens short-range attraction instead of applying a fixed multiplier.
            // Ensures force starts at zero when distance is 0 and reaches full strength at beta.
            if (distance < *beta) {
                forceValue *= distance / *beta;
            }
            
            // Smoothly reduces force near maxDistance to prevent abrupt cutoffs.
            // `smoothstep` ensures a gradual transition from full force (minDistance) to zero force (maxDistance).
            // This improves stability and prevents unnatural force drops.
            float falloff = smoothstep(*maxDistance, *minDistance, distance);
            forceValue *= falloff * (*dt);

            // Normalize force and apply safely to avoid extreme values
            force += normalize(direction) * forceValue;
            float maxForce = 50.0;
            force = clamp(force, -maxForce, maxForce);
        }
        
        // Apply universal repulsion between any two particles at very close range.
        // Prevents particles from overlapping by generating a short-range repulsive force.
        if (*repulsion > 0.0 && distance < (*minDistance * 1.5)) {
            float repulsionStrength = (*repulsion) * (1.0 - (distance / (*minDistance * 1.5)));
            force -= normalize(direction) * repulsionStrength;
        }
        
        // Apply a perturbation force within a specified radius around the click position.
        float2 clickPos = clickData[0].position;
        float effectRadius = 0.05 * *worldSize;
        float clickForce = clickData[0].force;

        if (clickPos.x != 0.0 || clickPos.y != 0.0) {
            float2 delta = selfParticle.position - clickPos;
            float distance = length(delta);

            if (distance < effectRadius) {
                // Generate a uniform random angle in [0, 2π]
                float angle = rand(id, 1, 123) * 6.2831853;
                float2 randomDirection = float2(cos(angle), sin(angle));

                // Compute aspect ratio correction properly
                float aspectRatio = worldSize[0] / worldSize[1];  // Invert aspect ratio
                float2 correctedDirection = float2(randomDirection.x, randomDirection.y * aspectRatio);

                // Re-normalize after applying aspect correction
                correctedDirection = normalize(correctedDirection);

                // Generate a random force magnitude in [-0.0002, 0.0002] and scale by clickForce
                float randomMagnitude = (rand(id, 2, 456) - 0.5) * 0.0002 * clickForce;

                // Apply final perturbation force
                selfParticle.velocity += correctedDirection * randomMagnitude;
            }
        }
    }
        
    // Apply friction dynamically
    selfParticle.velocity += force * 0.1;
    selfParticle.velocity *= (1.0 - *friction);
    selfParticle.position += selfParticle.velocity * (*dt);
    selfParticle.position = handleBoundary(selfParticle.position, *worldSize);

    particles[id] = selfParticle;
}
