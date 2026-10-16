const std = @import("std");
const trs = @import("transform.zig");
const Vec3f = @import("vec.zig").Vec3f;
const Mat4f = @import("mat.zig").Mat4f;

test "trs.makeTransform should create a transformation matrix" {
    const scale = Vec3f.init(.{ 2, 2, 2 });
    const rotation = Vec3f.init(.{
        0,
        0,
        std.math.degreesToRadians(90),
    });
    const translation = Vec3f.init(.{ 5, 0, 0 });

    const expected = Mat4f.init(.{
        .{ 0, -2, 0, 5 },
        .{ 2, 0, 0, 0 },
        .{ 0, 0, 2, 0 },
        .{ 0, 0, 0, 1 },
    });

    const actual = trs.makeTransform(translation, rotation, scale);

    const tolerance: f32 = 1e-5;

    for (expected.data, actual.data) |expected_row, actual_row| {
        for (expected_row, actual_row) |e, a| {
            try std.testing.expectApproxEqAbs(e, a, tolerance);
        }
    }
}

test "trs.makeTransform should return identity matrix" {
    const translation = Vec3f.init(.{ 0, 0, 0 });
    const rotation = Vec3f.init(.{ 0, 0, 0 });
    const scale = Vec3f.init(.{ 1, 1, 1 });

    const expected = Mat4f.initIdentity();
    const actual = trs.makeTransform(translation, rotation, scale);

    try std.testing.expectEqual(expected, actual);
}

test "trs.makeTransform should apply translation only" {
    const translation = Vec3f.init(.{ 5, -3, 2 });
    const rotation = Vec3f.init(.{ 0, 0, 0 });
    const scale = Vec3f.init(.{ 1, 1, 1 });

    const expected = Mat4f.init(.{
        .{ 1, 0, 0, 5 },
        .{ 0, 1, 0, -3 },
        .{ 0, 0, 1, 2 },
        .{ 0, 0, 0, 1 },
    });

    const actual = trs.makeTransform(translation, rotation, scale);

    try std.testing.expectEqual(expected, actual);
}

test "trs.makeTransform should apply non-uniform scaling" {
    const translation = Vec3f.init(.{ 0, 0, 0 });
    const rotation = Vec3f.init(.{ 0, 0, 0 });
    const scale = Vec3f.init(.{ 2, 3, 4 });

    const expected = Mat4f.init(.{
        .{ 2, 0, 0, 0 },
        .{ 0, 3, 0, 0 },
        .{ 0, 0, 4, 0 },
        .{ 0, 0, 0, 1 },
    });

    const actual = trs.makeTransform(translation, rotation, scale);

    try std.testing.expectEqual(expected, actual);
}

test "trs.transformPoint should map origin to translation" {
    const translation = Vec3f.init(.{ 5, -3, 7 });
    const rotation = Vec3f.init(.{
        std.math.degreesToRadians(30),
        std.math.degreesToRadians(45),
        std.math.degreesToRadians(60),
    });
    const scale = Vec3f.init(.{ 2, 3, 4 });

    const matrix = trs.makeTransform(translation, rotation, scale);
    const position = Vec3f.init(.{ 0, 0, 0 });

    const expected = translation;
    const actual = trs.transformPoint(matrix, position);

    const tolerance: f32 = 1e-5;

    for (expected.data, actual.data) |e, a| {
        try std.testing.expectApproxEqAbs(e, a, tolerance);
    }
}

test "trs.transformPoint should transform a point" {
    const scale = Vec3f.init(.{ 2, 2, 2 });
    const rotation = Vec3f.init(.{
        0,
        0,
        std.math.degreesToRadians(90),
    });
    const translation = Vec3f.init(.{ 5, 0, 0 });

    const matrix = trs.makeTransform(translation, rotation, scale);

    const position = Vec3f.init(.{ 1, 1, 0 });
    const expected = Vec3f.init(.{ 3, 2, 0 });

    const actual = trs.transformPoint(matrix, position);

    const tolerance: f32 = 1e-5;

    for (expected.data, actual.data) |e, a| {
        try std.testing.expectApproxEqAbs(e, a, tolerance);
    }
}

test "trs.transformPoint should apply rotations in XYZ order" {
    const translation = Vec3f.init(.{ 0, 0, 0 });
    const rotation = Vec3f.init(.{
        std.math.degreesToRadians(90),
        std.math.degreesToRadians(90),
        std.math.degreesToRadians(90),
    });
    const scale = Vec3f.init(.{ 1, 1, 1 });

    const matrix = trs.makeTransform(translation, rotation, scale);

    const position = Vec3f.init(.{ 1, 2, 3 });
    const expected = Vec3f.init(.{ 3, 2, -1 });
    const actual = trs.transformPoint(matrix, position);

    const tolerance: f32 = 1e-5;

    for (expected.data, actual.data) |e, a| {
        try std.testing.expectApproxEqAbs(e, a, tolerance);
    }
}
