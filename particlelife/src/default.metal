#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
};

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
};

vertex VertexOut vertex_main(const device Particle* particles [[buffer(0)]], uint id [[vertex_id]]) {
    VertexOut out;
    out.position = float4(particles[id].position, 0.0, 1.0);
    out.pointSize = 5.0;  // Reduced from 8.0 to 3.0
    return out;
}
fragment float4 fragment_main() {
    return float4(1.0, 1.0, 1.0, 0.9);  // Slight transparency to fade out older frames
}

kernel void compute_particle_movement(device Particle *particles [[buffer(0)]],
                                      uint id [[thread_position_in_grid]]) {
    particles[id].position += particles[id].velocity;
}
