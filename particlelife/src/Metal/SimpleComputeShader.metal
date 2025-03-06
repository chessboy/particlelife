//
//  SimpleComputeShader.metal
//  particlelife
//
//  Created by Rob Silverman on 3/6/25.
//

#include <metal_stdlib>
using namespace metal;

kernel void simpleComputeKernel(device float *data [[buffer(0)]],
                                uint id [[thread_position_in_grid]]) {
    float value = data[id];

    // Introduce more computation to prevent Metal optimizations
    for (int i = 0; i < 50; i++) {
        value = sin(value) + cos(value) * tan(value);
    }

    data[id] = value;
}
