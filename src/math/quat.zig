const Vec = @import("vec.zig").Vec;
const Mat = @import("mat.zig").Mat;

pub const Quatf = Quaternion(f32);

pub fn Quaternion(comptime T: type) type {
    comptime {
        switch (@typeInfo(T)) {
            .float => {},
            else => @compileError("T must be a floating-point type"),
        }
    }

    return struct {
        const Self = @This();
        const Vec3 = Vec(3, T);
        const Mat3 = Mat(3, 3, T);
        const Mat4 = Mat(4, 4, T);

        pub const Error = error{ZeroLengthQuaternion};

        x: T,
        y: T,
        z: T,
        w: T,

        pub fn init(x: T, y: T, z: T, w: T) Self {
            return .{ .x = x, .y = y, .z = z, .w = w };
        }

        pub fn initIdentity() Self {
            return init(0, 0, 0, 1);
        }

        pub fn lengthSquared(self: *const Self) T {
            return self.x * self.x + self.y * self.y +
                self.z * self.z + self.w * self.w;
        }

        pub fn length(self: *const Self) T {
            return @sqrt(self.lengthSquared());
        }

        pub fn normalize(self: *const Self) Error!Self {
            const len = self.length();
            if (len == 0) return error.ZeroLengthQuaternion;

            return init(
                self.x / len,
                self.y / len,
                self.z / len,
                self.w / len,
            );
        }

        pub fn conjugate(self: *const Self) Self {
            return init(-self.x, -self.y, -self.z, self.w);
        }

        pub fn invert(self: *const Self) Error!Self {
            const len_sq = self.lengthSquared();
            if (len_sq == 0) return error.ZeroLengthQuaternion;

            return init(
                -self.x / len_sq,
                -self.y / len_sq,
                -self.z / len_sq,
                self.w / len_sq,
            );
        }

        pub fn mul(a: Self, b: Self) Self {
            return init(
                a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
                a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
                a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
                a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
            );
        }

        /// `angle` is in radians; `axis` must be a unit vector.
        pub fn fromAxisAngle(axis: Vec3, angle: T) Self {
            const half = angle / 2;
            const s = @sin(half);

            return init(
                axis.data[0] * s,
                axis.data[1] * s,
                axis.data[2] * s,
                @cos(half),
            );
        }

        /// Rotates a vector by a unit quaternion.
        pub fn rotateVec3(q: Self, v: Vec3) Vec3 {
            const u = Vec3.init(.{ q.x, q.y, q.z });
            const cross_uv = Vec3.cross(u, v);
            const term1 = Vec3.scale(cross_uv, 2 * q.w);
            const term2 = Vec3.scale(Vec3.cross(u, cross_uv), 2);
            return Vec3.add(v, Vec3.add(term1, term2));
        }

        /// Converts a unit quaternion to a 3x3 rotation matrix.
        pub fn toMat3(self: *const Self) Mat3 {
            const x = self.x;
            const y = self.y;
            const z = self.z;
            const w = self.w;

            return Mat3.init(.{
                .{ 1 - 2 * (y * y + z * z), 2 * (x * y - w * z), 2 * (x * z + w * y) },
                .{ 2 * (x * y + w * z), 1 - 2 * (x * x + z * z), 2 * (y * z - w * x) },
                .{ 2 * (x * z - w * y), 2 * (y * z + w * x), 1 - 2 * (x * x + y * y) },
            });
        }

        /// Converts a unit quaternion to a 4x4 rotation matrix.
        pub fn toMat4(self: *const Self) Mat4 {
            const mat3 = self.toMat3();
            var result = Mat4.initIdentity();

            for (0..3) |row| {
                for (0..3) |col| {
                    result.data[row][col] = mat3.data[row][col];
                }
            }

            return result;
        }
    };
}
