//
//  Structs.metal
//  particlelife
//
//  Created by Rob Silverman on 3/21/25.
//

#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;     // 8 bytes
    float2 velocity;     // 8 bytes
    int species;         // 4 bytes
    int _padding;        // 4 bytes to make it aligned to 32
};

struct ClickData {
    float2 position;     // 8 bytes
    float force;         // 4 bytes
    int _padding;        // 4 bytes to make it aligned to 16
};

struct ParticleSettings {
    float maxDistance;           // 4 bytes
    float minDistance;           // 4 bytes
    float beta;                  // 4 bytes
    float friction;              // 4 bytes

    float repulsion;             // 4 bytes
    float pointSize;             // 4 bytes
    float worldSize;             // 4 bytes
    float _padding1;             // 4 bytes → align next field

    uint speciesColorOffset;     // 4 bytes
    uint paletteIndex;           // 4 bytes
    uint colorEffect;            // 4 bytes
    uint _padding2;              // 4 bytes → align next field
};

// New unified struct for camera + zoom + windowSize
struct ViewSettings {
    float2 cameraPosition;   // 8 bytes
    float  zoomLevel;        // 4 bytes
    float  _padding1;        // 4 bytes → align next field

    float2 windowSize;       // 8 bytes
    float2 _padding2;        // 8 bytes → total = 32 bytes
};
