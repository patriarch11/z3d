const std = @import("std");

pub const Vec = @Vector(4, f32);

pub fn vec2(x: f32, y: f32) Vec {
    return .{ x, y, 0.0, 0.0 };
}

pub fn vec3(x: f32, y: f32, z: f32) Vec {
    return .{ x, y, z, 0.0 };
}

pub fn vec4(x: f32, y: f32, z: f32, w: f32) Vec {
    return .{ x, y, z, w };
}

pub const VecComponent = enum { x, y, z, w };

pub inline fn swizzle(
    v: Vec,
    comptime x: VecComponent,
    comptime y: VecComponent,
    comptime z: VecComponent,
    comptime w: VecComponent,
) Vec {
    return @shuffle(f32, v, undefined, [4]i32{ @backingInt(x), @backingInt(y), @backingInt(z), @backingInt(w) });
}

pub inline fn dot2(v0: Vec, v1: Vec) f32 {
    const m = v0 * v1; // | x0*x1 | y0 * y1 | -- | -- |
    return m[0] + m[1];
}
test "z3dmath.dot2" {
    try std.testing.expectEqual(18, dot2(vec2(12, 3), vec2(1, 2)));
}

pub inline fn dot3(v0: Vec, v1: Vec) f32 {
    const m = v0 * v1;
    return m[0] + m[1] + m[2];
}
test "z3dmath.dot3" {
    try std.testing.expectEqual(26, dot3(vec3(12, 3, 4), vec3(1, 2, 2)));
}

pub inline fn dot4(v0: Vec, v1: Vec) f32 {
    return @reduce(.Add, v0 * v1);
}
test "z3dmath.dot4" {
    try std.testing.expectEqual(30, dot4(vec4(12, 3, 4, 2), vec4(1, 2, 2, 2)));
}

pub inline fn cross3(v0: Vec, v1: Vec) Vec {
    return swizzle(v0, .y, .z, .x, .w) * swizzle(v1, .z, .x, .y, .w) -
        swizzle(v0, .z, .x, .y, .w) * swizzle(v1, .y, .z, .x, .w);
}
test "z3dmath.cross3" {
    const v0 = vec3(1, 0, 0);
    const v1 = vec3(0, 1, 0);

    try std.testing.expectEqual(vec3(0, 0, 1), cross3(v0, v1));
    try std.testing.expectEqual(0, dot3(cross3(v0, v1), v0));
}

pub inline fn lenSq2(v: Vec) f32 {
    return dot2(v, v);
}
pub inline fn lenSq3(v: Vec) f32 {
    return dot3(v, v);
}
pub inline fn lenSq4(v: Vec) f32 {
    return dot4(v, v);
}

pub inline fn len2(v: Vec) f32 {
    return @sqrt(dot2(v, v));
}
pub inline fn len3(v: Vec) f32 {
    return @sqrt(dot3(v, v));
}
pub inline fn len4(v: Vec) f32 {
    return @sqrt(dot4(v, v));
}

pub inline fn normalize2(v: Vec) Vec {
    return v / len2(v);
}
pub inline fn normalize3(v: Vec) Vec {
    return v / len3(v);
}
pub inline fn normalize4(v: Vec) Vec {
    return v / len4(v);
}
