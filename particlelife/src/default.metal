#include <metal_stdlib>
using namespace metal;

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
    float radius;     // Effect radius
};

// Fast deterministic random function for Metal shaders
float rand(int x, int y, int z) {
    int seed = x + y * 57 + z * 241;
    seed = (seed << 13) ^ seed;
    return ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}


float3 speciesColor(int species) {
    switch (species) {
        case 0: return float3(1.0, 0.2, 0.2);  // 🔴 Soft Red
        case 1: return float3(1.0, 0.6, 0.0);  // 🟠 Orange
        case 2: return float3(0.95, 0.95, 0.0); // 🟡 Warm Yellow
        case 3: return float3(0.0, 0.8, 0.2);  // 🟢 Green (Deeper)
        case 4: return float3(0.0, 0.4, 1.0);  // 🔵 Bright Blue
        case 5: return float3(0.6, 0.2, 1.0);  // 🟣 Purple
        case 6: return float3(0.0, 1.0, 1.0);  // 🔵 Cyan
        case 7: return float3(1.0, 0.0, 0.6);  // 💖 Hot Pink (Instead of Magenta)
        case 8: return float3(0.2, 0.8, 0.6);  // 🌊 Teal (Replaces White)
        default: return float3(0.7, 0.7, 0.7); // ⚫ Light Gray (Fallback)
    }
}

vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]],
                             const device float2* cameraPosition [[buffer(1)]],
                             const device float* zoomLevel [[buffer(2)]],
                             constant float* pointSize [[buffer(3)]],
                             uint id [[vertex_id]]) {
    VertexOut out;

    // Compute world position in normalized space
    float2 worldPosition = particles[id].position - *cameraPosition;
    worldPosition *= *zoomLevel;

    // Hardcoded aspect ratio correction (assuming 16:9 screen)
    worldPosition.x /= ASPECT_RATIO;

    // Scale point size inversely with zoom (but keep it visible)
    float scaledPointSize = *pointSize * *zoomLevel;
    scaledPointSize = clamp(scaledPointSize, 1.0, 60.0);

    out.position = float4(worldPosition, 0.0, 1.0);
    out.pointSize = scaledPointSize;
    out.color = float4(speciesColor(particles[id].species), 1.0);

    return out;
}

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

fragment float4 fragment_main(VertexOut in [[stage_in]], float2 pointCoord [[point_coord]]) {
    float2 coord = pointCoord - 0.5;
    float distSquared = dot(coord, coord);

    // Use smoothstep for soft edges instead of discard
    float alpha = 1.0 - smoothstep(0.2, 0.25, distSquared);  // Smooth transition at the edge
    return float4(in.color.rgb, alpha);
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
    constant int *numSpecies [[buffer(2)]],
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
    
    if (selfParticle.species < 0 || selfParticle.species >= *numSpecies) {
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
            float influence = interactionMatrix[selfSpecies * (*numSpecies) + otherSpecies];

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
        float effectRadius = clickData[0].radius * *worldSize;

        if (clickPos.x != 0.0 || clickPos.y != 0.0) {
            float2 delta = selfParticle.position - clickPos;
            float distance = length(delta);

            if (distance < effectRadius) {
                // Generate a uniform random angle in [0, 2π] for perturbation direction.
                float angle = rand(id, 1, 123) * 6.2831853;
                float2 randomDirection = normalize(float2(cos(angle), sin(angle)));

                // Generate a small random force magnitude in [-0.0002, 0.0002].
                float randomMagnitude = (rand(id, 2, 456) - 0.5) * 0.0002;

                // Compute aspect ratio correction to ensure proper scaling.
                float aspectRatio = worldSize[1] / worldSize[0];
                float2 correctedDirection = float2(randomDirection.x * aspectRatio, randomDirection.y);

                // Apply final perturbation force.
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
