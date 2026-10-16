const std = @import("std");
const MathErrors = @import("errors.zig").MathErrors;

pub const Vec2f = Vec(2, f32);
pub const Vec3f = Vec(3, f32);
pub const Vec4f = Vec(4, f32);

pub fn Vec(comptime D: usize, comptime T: type) type {
    comptime {
        switch (@typeInfo(T)) {
            .float => {},
            else => @compileError("T must be a float"),
        }
    }

    return struct {
        const Self = @This();
        data: [D]T,

        pub fn init(data: [D]T) Self {
            return .{ .data = data };
        }

        pub fn initZero() Self {
            return .{ .data = @splat(0) };
        }

        pub fn add(a: Self, b: Self) Self {
            var res = initZero();

            for (0..D) |i| {
                res.data[i] = a.data[i] + b.data[i];
            }

            return res;
        }

        pub fn sub(a: Self, b: Self) Self {
            var res = initZero();

            for (0..D) |i| {
                res.data[i] = a.data[i] - b.data[i];
            }

            return res;
        }

        pub fn dot(a: Self, b: Self) T {
            var res: T = 0;

            for (0..D) |i| {
                res += a.data[i] * b.data[i];
            }

            return res;
        }

        pub fn scale(a: Self, k: T) Self {
            var res = initZero();

            for (0..D) |i| {
                res.data[i] = a.data[i] * k;
            }

            return res;
        }

        pub fn lengthSquared(self: *const Self) T {
            return self.dot(self.*);
        }

        pub fn length(self: *const Self) T {
            return @sqrt(self.lengthSquared());
        }

        pub fn normalize(self: *const Self) !Self {
            const len = self.length();

            if (len == 0) {
                return MathErrors.ZeroLengthVector;
            }

            var res = initZero();

            for (0..D) |i| {
                res.data[i] = self.data[i] / len;
            }

            return res;
        }

        pub fn normalizeOrZero(self: *const Self) Self {
            const v = self.normalize() catch |err| switch (err) {
                MathErrors.ZeroLengthVector => initZero(),
                MathErrors.DivisionByZero => {
                    std.debug.print("Normalize failed, returning zero vec3: {}\nre", .{err});
                    return initZero();
                },
            };

            return v;
        }

        /// N×N determinant (Laplace expansion along the first row, O(N!), fine for small D)
        fn det(comptime N: usize, m: [N][N]T) T {
            if (N == 0) {
                return 1;
            } else if (N == 1) {
                return m[0][0];
            } else {
                var s: T = 0;
                inline for (0..N) |c| {
                    var minor: [N - 1][N - 1]T = undefined;
                    for (1..N) |r| {
                        var cc: usize = 0;
                        for (0..N) |k| {
                            if (k == c) continue;
                            minor[r - 1][cc] = m[r][k];
                            cc += 1;
                        }
                    }
                    const sign: T = if (c % 2 == 0) 1 else -1;
                    s += sign * m[0][c] * det(N - 1, minor);
                }
                return s;
            }
        }

        /// Generalized cross product: D-1 vectors -> a vector perpendicular to all of them
        pub fn cross(vs: [D - 1]Self) Self {
            comptime if (D < 2) @compileError("cross requires D >= 2");

            var out: Self = undefined;
            inline for (0..D) |i| {
                var m: [D - 1][D - 1]T = undefined;
                for (0..D - 1) |r| {
                    var c: usize = 0;
                    for (0..D) |k| {
                        if (k == i) continue;
                        m[r][c] = vs[r].data[k];
                        c += 1;
                    }
                }
                const sign: T = if (i % 2 == 0) 1 else -1;
                out.data[i] = sign * det(D - 1, m);
            }
            return out;
        }

        pub fn isEq(self: *const Self, vec: Self) bool {
            for (0..D) |i| {
                if (self.data[i] != vec.data[i]) {
                    return false;
                }
            }

            return true;
        }
    };
}
