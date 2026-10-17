#include <metal_stdlib>
using namespace metal;

struct Vertex {
    packed_float2 position;
    packed_float4 color;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(
    uint vertex_id [[vertex_id]],
    const device Vertex* vertices [[buffer(0)]]
) {
    Vertex v = vertices[vertex_id];

    VertexOut out;
    out.position = float4(float2(v.position), 0.0, 1.0);
    out.color = float4(v.color);

    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
