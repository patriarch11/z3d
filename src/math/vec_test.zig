const std = @import("std");
const Vec3f = @import("vec.zig").Vec3f;

test "Vec3f.add should sum two vectors" {
    const a = Vec3f.init([3]f32{ 1, 3, 5 });
    const b = Vec3f.init([3]f32{ 2, 4, 6 });

    const expected = Vec3f.init([3]f32{ 3, 7, 11 });
    const actual = Vec3f.add(a, b);

    try std.testing.expect(actual.isEq(expected));
}

test "Vec3f.sub should substract two vectors" {
    const a = Vec3f.init([3]f32{ 1, 3, 5 });
    const b = Vec3f.init([3]f32{ 2, 4, 6 });

    const expected = Vec3f.init([3]f32{ -1, -1, -1 });
    const actual = Vec3f.sub(a, b);

    try std.testing.expect(actual.isEq(expected));
}

test "Vec3f.dot should calculate the dot product of two vectors" {
    const a = Vec3f.init([3]f32{ 1, 3, 5 });
    const b = Vec3f.init([3]f32{ 2, 4, 6 });

    const expected = 44.0;
    const actual = Vec3f.dot(a, b);

    try std.testing.expectEqual(expected, actual);
}

test "Vec3f.scale should scale vector" {
    const a = Vec3f.init([3]f32{ 1, 3, 5 });
    const k = 3.0;

    const expected = Vec3f.init([3]f32{ 3, 9, 15 });
    const actual = Vec3f.scale(a, k);

    try std.testing.expectEqual(expected, actual);
}

test "Vec3f.lengthSquared should return squared vector length" {
    const a = Vec3f.init([3]f32{ 1, 3, 5 });

    const expected = 35.0;
    const actual = a.lengthSquared();

    try std.testing.expectEqual(expected, actual);
}

test "Vec3f.length should return vector length" {
    const a = Vec3f.init([3]f32{ 1, 3, 5 });

    const expected = @sqrt(35.0);
    const actual = a.length();

    try std.testing.expectEqual(expected, actual);
}

test "Vec3f.normalize should return normalized vector" {
    const a = Vec3f.init([3]f32{ 3, 4, 0 });

    const expected = Vec3f.init([3]f32{ 0.6, 0.8, 0 });
    const actual = try a.normalize();

    try std.testing.expectApproxEqAbs(expected.data[0], actual.data[0], 0.00001);
    try std.testing.expectApproxEqAbs(expected.data[1], actual.data[1], 0.00001);
    try std.testing.expectApproxEqAbs(expected.data[2], actual.data[2], 0.00001);
}

test "Vec3f.normalize should return error for zero length vector" {
    const a = Vec3f.init([3]f32{ 0, 0, 0 });

    try std.testing.expectError(
        error.ZeroLengthVector,
        a.normalize(),
    );
}

test "Vec3f.normalizeOrZero should return normalized vector" {
    const a = Vec3f.init([3]f32{ 3, 4, 0 });

    const expected = Vec3f.init([3]f32{ 0.6, 0.8, 0 });
    const actual = a.normalizeOrZero();

    try std.testing.expectApproxEqAbs(expected.data[0], actual.data[0], 0.00001);
    try std.testing.expectApproxEqAbs(expected.data[1], actual.data[1], 0.00001);
    try std.testing.expectApproxEqAbs(expected.data[2], actual.data[2], 0.00001);
}

test "Vec3f.normalizeOrZero should return zero vector for zero length vector" {
    const a = Vec3f.init([3]f32{ 0, 0, 0 });

    const expected = Vec3f.init([3]f32{ 0, 0, 0 });
    const actual = a.normalizeOrZero();

    try std.testing.expect(actual.isEq(expected));
}

test "Vec3f.cross should return a vector perpendicular to both input vectors" {
    const a = Vec3f.init([3]f32{ 1, 3, 5 });
    const b = Vec3f.init([3]f32{ 2, 4, 6 });

    const c = Vec3f.cross(.{ a, b });

    try std.testing.expect(c.isEq(Vec3f.init(.{ -2, 4, -2 })));
    try std.testing.expectApproxEqAbs(0, Vec3f.dot(a, c), 1e-5);
    try std.testing.expectApproxEqAbs(0, Vec3f.dot(b, c), 1e-5);
}
