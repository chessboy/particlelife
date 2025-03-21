//
//  Structs.metal
//  particlelife
//
//  Created by Rob Silverman on 3/21/25.
//

#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    int species;
};

struct ClickData {
    float2 position;  // x, y of click
    float force;     // Effect force
};


