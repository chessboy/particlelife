#include <metal_stdlib>
using namespace metal;

#include "ColorPalettes.metal"
#include "Random.metal"
#include "Constants.metal"
#include "Structs.metal"

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
                                      constant ClickData* clickData [[buffer(4)]],
                                      constant uint &frameCount [[buffer(5)]],
                                      constant PhysicsSettings &settings [[buffer(6)]],
                                      uint id [[thread_position_in_grid]],
                                      uint totalParticles [[threads_per_grid]]) {
    
    if (id >= totalParticles) return;
    
    // Load values once (avoid redundant memory access)
    const int c_speciesCount = *speciesCount;
    const float c_dt = *dt;
    const float c_maxDistance = settings.maxDistance;
    const float c_minDistance = settings.minDistance;
    const float c_worldSize = settings.worldSize;
    const float c_repulsion = settings.repulsion;
    const float c_beta = settings.beta;
    const float c_friction = settings.friction;
    
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
            force = fast::clamp(force, -MAX_FORCE, MAX_FORCE);
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
                const float angle = rand(id, 1, 123) * πTimes2;
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
    const float frictionFactor = 1.0 - (c_friction * 1.1);
    
    // Apply final force
    selfParticle.velocity += force * 0.175;
    
    // Apply friction
    selfParticle.velocity *= frictionFactor;
    
    // Move the particle by velocity with respect to delta time
    selfParticle.position += selfParticle.velocity * c_dt;
    
    // Keep it in bounds
    selfParticle.position = handleBoundary(selfParticle.position, c_worldSize);
    
    particles[id] = selfParticle;
}
