const vec = @import("vec.zig");

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
