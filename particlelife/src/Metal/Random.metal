//
//  Random.metal
//  particlelife
//
//  Created by Rob Silverman on 3/3/25.
//

#include <metal_stdlib>
using namespace metal;

// Fast deterministic random function for Metal shaders
inline float rand(int x, int y, int z) {
    int seed = x + y * 57 + z * 241;
    seed = (seed << 13) ^ seed;
    return ((1.0 - ((seed * (seed * seed * 15731 + 789221) + 1376312589) & 2147483647) / 1073741824.0f) + 1.0f) / 2.0f;
}
