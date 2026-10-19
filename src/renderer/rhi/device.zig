const z3d = @import("z3d");
const errors = @import("errors.zig");
const buffer = @import("buffer.zig");

const objc = z3d.platform.macos.objc;

const Error = errors.Error;

pub fn Device(comptime Impl: type) type {
    return struct {
        impl: Impl.Device,

        const Self = @This();

        pub fn init() !Self {
            return .{
                .impl = try Impl.Device.init(),
            };
        }

        pub fn deinit(self: *Self) void {
            self.impl.deinit();
            self.* = undefined;
        }

        pub fn createBuffer(self: *const Self, desc: buffer.BufferDesc) !buffer.Buffer(Impl.Buffer) {
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

        pub fn writeBuffer(self: *const Self, buff: *const buffer.Buffer(Impl.Buffer), offset: usize, data: []const u8) !void {
            return try self.impl.writeBuffer(buff, offset, data);
        }
    };
}
