const std = @import("std");
const trs = @import("transform.zig");
const Vec3f = @import("vec.zig").Vec3f;
const Mat4f = @import("mat.zig").Mat4f;
const Quatf = @import("quat.zig").Quatf;

const tolerance: f32 = 1e-5;

const axis_x = Vec3f.init(.{ 1, 0, 0 });
const axis_y = Vec3f.init(.{ 0, 1, 0 });
const axis_z = Vec3f.init(.{ 0, 0, 1 });

fn deg(d: f32) f32 {
    return std.math.degreesToRadians(d);
}

fn expectVecApproxEq(expected: Vec3f, actual: Vec3f) !void {
    for (expected.data, actual.data) |e, a| {
        try std.testing.expectApproxEqAbs(e, a, tolerance);
    }
}

fn expectMatApproxEq(expected: Mat4f, actual: Mat4f) !void {
    for (expected.data, actual.data) |expected_row, actual_row| {
        for (expected_row, actual_row) |e, a| {
            try std.testing.expectApproxEqAbs(e, a, tolerance);
        }
    }
}

test "trs.makeTransform should create a transformation matrix" {
    const scale = Vec3f.init(.{ 2, 2, 2 });
    const rotation = Quatf.fromAxisAngle(axis_z, deg(90));
    const translation = Vec3f.init(.{ 5, 0, 0 });

    const expected = Mat4f.init(.{
        .{ 0, -2, 0, 5 },
        .{ 2, 0, 0, 0 },
        .{ 0, 0, 2, 0 },
        .{ 0, 0, 0, 1 },
    });

    const actual = trs.makeTransform(translation, rotation, scale);

    try expectMatApproxEq(expected, actual);
}

test "trs.makeTransform should return identity matrix" {
    const translation = Vec3f.init(.{ 0, 0, 0 });
    const rotation = Quatf.initIdentity();
    const scale = Vec3f.init(.{ 1, 1, 1 });

    const expected = Mat4f.initIdentity();
    const actual = trs.makeTransform(translation, rotation, scale);

    try expectMatApproxEq(expected, actual);
}

test "trs.makeTransform should apply translation only" {
    const translation = Vec3f.init(.{ 5, -3, 2 });
    const rotation = Quatf.initIdentity();
    const scale = Vec3f.init(.{ 1, 1, 1 });

    const expected = Mat4f.init(.{
        .{ 1, 0, 0, 5 },
        .{ 0, 1, 0, -3 },
        .{ 0, 0, 1, 2 },
        .{ 0, 0, 0, 1 },
    });

    const actual = trs.makeTransform(translation, rotation, scale);

    try expectMatApproxEq(expected, actual);
}

test "trs.makeTransform should apply non-uniform scaling" {
    const translation = Vec3f.init(.{ 0, 0, 0 });
    const rotation = Quatf.initIdentity();
    const scale = Vec3f.init(.{ 2, 3, 4 });

    const expected = Mat4f.init(.{
        .{ 2, 0, 0, 0 },
        .{ 0, 3, 0, 0 },
        .{ 0, 0, 4, 0 },
        .{ 0, 0, 0, 1 },
    });

    const actual = trs.makeTransform(translation, rotation, scale);

    try expectMatApproxEq(expected, actual);
}

test "trs.transformPoint should map origin to translation" {
    const translation = Vec3f.init(.{ 5, -3, 7 });
    // Довільний поворот: X(30°), потім Y(45°), потім Z(60°)
    const rotation = Quatf.mul(
        Quatf.mul(
            Quatf.fromAxisAngle(axis_z, deg(60)),
            Quatf.fromAxisAngle(axis_y, deg(45)),
        ),
        Quatf.fromAxisAngle(axis_x, deg(30)),
    );
    const scale = Vec3f.init(.{ 2, 3, 4 });

    const matrix = trs.makeTransform(translation, rotation, scale);
    const position = Vec3f.init(.{ 0, 0, 0 });

    const actual = trs.transformPoint(matrix, position);

    try expectVecApproxEq(translation, actual);
}

test "trs.transformPoint should transform a point" {
    const scale = Vec3f.init(.{ 2, 2, 2 });
    const rotation = Quatf.fromAxisAngle(axis_z, deg(90));
    const translation = Vec3f.init(.{ 5, 0, 0 });

    const matrix = trs.makeTransform(translation, rotation, scale);

    const position = Vec3f.init(.{ 1, 1, 0 });
    const expected = Vec3f.init(.{ 3, 2, 0 });

    const actual = trs.transformPoint(matrix, position);

    try expectVecApproxEq(expected, actual);
}

test "trs.transformPoint should apply composed quaternion rotations (X, then Y, then Z)" {
    const translation = Vec3f.init(.{ 0, 0, 0 });
    // q = qz * qy * qx  =>  спершу X, потім Y, потім Z
    const rotation = Quatf.mul(
        Quatf.mul(
            Quatf.fromAxisAngle(axis_z, deg(90)),
            Quatf.fromAxisAngle(axis_y, deg(90)),
        ),
        Quatf.fromAxisAngle(axis_x, deg(90)),
    );
    const scale = Vec3f.init(.{ 1, 1, 1 });

    const matrix = trs.makeTransform(translation, rotation, scale);

    const position = Vec3f.init(.{ 1, 2, 3 });
    // (1,2,3) -X90-> (1,-3,2) -Y90-> (2,-3,-1) -Z90-> (3,2,-1)
    const expected = Vec3f.init(.{ 3, 2, -1 });
    const actual = trs.transformPoint(matrix, position);

    try expectVecApproxEq(expected, actual);
}
