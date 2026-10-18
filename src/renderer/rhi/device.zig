const z3d = @import("z3d");
const errors = @import("errors.zig");
const buffer = @import("buffer.zig");

const objc = z3d.platform.macos.objc;

const Error = errors.Error;

pub const InitError = objc.Error || Error;

pub fn Device(comptime Impl: type) type {
    return struct {
        impl: Impl.Device,

        const Self = @This();

        pub fn init() InitError!Self {
            return .{
                .impl = try Impl.Device.init(),
            };
        }

        pub fn deinit(self: *Self) void {
            self.impl.deinit();
        }

        pub fn createBuffer(
            self: *const Self,
            desc: buffer.BufferDesc,
        ) Error!buffer.Buffer(Impl.Buffer) {
            if (desc.size == 0) {
                return Error.InvalidBufferUsage;
            }

            if (@as(u32, @bitCast(desc.usage)) == 0) {
                return error.InvalidBufferUsage;
            }

            return .{
                .impl = try self.impl.createBuffer(desc),
            };
        }
    };
}
