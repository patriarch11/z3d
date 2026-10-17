const std = @import("std");
const vec = @import("vec.zig");
const quat = @import("quat.zig");

pub const mat_rows = 4;

pub const identity = Mat{
    .{ 1, 0, 0, 0 },
    .{ 0, 1, 0, 0 },
    .{ 0, 0, 1, 0 },
    .{ 0, 0, 0, 1 },
};

pub const Mat = [mat_rows]vec.F32x4;

pub fn add(m0: Mat, m1: Mat) Mat {
    var res: Mat = undefined;

    inline for (0..mat_rows) |i| {
        res[i] = m0[i] + m1[i];
    }

    return res;
}
test "z3dmath.mat.add" {
    const cases = .{
        .{
            Mat{
                .{ 1, 2, 3, 4 },
                .{ 5, 6, 7, 8 },
                .{ 9, 10, 11, 12 },
                .{ 13, 14, 15, 16 },
            },
            Mat{
                .{ 16, 15, 14, 13 },
                .{ 12, 11, 10, 9 },
                .{ 8, 7, 6, 5 },
                .{ 4, 3, 2, 1 },
            },
            Mat{
                .{ 17, 17, 17, 17 },
                .{ 17, 17, 17, 17 },
                .{ 17, 17, 17, 17 },
                .{ 17, 17, 17, 17 },
            },
        },
        .{
            Mat{
                .{ -1, -2, -3, -4 },
                .{ 0, 0, 0, 0 },
                .{ 1.5, 2.5, 3.5, 4.5 },
                .{ 10, -10, 20, -20 },
            },
            Mat{
                .{ 1, 2, 3, 4 },
                .{ 0, 0, 0, 0 },
                .{ 0.5, 0.5, 0.5, 0.5 },
                .{ -5, 5, -10, 10 },
            },
            Mat{
                .{ 0, 0, 0, 0 },
                .{ 0, 0, 0, 0 },
                .{ 2, 3, 4, 5 },
                .{ 5, -5, 10, -10 },
            },
        },
    };

    inline for (cases) |case| {
        const result = add(case[0], case[1]);

        inline for (0..mat_rows) |i| {
            try vec.test_util.expectVecApproxEqAbs(case[2][i], result[i]);
        }
    }
}

pub fn sub(m0: Mat, m1: Mat) Mat {
    var res: Mat = undefined;

    inline for (0..mat_rows) |i| {
        res[i] = m0[i] - m1[i];
    }

    return res;
}
test "z3dmath.mat.sub" {
    const cases = .{
        .{
            Mat{
                .{ 10, 20, 30, 40 },
                .{ 50, 60, 70, 80 },
                .{ 90, 100, 110, 120 },
                .{ 130, 140, 150, 160 },
            },
            Mat{
                .{ 1, 2, 3, 4 },
                .{ 5, 6, 7, 8 },
                .{ 9, 10, 11, 12 },
                .{ 13, 14, 15, 16 },
            },
            Mat{
                .{ 9, 18, 27, 36 },
                .{ 45, 54, 63, 72 },
                .{ 81, 90, 99, 108 },
                .{ 117, 126, 135, 144 },
            },
        },
        .{
            Mat{
                .{ -1, -2, -3, -4 },
                .{ 0, 0, 0, 0 },
                .{ 1.5, 2.5, 3.5, 4.5 },
                .{ 10, -10, 20, -20 },
            },
            Mat{
                .{ 1, 2, 3, 4 },
                .{ 0, 0, 0, 0 },
                .{ 0.5, 0.5, 0.5, 0.5 },
                .{ -5, 5, -10, 10 },
            },
            Mat{
                .{ -2, -4, -6, -8 },
                .{ 0, 0, 0, 0 },
                .{ 1, 2, 3, 4 },
                .{ 15, -15, 30, -30 },
            },
        },
    };

    inline for (cases) |case| {
        const result = sub(case[0], case[1]);

        inline for (0..mat_rows) |i| {
            try vec.test_util.expectVecApproxEqAbs(case[2][i], result[i]);
        }
    }
}

pub fn mulVec(m: Mat, v: vec.Vec) vec.Vec {
    return vec.splat(v[0]) * m[0] +
        vec.splat(v[1]) * m[1] +
        vec.splat(v[2]) * m[2] +
        vec.splat(v[3]) * m[3];
}
test "z3dmath.mat.mulVec" {
    const cases = .{
        .{
            Mat{
                .{ 1, 2, 3, 4 },
                .{ 5, 6, 7, 8 },
                .{ 9, 10, 11, 12 },
                .{ 13, 14, 15, 16 },
            },
            vec.f32x4(1, 2, 3, 4),
            vec.f32x4(90, 100, 110, 120),
        },
        .{
            Mat{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
            vec.f32x4(3, -2, 5, 1),
            vec.f32x4(3, -2, 5, 1),
        },
        .{
            Mat{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 10, 20, 30, 1 },
            },
            vec.f32x4(2, 3, 4, 1),
            vec.f32x4(12, 23, 34, 1),
        },
        .{
            Mat{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 10, 20, 30, 1 },
            },
            vec.f32x4(2, 3, 4, 0),
            vec.f32x4(2, 3, 4, 0),
        },
    };

    inline for (cases) |case| {
        const result = mulVec(case[0], case[1]);

        try vec.test_util.expectVecApproxEqAbs(case[2], result);
    }
}

pub fn mulMat(m0: Mat, m1: Mat) Mat {
    var res: Mat = undefined;

    inline for (0..mat_rows) |i| {
        res[i] =
            vec.splat(m0[i][0]) * m1[0] +
            vec.splat(m0[i][1]) * m1[1] +
            vec.splat(m0[i][2]) * m1[2] +
            vec.splat(m0[i][3]) * m1[3];
    }

    return res;
}
test "z3dmath.mat.mulMat" {
    const cases = .{
        .{
            Mat{
                .{ 1, 2, 3, 4 },
                .{ 5, 6, 7, 8 },
                .{ 9, 10, 11, 12 },
                .{ 13, 14, 15, 16 },
            },
            Mat{
                .{ 16, 15, 14, 13 },
                .{ 12, 11, 10, 9 },
                .{ 8, 7, 6, 5 },
                .{ 4, 3, 2, 1 },
            },
            Mat{
                .{ 80, 70, 60, 50 },
                .{ 240, 214, 188, 162 },
                .{ 400, 358, 316, 274 },
                .{ 560, 502, 444, 386 },
            },
        },
        .{
            // Identity * Matrix = Matrix
            identity,
            Mat{
                .{ 2, 3, 4, 5 },
                .{ 6, 7, 8, 9 },
                .{ 10, 11, 12, 13 },
                .{ 14, 15, 16, 17 },
            },
            Mat{
                .{ 2, 3, 4, 5 },
                .{ 6, 7, 8, 9 },
                .{ 10, 11, 12, 13 },
                .{ 14, 15, 16, 17 },
            },
        },
        .{
            // Scale * Translation
            Mat{
                .{ 2, 0, 0, 0 },
                .{ 0, 3, 0, 0 },
                .{ 0, 0, 4, 0 },
                .{ 0, 0, 0, 1 },
            },
            Mat{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 10, 20, 30, 1 },
            },
            Mat{
                .{ 2, 0, 0, 0 },
                .{ 0, 3, 0, 0 },
                .{ 0, 0, 4, 0 },
                .{ 10, 20, 30, 1 },
            },
        },
    };

    inline for (cases) |case| {
        const result = mulMat(case[0], case[1]);

        inline for (0..mat_rows) |i| {
            try vec.test_util.expectVecApproxEqAbs(case[2][i], result[i]);
        }
    }
}

pub fn fromQuat(q: quat.Quat) Mat {
    const nq = quat.normalize(q);

    const xx_yy_zz = nq * nq;

    const xy_xz_yz = vec.swizzle(nq, .x, .x, .y, .w) * vec.swizzle(nq, .y, .z, .z, .w);
    const xw_yw_zw = vec.swizzle(nq, .x, .y, .z, .w) * vec.swizzle(nq, .w, .w, .w, .w);

    const xx, const yy, const zz = .{ 0, 1, 2 };
    const xy, const xz, const yz = .{ -1, -2, -3 };
    const xw, const yw, const zw = .{ -1, -2, -3 };

    // ----
    // r0 (1 - 2(y^2 + z^2), 2(xy + zw), 2(xz - yw), 0)
    // -----
    const r0_signs = vec.f32x4(1, 1, -1, 1); // r02: xz + yw -> xz + (-yw)
    const r0_correction = vec.f32x4(-1, 1, 1, 1); // r00: (y^2 + z^2) -> -(y^2 + z^2)
    const r0_base = vec.f32x4(1, 0, 0, 0); // r00: 1 + (-2(y^2 + z^2))

    // zig fmt: off
    // (y^2 + z^2), (xy + zw), (xz - yw), 0)
    var r0 =
        @shuffle(f32, xx_yy_zz, xy_xz_yz, [4]i32{yy, xy, xz, 0}) +
        @shuffle(f32, xx_yy_zz, xw_yw_zw, [4]i32{zz, zw, yw, 0}) * r0_signs;
    // zig fmt: on

    r0 = vec.applyMask(r0, vec.mask_xyz);
    r0 = r0_base + vec.splat(2) * (r0 * r0_correction);

    // ----
    // r1 (2(xy - zw), 1 - 2(x^2 + z^2), 2(yz + xw), 0)
    // -----
    const r1_signs = vec.f32x4(-1, 1, 1, 1);
    const r1_correction = vec.f32x4(1, -1, 1, 1);
    const r1_base = vec.f32x4(0, 1, 0, 0);

    // zig fmt: off
    var r1 =
        @shuffle(f32, xx_yy_zz, xy_xz_yz, [4]i32{xy, xx, yz, 0}) +
        @shuffle(f32, xx_yy_zz, xw_yw_zw, [4]i32{zw, zz, xw, 0}) * r1_signs;
    // zig fmt: on

    r1 = vec.applyMask(r1, vec.mask_xyz);
    r1 = r1_base + vec.splat(2) * (r1 * r1_correction);

    // ----
    // r2 (2(xz + yw), 2(yz - xw), 1 - 2(x^2 + y^2), 0)
    // -----
    const r2_signs = vec.f32x4(1, -1, 1, 1);
    const r2_correction = vec.f32x4(1, 1, -1, 1);
    const r2_base = vec.f32x4(0, 0, 1, 0);

    // zig fmt: off
    var r2 =
        @shuffle(f32, xx_yy_zz, xy_xz_yz, [4]i32{xz, yz, xx, 0}) +
        @shuffle(f32, xx_yy_zz, xw_yw_zw, [4]i32{yw, xw, yy, 0}) * r2_signs;
    // zig fmt: on

    r2 = vec.applyMask(r2, vec.mask_xyz);
    r2 = r2_base + vec.splat(2) * (r2 * r2_correction);

    return .{ r0, r1, r2, quat.identity };
}
test "fromQuat" {
    const toRad = std.math.degreesToRadians;

    const cases = .{
        .{
            .name = "identity",
            .q = quat.identity,
            .expected = identity,
        },
        .{
            .name = "rotate X 90",
            .q = quat.fromAxisAngle(vec.f32x4(1, 0, 0, 0), toRad(90.0)),
            .expected = Mat{
                vec.f32x4(1, 0, 0, 0),
                vec.f32x4(0, 0, 1, 0),
                vec.f32x4(0, -1, 0, 0),
                vec.f32x4(0, 0, 0, 1),
            },
        },
        .{
            .name = "rotate Y 90",
            .q = quat.fromAxisAngle(vec.f32x4(0, 1, 0, 0), toRad(90.0)),
            .expected = Mat{
                vec.f32x4(0, 0, -1, 0),
                vec.f32x4(0, 1, 0, 0),
                vec.f32x4(1, 0, 0, 0),
                vec.f32x4(0, 0, 0, 1),
            },
        },
        .{
            .name = "rotate Z 90",
            .q = quat.fromAxisAngle(vec.f32x4(0, 0, 1, 0), toRad(90.0)),
            .expected = Mat{
                vec.f32x4(0, 1, 0, 0),
                vec.f32x4(-1, 0, 0, 0),
                vec.f32x4(0, 0, 1, 0),
                vec.f32x4(0, 0, 0, 1),
            },
        },
        .{
            .name = "rotate X 180",
            .q = quat.fromAxisAngle(vec.f32x4(1, 0, 0, 0), toRad(180.0)),
            .expected = Mat{
                vec.f32x4(1, 0, 0, 0),
                vec.f32x4(0, -1, 0, 0),
                vec.f32x4(0, 0, -1, 0),
                vec.f32x4(0, 0, 0, 1),
            },
        },
        .{
            .name = "non-normalized quaternion",
            .q = quat.fromAxisAngle(vec.f32x4(0, 0, 1, 0), toRad(90.0)) * vec.splat(5),
            .expected = Mat{
                vec.f32x4(0, 1, 0, 0),
                vec.f32x4(-1, 0, 0, 0),
                vec.f32x4(0, 0, 1, 0),
                vec.f32x4(0, 0, 0, 1),
            },
        },
        .{
            .name = "rotate Z -90",
            .q = quat.fromAxisAngle(vec.f32x4(0, 0, 1, 0), toRad(-90.0)),
            .expected = Mat{
                vec.f32x4(0, -1, 0, 0),
                vec.f32x4(1, 0, 0, 0),
                vec.f32x4(0, 0, 1, 0),
                vec.f32x4(0, 0, 0, 1),
            },
        },
        .{
            .name = "rotate around diagonal axis 180",
            .q = quat.fromAxisAngle(vec.f32x4(1, 1, 0, 0), toRad(180.0)),
            .expected = Mat{
                vec.f32x4(0, 1, 0, 0),
                vec.f32x4(1, 0, 0, 0),
                vec.f32x4(0, 0, -1, 0),
                vec.f32x4(0, 0, 0, 1),
            },
        },
    };

    inline for (cases) |case| {
        const actual = fromQuat(case.q);

        inline for (0..4) |i| {
            vec.test_util.expectVecApproxEqAbs(case.expected[i], actual[i]) catch |err| {
                std.debug.print(
                    "\nCase: {s}, row: {d}\nExpected: {any}\nActual:   {any}\n",
                    .{ case.name, i, case.expected[i], actual[i] },
                );
                return err;
            };
        }
    }
}
