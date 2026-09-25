#include <metal_stdlib>
using namespace metal;

// Full-screen triangle passthrough for the placeholder test pattern.
struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut passthroughVertex(uint vertexID [[vertex_id]]) {
    float2 positions[3] = { float2(-1.0, -1.0), float2(3.0, -1.0), float2(-1.0, 3.0) };
    float2 uvs[3] = { float2(0.0, 1.0), float2(2.0, 1.0), float2(0.0, -1.0) };
    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = uvs[vertexID];
    return out;
}

// Neutral grid pattern. Placeholder only: no game shaders exist.
fragment float4 patternFragment(VertexOut in [[stage_in]]) {
    float2 grid = fract(in.uv * 24.0);
    float line = step(grid.x, 0.04) + step(grid.y, 0.04);
    float3 base = float3(0.10, 0.12, 0.18);
    float3 tint = mix(base, float3(0.20, 0.45, 0.65), clamp(line, 0.0, 1.0));
    return float4(tint, 1.0);
}
