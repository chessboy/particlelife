#include <metal_stdlib>
using namespace metal;

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

    float2 worldPosition = particles[id].position - *cameraPosition;
    worldPosition *= *zoomLevel;
    
    out.position = float4(worldPosition, 0.0, 1.0);
    out.pointSize = *pointSize;
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
    out.color = float4(0.5, 0.5, 0.0, 1.0);

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
    float boundary = worldSize; // ✅ Dynamic boundary
    float wrapDistance = 2.0 * worldSize; // ✅ Dynamic wrap distance

    if (pos.x > boundary) pos.x -= wrapDistance;
    if (pos.x < -boundary) pos.x += wrapDistance;
    if (pos.y > boundary) pos.y -= wrapDistance;
    if (pos.y < -boundary) pos.y += wrapDistance;

    return pos;
}

float2 computeWrappedDistance(float2 posA, float2 posB, float worldSize) {
    float wrapDistance = 2.0 * worldSize; // ✅ Dynamic wrap distance
    float2 delta = posB - posA;

    if (delta.x > worldSize) delta.x -= wrapDistance;
    if (delta.x < -worldSize) delta.x += wrapDistance;
    if (delta.y > worldSize) delta.y -= wrapDistance;
    if (delta.y < -worldSize) delta.y += wrapDistance;

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

        // compute force intreations
        if (distance > *minDistance && distance < *maxDistance) {
            int selfSpecies = selfParticle.species;
            int otherSpecies = other.species;
            float influence = interactionMatrix[selfSpecies * (*numSpecies) + otherSpecies];

            float forceValue = (distance / *beta - 1.0) * influence;
            if (distance < *beta) {
                forceValue *= 0.7;  // Weaken short-range attraction
            }

            float falloff = smoothstep(*maxDistance, *minDistance, distance);
            forceValue *= falloff * (*dt);
            
            force += normalize(direction) * forceValue;
            float maxForce = 50.0;
            force = clamp(force, -maxForce, maxForce);
        }

        // universal repulsion between any 2 particles
        if (*repulsion > 0.0 && distance < (*minDistance * 1.5)) {
            float repulsionStrength = (*repulsion) * (1.0 - (distance / (*minDistance * 1.5)));
            force -= normalize(direction) * repulsionStrength;
        }
    }

    // Apply friction dynamically
    selfParticle.velocity += force * 0.1;
    selfParticle.velocity *= (1.0 - *friction);
    selfParticle.position += selfParticle.velocity * (*dt);
    selfParticle.position = handleBoundary(selfParticle.position, *worldSize);

    particles[id] = selfParticle;
}
