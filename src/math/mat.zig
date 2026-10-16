const Vec = @import("vec.zig").Vec;
const Vec3f = @import("vec.zig").Vec3f;
const Vec4f = @import("vec.zig").Vec4f;

pub const Mat2f = Mat(2, 2, f32);
pub const Mat3f = Mat(3, 3, f32);
pub const Mat4f = Mat(4, 4, f32);

pub fn Mat(comptime R: usize, comptime C: usize, comptime T: type) type {
    comptime {
        switch (@typeInfo(T)) {
            .float => {},
            else => @compileError("T must be a float"),
        }
    }

    return struct {
        const Self = @This();

        data: [R][C]T,

        pub fn init(data: [R][C]T) Self {
            return .{ .data = data };
        }

        pub fn initZero() Self {
            return .{ .data = @splat(@splat(0)) };
        }

        pub fn initIdentity() Self {
            comptime {
                if (R != C) {
                    @compileError("Identity matrix must be square");
                }
            }

            var res = initZero();

            for (0..R) |i| {
                res.data[i][i] = 1.0;
            }

            return res;
        }

        pub fn getRow(self: *const Self, row: usize) Vec(C, T) {
            return Vec(C, T).init(self.data[row]);
        }

        pub fn getCol(self: *const Self, col: usize) Vec(R, T) {
            var res: [R]T = @splat(0);

            for (0..R) |i| {
                res[i] = self.data[i][col];
            }

            return Vec(R, T).init(res);
        }

        pub fn add(a: Self, b: Self) Self {
            var res = initZero();

            for (0..R) |row| {
                for (0..C) |col| {
                    res.data[row][col] = a.data[row][col] + b.data[row][col];
                }
            }

            return res;
        }

        pub fn sub(a: Self, b: Self) Self {
            var res = initZero();

            for (0..R) |row| {
                for (0..C) |col| {
                    res.data[row][col] = a.data[row][col] - b.data[row][col];
                }
            }

            return res;
        }

        pub fn scale(a: Self, k: T) Self {
            var res = initZero();

            for (0..R) |row| {
                for (0..C) |col| {
                    res.data[row][col] = a.data[row][col] * k;
                }
            }

            return res;
        }

        pub fn mul(
            a: Self,
            comptime BCols: usize,
            b: Mat(C, BCols, T),
        ) Mat(R, BCols, T) {
            const VecT = Vec(C, T);
            var res = Mat(R, BCols, T).initZero();

            for (0..R) |row| {
                for (0..BCols) |col| {
                    const vec_a = a.getRow(row);
                    const vec_b = b.getCol(col);

                    res.data[row][col] = VecT.dot(vec_a, vec_b);
                }
            }

            return res;
        }

        pub fn mulVec(a: Self, vec: Vec(C, T)) Vec(R, T) {
            var res = Vec(R, T).initZero();

            for (0..R) |row| {
                const vec_a = a.getRow(row);
                res.data[row] = Vec(C, T).dot(vec_a, vec);
            }

            return res;
        }

        pub fn transpose(a: Self) Mat(C, R, T) {
            var res = Mat(C, R, T).initZero();

            for (0..C) |i| {
                res.data[i] = a.getCol(i).data;
            }

            return res;
        }
    };
}

pub fn translate(offset: Vec3f) Mat4f {
    var res = Mat4f.initIdentity();

    for (0..3) |i| {
        res.data[i][3] = offset.data[i];
    }

    return res;
}

pub fn scaling(s: Vec3f) Mat4f {
    var res = Mat4f.initIdentity();

    for (0..3) |i| {
        res.data[i][i] = s.data[i];
    }

    return res;
}

pub fn rotateX(angle: f32) Mat4f {
    var res = Mat4f.initIdentity();

    res.data[1][1] = @cos(angle);
    res.data[1][2] = -@sin(angle);
    res.data[2][1] = @sin(angle);
    res.data[2][2] = @cos(angle);

    return res;
}
pub fn rotateY(angle: f32) Mat4f {
    var res = Mat4f.initIdentity();

    res.data[0][0] = @cos(angle);
    res.data[0][2] = @sin(angle);
    res.data[2][0] = -@sin(angle);
    res.data[2][2] = @cos(angle);

    return res;
}
pub fn rotateZ(angle: f32) Mat4f {
    var res = Mat4f.initIdentity();

    res.data[0][0] = @cos(angle);
    res.data[0][1] = -@sin(angle);
    res.data[1][0] = @sin(angle);
    res.data[1][1] = @cos(angle);

    return res;
}
