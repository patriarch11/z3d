const std = @import("std");
const matrix = @import("mat.zig");
const Mat = @import("mat.zig").Mat;
const Mat2f = @import("mat.zig").Mat2f;
const Mat3f = @import("mat.zig").Mat3f;
const Mat4f = @import("mat.zig").Mat4f;
const Vec2f = @import("_vec.zig").Vec2f;
const Vec3f = @import("_vec.zig").Vec3f;

const Mat2x3 = Mat(2, 3, f32);
const Mat2x4 = Mat(2, 4, f32);
const Mat3x4 = Mat(3, 4, f32);
const Mat3x2 = Mat(3, 2, f32);

test "Mat.add should sum two matricies" {
    const a = Mat3f.init([3][3]f32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    });
    const b = Mat3f.init([3][3]f32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    });

    const expected = Mat3f.init([3][3]f32{
        .{ 2, 4, 6 },
        .{ 8, 10, 12 },
        .{ 14, 16, 18 },
    });
    const actual = Mat3f.add(a, b);

    try std.testing.expectEqual(expected, actual);
}

test "Mat.sub should substract two matricies" {
    const a = Mat3f.init([3][3]f32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    });
    const b = Mat3f.init([3][3]f32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    });

    const expected = Mat3f.initZero();
    const actual = Mat3f.sub(a, b);

    try std.testing.expectEqual(expected, actual);
}

test "Mat.scale should scale matricies" {
    const a = Mat3f.init([3][3]f32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
        .{ 7, 8, 9 },
    });
    const k = 2.0;

    const expected = Mat3f.init([3][3]f32{
        .{ 2, 4, 6 },
        .{ 8, 10, 12 },
        .{ 14, 16, 18 },
    });
    const actual = Mat3f.scale(a, k);

    try std.testing.expectEqual(expected, actual);
}

test "Mat.mul should multiply square 2 matricies" {
    const a = Mat2f.init([2][2]f32{
        .{ 1, 2 },
        .{ 3, 4 },
    });
    const b = Mat2f.init([2][2]f32{
        .{ 5, 6 },
        .{ 7, 8 },
    });

    const expected = Mat2f.init([2][2]f32{
        .{ 19, 22 },
        .{ 43, 50 },
    });
    const actual = Mat2f.mul(a, 2, b);

    try std.testing.expectEqual(expected, actual);
}

test "Mat.mul should multiply 2 rectangular matricies" {
    const a = Mat2x3.init(.{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
    });

    const b = Mat3x4.init(.{
        .{ 7, 8, 9, 10 },
        .{ 11, 12, 13, 14 },
        .{ 15, 16, 17, 18 },
    });

    const expected = Mat2x4.init(.{
        .{ 74, 80, 86, 92 },
        .{ 173, 188, 203, 218 },
    });
    const actual = Mat2x3.mul(a, 4, b);

    try std.testing.expectEqual(expected, actual);
}

test "Mat3f.initIdentity should create identity matrix" {
    const expected = Mat3f.init([3][3]f32{
        .{ 1, 0, 0 },
        .{ 0, 1, 0 },
        .{ 0, 0, 1 },
    });
    const actual = Mat3f.initIdentity();

    try std.testing.expectEqual(expected, actual);
}

test "Mat.mulVec should return vector with the same dim, as matrix columns" {
    const mat = Mat2x3.init([2][3]f32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
    });
    const vec = Vec3f.init([3]f32{ 7, 8, 9 });

    const expected = Vec2f.init([2]f32{ 50, 122 });
    const actual = Mat2x3.mulVec(mat, vec);

    try std.testing.expectEqual(expected, actual);
}

test "Mat.transpose shoud transpose a matrix" {
    const mat = Mat2x3.init([2][3]f32{
        .{ 1, 2, 3 },
        .{ 4, 5, 6 },
    });

    const expected = Mat3x2.init([3][2]f32{
        .{ 1, 4 },
        .{ 2, 5 },
        .{ 3, 6 },
    });
    const actual = Mat2x3.transpose(mat);

    try std.testing.expectEqual(expected, actual);
}

test "matrix.translate shoud return the translation matrix" {
    const offset = Vec3f.init([3]f32{ 2, 3, 4 });

    const expected = Mat4f.init([4][4]f32{
        .{ 1, 0, 0, 2 },
        .{ 0, 1, 0, 3 },
        .{ 0, 0, 1, 4 },
        .{ 0, 0, 0, 1 },
    });
    const actual = matrix.translate(offset);

    try std.testing.expectEqual(expected, actual);
}

test "matrix.scaling shoud return the scaling matrix" {
    const s = Vec3f.init([3]f32{ 2, 3, 4 });

    const expected = Mat4f.init([4][4]f32{
        .{ 2, 0, 0, 0 },
        .{ 0, 3, 0, 0 },
        .{ 0, 0, 4, 0 },
        .{ 0, 0, 0, 1 },
    });
    const actual = matrix.scaling(s);

    try std.testing.expectEqual(expected, actual);
}

test "matrix.rotateX should return the rotation matrix around X axis" {
    const angle: f32 = std.math.pi / 2.0;

    const expected = Mat4f.init(.{
        .{ 1, 0, 0, 0 },
        .{ 0, 0, -1, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 0, 1 },
    });
    const actual = matrix.rotateX(angle);

    for (0..4) |row| {
        for (0..4) |col| {
            try std.testing.expectApproxEqAbs(
                expected.data[row][col],
                actual.data[row][col],
                0.00001,
            );
        }
    }
}

test "matrix.rotateY should return the rotation matrix around Y axis" {
    const angle: f32 = std.math.pi / 2.0;

    const expected = Mat4f.init(.{
        .{ 0, 0, 1, 0 },
        .{ 0, 1, 0, 0 },
        .{ -1, 0, 0, 0 },
        .{ 0, 0, 0, 1 },
    });
    const actual = matrix.rotateY(angle);

    for (0..4) |row| {
        for (0..4) |col| {
            try std.testing.expectApproxEqAbs(
                expected.data[row][col],
                actual.data[row][col],
                0.00001,
            );
        }
    }
}

test "matrix.rotateZ should return the rotation matrix around Z axis" {
    const angle: f32 = std.math.pi / 2.0;

    const expected = Mat4f.init(.{
        .{ 0, -1, 0, 0 },
        .{ 1, 0, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    });
    const actual = matrix.rotateZ(angle);

    for (0..4) |row| {
        for (0..4) |col| {
            try std.testing.expectApproxEqAbs(
                expected.data[row][col],
                actual.data[row][col],
                0.00001,
            );
        }
    }
}
