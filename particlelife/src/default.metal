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
    if (species == 0) return float3(1.0, 0.0, 0.0); // Red
    if (species == 1) return float3(0.0, 1.0, 0.0); // Green
    if (species == 2) return float3(0.0, 0.0, 1.0); // Blue
    return float3(1.0, 1.0, 1.0); // White (fallback, should never be hit now)
}

vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]], uint id [[vertex_id]]) {
    VertexOut out;
    out.position = float4(particles[id].position, 0.0, 1.0);
    out.pointSize = 5.0;
    out.color = float4(speciesColor(particles[id].species), 1.0);
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}

float2 wrap_position(float2 pos) {
    if (pos.x > 1.0) pos.x -= 2.0;
    if (pos.x < -1.0) pos.x += 2.0;
    if (pos.y > 1.0) pos.y -= 2.0;
    if (pos.y < -1.0) pos.y += 2.0;
    return pos;
}

kernel void compute_particle_movement(device Particle *particles [[buffer(0)]],
                                      constant float *interactionMatrix [[buffer(1)]],
                                      uint id [[thread_position_in_grid]],
                                      uint totalParticles [[threads_per_grid]]) {
    if (id >= totalParticles) return;

    float2 force = float2(0.0, 0.0);
    float maxDistance = 1.0;
    float forceStrength = 0.0005;

    Particle selfParticle = particles[id];

    for (uint i = 0; i < totalParticles; i++) {
        if (i == id) continue;

        Particle other = particles[i];
        float2 direction = other.position - selfParticle.position;
        float distance = length(direction);

        if (distance > 0.001 && distance < maxDistance) {
            int selfSpecies = selfParticle.species;
            int otherSpecies = other.species;
            float influence = interactionMatrix[selfSpecies * 3 + otherSpecies];

            force += normalize(direction) * influence * forceStrength;
        }
    }

    particles[id].velocity += force;
    particles[id].position += particles[id].velocity;

    // ✅ Apply wrap-around logic
    particles[id].position = wrap_position(particles[id].position);
}
