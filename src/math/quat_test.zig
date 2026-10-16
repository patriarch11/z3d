const std = @import("std");
const Quaternion = @import("quat.zig").Quaternion;
const Vec = @import("_vec.zig").Vec;
const Mat = @import("mat.zig").Mat;

const Quatf = Quaternion(f32);
const Vec3f = Vec(3, f32);
const Mat3f = Mat(3, 3, f32);
const Mat4f = Mat(4, 4, f32);

const epsilon: f32 = 0.00001;

fn expectQuatApproxEq(expected: Quatf, actual: Quatf) !void {
    try std.testing.expectApproxEqAbs(expected.x, actual.x, epsilon);
    try std.testing.expectApproxEqAbs(expected.y, actual.y, epsilon);
    try std.testing.expectApproxEqAbs(expected.z, actual.z, epsilon);
    try std.testing.expectApproxEqAbs(expected.w, actual.w, epsilon);
}

fn expectVec3ApproxEq(expected: Vec3f, actual: Vec3f) !void {
    for (0..3) |i| {
        try std.testing.expectApproxEqAbs(
            expected.data[i],
            actual.data[i],
            epsilon,
        );
    }
}

fn expectMat3ApproxEq(expected: Mat3f, actual: Mat3f) !void {
    for (0..3) |row| {
        for (0..3) |col| {
            try std.testing.expectApproxEqAbs(
                expected.data[row][col],
                actual.data[row][col],
                epsilon,
            );
        }
    }
}

fn expectMat4ApproxEq(expected: Mat4f, actual: Mat4f) !void {
    for (0..4) |row| {
        for (0..4) |col| {
            try std.testing.expectApproxEqAbs(
                expected.data[row][col],
                actual.data[row][col],
                epsilon,
            );
        }
    }
}

test "Quaternion.initIdentity should return identity quaternion" {
    const expected = Quatf.init(0, 0, 0, 1);
    const actual = Quatf.initIdentity();

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.lengthSquared should return squared quaternion length" {
    const q = Quatf.init(1, 2, 3, 4);

    const expected: f32 = 30;
    const actual = q.lengthSquared();

    try std.testing.expectApproxEqAbs(expected, actual, epsilon);
}

test "Quaternion.length should return quaternion length" {
    const q = Quatf.init(1, 2, 3, 4);

    const expected: f32 = @sqrt(@as(f32, 30));
    const actual = q.length();

    try std.testing.expectApproxEqAbs(expected, actual, epsilon);
}

test "Quaternion.normalize should return unit quaternion" {
    const q = Quatf.init(0, 3, 0, 4);

    const expected = Quatf.init(0, 0.6, 0, 0.8);
    const actual = q.normalize();

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.normalize should preserve identity quaternion" {
    const q = Quatf.initIdentity();

    const expected = Quatf.initIdentity();
    const actual = q.normalize();

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.conjugate should negate vector part" {
    const q = Quatf.init(1, 2, 3, 4);

    const expected = Quatf.init(-1, -2, -3, 4);
    const actual = q.conjugate();

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.invert should return inverse quaternion" {
    const q = Quatf.init(1, 2, 3, 4);

    const expected = Quatf.init(
        -1.0 / 30.0,
        -2.0 / 30.0,
        -3.0 / 30.0,
        4.0 / 30.0,
    );
    const actual = q.invert();

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.invert should produce identity when multiplied by original" {
    const q = Quatf.init(1, 2, 3, 4);

    const expected = Quatf.initIdentity();
    const actual = Quatf.mul(q, q.invert());

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.mul should multiply two quaternions" {
    const a = Quatf.init(1, 2, 3, 4);
    const b = Quatf.init(5, 6, 7, 8);

    const expected = Quatf.init(24, 48, 48, -6);
    const actual = Quatf.mul(a, b);

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.mul should preserve quaternion when multiplied by identity" {
    const q = Quatf.init(1, 2, 3, 4);
    const identity = Quatf.initIdentity();

    const expected = q;
    const actual = Quatf.mul(q, identity);

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.fromAxisAngle should create quaternion from X axis rotation" {
    const axis = Vec3f.init(.{ 1, 0, 0 });
    const angle: f32 = std.math.pi / 2.0;

    const expected = Quatf.init(
        @sqrt(@as(f32, 0.5)),
        0,
        0,
        @sqrt(@as(f32, 0.5)),
    );
    const actual = Quatf.fromAxisAngle(axis, angle);

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.fromAxisAngle should return identity for zero angle" {
    const axis = Vec3f.init(.{ 0, 1, 0 });
    const angle: f32 = 0;

    const expected = Quatf.initIdentity();
    const actual = Quatf.fromAxisAngle(axis, angle);

    try expectQuatApproxEq(expected, actual);
}

test "Quaternion.rotateVec3 should rotate vector 90 degrees around Z axis" {
    const axis = Vec3f.init(.{ 0, 0, 1 });
    const angle: f32 = std.math.pi / 2.0;
    const q = Quatf.fromAxisAngle(axis, angle);

    const v = Vec3f.init(.{ 1, 0, 0 });

    const expected = Vec3f.init(.{ 0, 1, 0 });
    const actual = Quatf.rotateVec3(q, v);

    try expectVec3ApproxEq(expected, actual);
}

test "Quaternion.rotateVec3 should preserve vector with identity quaternion" {
    const q = Quatf.initIdentity();
    const v = Vec3f.init(.{ 1, 2, 3 });

    const expected = v;
    const actual = Quatf.rotateVec3(q, v);

    try expectVec3ApproxEq(expected, actual);
}

test "Quaternion.toMat3 should return rotation matrix around Z axis" {
    const axis = Vec3f.init(.{ 0, 0, 1 });
    const angle: f32 = std.math.pi / 2.0;
    const q = Quatf.fromAxisAngle(axis, angle);

    const expected = Mat3f.init(.{
        .{ 0, -1, 0 },
        .{ 1, 0, 0 },
        .{ 0, 0, 1 },
    });
    const actual = q.toMat3();

    try expectMat3ApproxEq(expected, actual);
}

test "Quaternion.toMat3 should return identity matrix for identity quaternion" {
    const q = Quatf.initIdentity();

    const expected = Mat3f.initIdentity();
    const actual = q.toMat3();

    try expectMat3ApproxEq(expected, actual);
}

test "Quaternion.toMat4 should return rotation matrix around Y axis" {
    const axis = Vec3f.init(.{ 0, 1, 0 });
    const angle: f32 = std.math.pi / 2.0;
    const q = Quatf.fromAxisAngle(axis, angle);

    const expected = Mat4f.init(.{
        .{ 0, 0, 1, 0 },
        .{ 0, 1, 0, 0 },
        .{ -1, 0, 0, 0 },
        .{ 0, 0, 0, 1 },
    });
    const actual = q.toMat4();

    try expectMat4ApproxEq(expected, actual);
}

test "Quaternion.toMat4 should return identity matrix for identity quaternion" {
    const q = Quatf.initIdentity();

    const expected = Mat4f.initIdentity();
    const actual = q.toMat4();

    try expectMat4ApproxEq(expected, actual);
}
