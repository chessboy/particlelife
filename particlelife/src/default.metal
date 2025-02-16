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
        case 0: return float3(1.0, 0.0, 0.0);  // 🔴 Red
        case 1: return float3(1.0, 0.5, 0.0);  // 🟠 Orange
        case 2: return float3(1.0, 1.0, 0.0);  // 🟡 Yellow
        case 3: return float3(0.0, 1.0, 0.0);  // 🟢 Green
        case 4: return float3(0.0, 0.0, 1.0);  // 🔵 Blue
        case 5: return float3(0.5, 0.0, 1.0);  // 🟣 Purple
        default: return float3(1.0, 1.0, 1.0); // ⚪ White (debug)
    }
}

vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]],
                             const device float2* cameraPosition [[buffer(1)]],
                             const device float* zoomLevel [[buffer(2)]],
                             uint id [[vertex_id]]) {
    VertexOut out;

    // ✅ Convert to world space
    float2 worldPosition = particles[id].position - *cameraPosition;
    
    // ✅ Apply zoom only for rendering
    worldPosition *= *zoomLevel;
    
    out.position = float4(worldPosition, 0.0, 1.0);
    out.pointSize = 7.0;
    out.color = float4(speciesColor(particles[id].species), 1.0);

    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]], float2 pointCoord [[point_coord]]) {
    float2 coord = pointCoord - 0.5;
    float distSquared = dot(coord, coord);

    // Use smoothstep for soft edges instead of discard
    float alpha = 1.0 - smoothstep(0.2, 0.25, distSquared);  // Smooth transition at the edge
    return float4(in.color.rgb, alpha);
}

float2 handleBoundary(float2 pos) {
    if (pos.x > 1.0) pos.x -= 2.0;
    if (pos.x < -1.0) pos.x += 2.0;
    if (pos.y > 1.0) pos.y -= 2.0;
    if (pos.y < -1.0) pos.y += 2.0;
    
    return pos;
}

float2 computeWrappedDistance(float2 posA, float2 posB) {
    float2 delta = posB - posA;

    if (delta.x > 1.0) delta.x -= 2.0;
    if (delta.x < -1.0) delta.x += 2.0;
    if (delta.y > 1.0) delta.y -= 2.0;
    if (delta.y < -1.0) delta.y += 2.0;

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
    constant float *repulsionStrength [[buffer(8)]],
    constant float2 *cameraPosition [[buffer(9)]],
    constant float *zoomLevel [[buffer(10)]],
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

        Particle other = particles[i];
        float2 direction = computeWrappedDistance(selfParticle.position, other.position);
        float distance = length(direction);

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
        }

        // universal repeller
        if (*repulsionStrength > 0.0 && distance < (*minDistance * 1.5)) {
            float repulsion = (*repulsionStrength) * (1.0 - (distance / (*minDistance * 1.5)));
            force -= normalize(direction) * repulsion;
        }
    }

    // Apply friction dynamically
    selfParticle.velocity += force * 0.1;
    selfParticle.velocity *= *friction;
    selfParticle.position += selfParticle.velocity * (*dt);
    selfParticle.position = handleBoundary(selfParticle.position);

    particles[id] = selfParticle;
}
