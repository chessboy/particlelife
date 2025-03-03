//
//  ColorUtils.metal
//  particlelife
//
//  Created by Rob Silverman on 3/3/25.
//

#include <metal_stdlib>
using namespace metal;

// Converts RGB to HSV
inline float3 rgbToHsv(float3 c) {
    float maxVal = max(c.r, max(c.g, c.b));
    float minVal = min(c.r, min(c.g, c.b));
    float delta = maxVal - minVal;

    float h = 0.0;
    float s = (maxVal == 0.0) ? 0.0 : delta / maxVal;
    float v = maxVal;

    if (delta > 0.0) {
        if (maxVal == c.r) {
            h = (c.g - c.b) / delta;
        } else if (maxVal == c.g) {
            h = 2.0 + (c.b - c.r) / delta;
        } else {
            h = 4.0 + (c.r - c.g) / delta;
        }
        h = fmod(h / 6.0 + 1.0, 1.0);
    }

    return float3(h, s, v);
}

// Converts HSV to RGB
inline float3 hsvToRgb(float3 hsv) {
    float h = hsv.x * 6.0;
    float s = hsv.y;
    float v = hsv.z;

    int i = int(h);
    float f = h - i;
    float p = v * (1.0 - s);
    float q = v * (1.0 - f * s);
    float t = v * (1.0 - (1.0 - f) * s);

    switch (i % 6) {
        case 0: return float3(v, t, p);
        case 1: return float3(q, v, p);
        case 2: return float3(p, v, t);
        case 3: return float3(p, q, v);
        case 4: return float3(t, p, v);
        case 5: return float3(v, p, q);
    }
    return float3(0.0, 0.0, 0.0);
}
