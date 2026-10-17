const std = @import("std");
const vec = @import("vec.zig");

pub const Quat = vec.F32x4;

pub const identity: Quat = vec.f32x4(0, 0, 0, 1);

pub fn fromAxisAngle(axis: vec.Vec, angle: f32) Quat {
    const half = angle * 0.5;

    const sin = @sin(half);
    const cos = @cos(half);

    const a = vec.normalize3(axis);

    var res = a * vec.splat(sin);
    res[3] = cos;

    return res;
}
test "z3dmath.quat.fromAxisAngle" {
    const toRad = std.math.degreesToRadians;

    const cases = .{
        // Identity rotation
        .{ vec.f32x4(1, 0, 0, 0), toRad(0.0), vec.f32x4(0, 0, 0, 1) },

        // 90 degrees around X
        .{ vec.f32x4(1, 0, 0, 0), toRad(90.0), vec.f32x4(0.7071068, 0, 0, 0.7071068) },

        // 90 degrees around Y
        .{ vec.f32x4(0, 1, 0, 0), toRad(90.0), vec.f32x4(0, 0.7071068, 0, 0.7071068) },

        // 90 degrees around Z
        .{ vec.f32x4(0, 0, 1, 0), toRad(90.0), vec.f32x4(0, 0, 0.7071068, 0.7071068) },

        // 180 degrees around X
        .{ vec.f32x4(1, 0, 0, 0), toRad(180.0), vec.f32x4(1, 0, 0, 0) },

        // Negative rotation
        .{ vec.f32x4(0, 1, 0, 0), toRad(-90.0), vec.f32x4(0, -0.7071068, 0, 0.7071068) },

        // Non-unit axis
        .{ vec.f32x4(0, 5, 0, 0), toRad(90.0), vec.f32x4(0, 0.7071068, 0, 0.7071068) },

        // Arbitrary axis
        .{ vec.f32x4(1, 1, 0, 0), toRad(180.0), vec.f32x4(0.7071068, 0.7071068, 0, 0) },
    };

    inline for (cases) |case| {
        const result = fromAxisAngle(case[0], case[1]);

        try vec.test_util.expectVecApproxEqAbs(case[2], result);
    }
}

pub fn mul(a: Quat, b: Quat) Quat {
    const u = vec.applyMask(a, vec.mask_xyz);
    const v = vec.applyMask(b, vec.mask_xyz);

    // zig fmt: off
    const xyz = vec.splat(a[3]) * v
        + vec.splat(b[3]) * u
        + vec.cross3(u, v);
    // zig fmt: on

    const w = a[3] * b[3] - vec.dot3(u, v)[0];

    return vec.f32x4(xyz[0], xyz[1], xyz[2], w);
}
test "z3dmath.quat.mul" {
    const h = 0.7071068;

    const qx = vec.f32x4(h, 0, 0, h);
    const qy = vec.f32x4(0, h, 0, h);
    const qz = vec.f32x4(0, 0, h, h);

    const cases = .{
        // Identity * identity
        .{ identity, identity, identity },

        // Right identity
        .{ qx, identity, qx },

        // Left identity
        .{ identity, qy, qy },

        // 90 degrees + 90 degrees around X
        .{ qx, qx, vec.f32x4(1, 0, 0, 0) },

        // 90 degrees + 90 degrees around Y
        .{ qy, qy, vec.f32x4(0, 1, 0, 0) },

        // X * Y
        .{ qx, qy, vec.f32x4(0.5, 0.5, 0.5, 0.5) },

        // Y * X
        .{ qy, qx, vec.f32x4(0.5, 0.5, -0.5, 0.5) },

        // X * Z
        .{ qx, qz, vec.f32x4(0.5, -0.5, 0.5, 0.5) },

        // Z * X
        .{ qz, qx, vec.f32x4(0.5, 0.5, 0.5, 0.5) },

        // Quaternion multiplied by its conjugate
        .{
            qx,
            vec.f32x4(-h, 0, 0, h),
            identity,
        },

        // Non-unit quaternions
        .{
            vec.f32x4(1, 2, 3, 4),
            vec.f32x4(5, 6, 7, 8),
            vec.f32x4(24, 48, 48, -6),
        },
    };

    inline for (cases) |case| {
        const result = mul(case[0], case[1]);

        try vec.test_util.expectVecApproxEqAbs(
            case[2],
            result,
        );
    }
}

pub fn normalize(q: Quat) Quat {
    return vec.normalize4(q);
}
