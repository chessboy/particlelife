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

float2 handleBoundary(float2 pos) {
    if (pos.x > 1.0) pos.x -= 2.0;
    if (pos.x < -1.0) pos.x += 2.0;
    if (pos.y > 1.0) pos.y -= 2.0;
    if (pos.y < -1.0) pos.y += 2.0;
    return pos;
}

kernel void compute_particle_movement(device Particle *particles [[buffer(0)]],
                                      constant float *interactionMatrix [[buffer(1)]],
                                      constant int *numSpecies [[buffer(2)]],
                                      constant float *dt [[buffer(3)]],
                                      uint id [[thread_position_in_grid]],
                                      uint totalParticles [[threads_per_grid]]) {
    if (id >= totalParticles) return;
    
    float2 force = float2(0.0, 0.0);
    float maxDistance = 1.0;
    float minDistance = 0.02;
    float beta = 0.3;
    
    Particle selfParticle = particles[id];
    
    for (uint i = 0; i < totalParticles; i++) {
        if (i == id) continue;
        
        Particle other = particles[i];
        float2 direction = other.position - selfParticle.position;
        float distance = length(direction);
        
        if (distance > minDistance && distance < maxDistance) {
            int selfSpecies = selfParticle.species;
            int otherSpecies = other.species;
            float influence = interactionMatrix[selfSpecies * (*numSpecies) + otherSpecies];
            
            float forceValue = (distance / beta - 1.0) * influence;
            if (distance < beta) {
                forceValue = (distance / beta - 1.0) * influence * 0.5;  // ✅ Scale down attraction force
            } else {
                float smoothFactor = 1.0 - abs(1.0 + beta - 2.0 * distance) / (1.0 - beta);
                forceValue = influence * smoothFactor * 0.5;  // ✅ Scale down long-range force
            }
            
            float falloff = smoothstep(maxDistance, minDistance, distance);
            forceValue *= falloff * (*dt);  // ✅ Scale by time step
            
            force += normalize(direction) * forceValue;
        }
    }
    
    float friction = 0.98;  // ✅ Adjustable friction factor (reduces energy over time)
    
    // Load particle data into thread-local variables
    thread float2 velocity = selfParticle.velocity;  // ✅ Copy velocity to thread memory
    
    // Apply force to velocity
    velocity += force * 0.1;
    
    // Apply friction
    velocity *= friction;
    
    // Update position
    selfParticle.position += velocity * (*dt);
    
    // Apply bouncing boundary conditions
    selfParticle.position = handleBoundary(selfParticle.position);
    
    // Write updated velocity and position back to the particle
    selfParticle.velocity = velocity;
    particles[id] = selfParticle;
}
