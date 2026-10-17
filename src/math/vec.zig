const std = @import("std");

pub const veclen = 4;

pub const F32x4 = @Vector(veclen, f32);
pub const Boolx4 = @Vector(veclen, bool);

pub const Vec = F32x4;

pub const mask_xy = Boolx4{ true, true, false, false };
pub const mask_xyz = Boolx4{ true, true, true, false };

pub inline fn f32x4(x: f32, y: f32, z: f32, w: f32) F32x4 {
    return .{ x, y, z, w };
}

pub inline fn f32x4s(e: f32) F32x4 {
    return splat(e);
}

pub const F32x4Comp = enum {
    x,
    y,
    z,
    w,
    pub inline fn mask(
        comptime x: F32x4Comp,
        comptime y: F32x4Comp,
        comptime z: F32x4Comp,
        comptime w: F32x4Comp,
    ) [4]i32 {
        return [4]i32{ @backingInt(x), @backingInt(y), @backingInt(z), @backingInt(w) };
    }
};

pub inline fn swizzle_mask(v: F32x4, mask: [4]i32) F32x4 {
    return @shuffle(f32, v, undefined, mask);
}

pub inline fn swizzle(
    v: F32x4,
    comptime x: F32x4Comp,
    comptime y: F32x4Comp,
    comptime z: F32x4Comp,
    comptime w: F32x4Comp,
) F32x4 {
    return @shuffle(
        f32,
        v,
        undefined,
        [4]i32{ @backingInt(x), @backingInt(y), @backingInt(z), @backingInt(w) },
    );
}

pub inline fn splat(e: f32) F32x4 {
    return @splat(e);
}

pub inline fn applyMask(v: F32x4, mask: Boolx4) F32x4 {
    return @select(
        f32,
        mask,
        v,
        splat(0),
    );
}

pub inline fn dot2(v0: Vec, v1: Vec) F32x4 {
    const m = v0 * v1; // | x0*x1 | y0 * y1 | -- | -- |
    return splat(m[0] + m[1]);
}
test "z3dmath.vec.dot2" {
    try test_util.expectVecApproxEqAbs(
        splat(-7),
        dot2(f32x4(1, -2, 23, -299.3), f32x4(3, 5, 23, -299.3)),
    );
}

pub inline fn dot3(v0: Vec, v1: Vec) F32x4 {
    const m = v0 * v1;
    return splat(m[0] + m[1] + m[2]);
}
test "z3dmath.vec.dot3" {
    try test_util.expectVecApproxEqAbs(
        splat(5),
        dot3(f32x4(1, -2, 4, -299.3), f32x4(3, 5, 3, -299.3)),
    );
}

pub inline fn dot4(v0: Vec, v1: Vec) F32x4 {
    return splat(@reduce(.Add, v0 * v1));
}
test "z3dmath.vec.dot4" {
    try test_util.expectVecApproxEqAbs(
        splat(2),
        dot4(f32x4(1, -2, 4, 6), f32x4(3, 5, 3, -0.5)),
    );
}

pub inline fn cross3(v0: Vec, v1: Vec) Vec {
    const mask_yzxw = F32x4Comp.mask(.y, .z, .x, .w);
    const mask_zxyw = F32x4Comp.mask(.z, .x, .y, .w);
    // zig fmt: off
    return applyMask(
        swizzle_mask(v0, mask_yzxw) * swizzle_mask(v1, mask_zxyw) -
        swizzle_mask(v0, mask_zxyw) * swizzle_mask(v1, mask_yzxw),
        mask_xyz,
    );
    // zig fmt: on

}
test "z3dmath.vec.cross3" {
    const cases = .{
        .{ f32x4(1, 0, 0, -23.01), f32x4(0, 1, 0, -23.01), f32x4(0, 0, 1, 0) },
        .{ f32x4(0, 1, 0, 3.01), f32x4(1, 0, 0, -23.01), f32x4(0, 0, -1, 0) },
        .{ f32x4(1, 0, 0, -23.01), f32x4(1, 0, 0, -3.031), f32x4(0, 0, 0, 0) },
        .{ f32x4(1, 2, 3, -23.01), f32x4(4, 5, 6, -23.01), f32x4(-3, 6, -3, 0) },
        .{ f32x4(4, 5, 6, -23.01), f32x4(1, 2, 3, -23.01), f32x4(3, -6, 3, 0) },
    };

    inline for (cases) |case| {
        const result = cross3(case[0], case[1]);

        try test_util.expectVecApproxEqAbs(case[2], result);
        try test_util.expectVecApproxEqAbs(splat(0), dot3(result, case[0]));
        try test_util.expectVecApproxEqAbs(splat(0), dot3(result, case[1]));
        try std.testing.expectEqual(0, result[3]);
    }
}

pub inline fn lenSq2(v: Vec) F32x4 {
    return dot2(v, v);
}
pub inline fn lenSq3(v: Vec) F32x4 {
    return dot3(v, v);
}
pub inline fn lenSq4(v: Vec) F32x4 {
    return dot4(v, v);
}
test "z3dmath.vec.lenSq2" {
    const cases = .{
        .{ f32x4(3, 4, 12, 3), splat(25) },
        .{ f32x4(0, 0, 12, 3), splat(0) },
        .{ f32x4(-3, -4, 2, 1), splat(25.0) },
    };

    inline for (cases) |case| {
        try test_util.expectVecApproxEqAbs(case[1], lenSq2(case[0]));
    }
}
test "z3dmath.vec.lenSq3" {
    const cases = .{
        .{ f32x4(2, 3, 6, 10), splat(49.0) },
        .{ f32x4(0, 0, 0, 15), splat(0.0) },
        .{ f32x4(-2, -3, -6, 13), splat(49.0) },
    };

    inline for (cases) |case| {
        try test_util.expectVecApproxEqAbs(case[1], lenSq3(case[0]));
    }
}
test "z3dmath.vec.lenSq4" {
    const cases = .{
        .{ f32x4(1, 2, 3, 4), splat(30.0) },
        .{ f32x4(0, 0, 0, 0), splat(0.0) },
        .{ f32x4(0, 0, 0, -2), splat(4.0) },
    };

    inline for (cases) |case| {
        try test_util.expectVecApproxEqAbs(case[1], lenSq4(case[0]));
    }
}

pub inline fn len2(v: Vec) F32x4 {
    return @sqrt(dot2(v, v));
}
pub inline fn len3(v: Vec) F32x4 {
    return @sqrt(dot3(v, v));
}
pub inline fn len4(v: Vec) F32x4 {
    return @sqrt(dot4(v, v));
}
test "z3dmath.vec.len2" {
    const cases = .{
        .{ f32x4(3, 4, 1, -10), splat(5.0) },
        .{ f32x4(0, 0, 12, -22.312), splat(0.0) },
        .{ f32x4(-3, -4, 1, 5), splat(5.0) },
    };

    inline for (cases) |case| {
        try test_util.expectVecApproxEqAbs(case[1], len2(case[0]));
    }
}
test "z3dmath.vec.len3" {
    const cases = .{
        .{ f32x4(2, 3, 6, -12.33), splat(7.0) },
        .{ f32x4(0, 0, 0, -12.33), splat(0.0) },
        .{ f32x4(0, 3, 4, -12.33), splat(5.0) },
    };

    inline for (cases) |case| {
        try test_util.expectVecApproxEqAbs(case[1], len3(case[0]));
    }
}
test "z3dmath.vec.len4" {
    const cases = .{
        .{ f32x4(1, 2, 2, 4), splat(5.0) },
        .{ f32x4(0, 0, 0, 0), splat(0.0) },
        .{ f32x4(0, 0, 0, -2), splat(2.0) },
    };

    inline for (cases) |case| {
        try std.testing.expectEqual(case[1], len4(case[0]));
    }
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
test "z3dmath.vec.normalize2" {
    const cases = .{
        .{ f32x4(3, 4, 0, 0), f32x4(0.6, 0.8, 0, 0) },
        .{ f32x4(5, 0, 0, 0), f32x4(1, 0, 0, 0) },
        .{ f32x4(-5, 0, 0, 0), f32x4(-1, 0, 0, 0) },
        .{ f32x4(0, -5, 0, 0), f32x4(0, -1, 0, 0) },
    };

    inline for (cases) |case| {
        const result = normalize2(case[0]);

        try test_util.expectVecApproxEqAbs(case[1], result);
        try std.testing.expectApproxEqAbs(@as(f32, 1), len2(result)[0], 1e-6);
    }
}
test "z3dmath.vec.normalize3" {
    const cases = .{
        .{ f32x4(0, 3, 4, 0), f32x4(0, 0.6, 0.8, 0) },
        .{ f32x4(5, 0, 0, 0), f32x4(1, 0, 0, 0) },
        .{ f32x4(0, -5, 0, 0), f32x4(0, -1, 0, 0) },
        .{ f32x4(2, 3, 6, 0), f32x4(2.0 / 7.0, 3.0 / 7.0, 6.0 / 7.0, 0) },
    };

    inline for (cases) |case| {
        const result = normalize3(case[0]);

        try test_util.expectVecApproxEqAbs(case[1], result);
        try std.testing.expectApproxEqAbs(@as(f32, 1), len3(result)[0], 1e-6);
    }
}
test "z3dmath.vec.normalize4" {
    const cases = .{
        .{ f32x4(1, 2, 2, 4), f32x4(0.2, 0.4, 0.4, 0.8) },
        .{ f32x4(5, 0, 0, 0), f32x4(1, 0, 0, 0) },
        .{ f32x4(0, 0, 0, -5), f32x4(0, 0, 0, -1) },
        .{ f32x4(0, 3, 4, 0), f32x4(0, 0.6, 0.8, 0) },
    };

    inline for (cases) |case| {
        const result = normalize4(case[0]);

        try test_util.expectVecApproxEqAbs(case[1], result);
        try std.testing.expectApproxEqAbs(@as(f32, 1), len4(result)[0], 1e-6);
    }
}

pub const test_util = struct {
    pub const tolerance = 0.0001;

    pub fn expectVecApproxEqAbs(expected: F32x4, actual: F32x4) !void {
        inline for (0..veclen) |i| {
            try std.testing.expectApproxEqAbs(expected[i], actual[i], tolerance);
        }
    }
};
