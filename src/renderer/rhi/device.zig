const errors = @import("errors.zig");

pub fn Device(comptime Impl: type) type {
    return struct {
        impl: Impl,

        const Self = @This();

        pub fn init() errors.Error!Self {
            return .{
                .impl = try Impl.init(),
            };
        }

        pub fn deinit(self: *Self) void {
            self.impl.deinit();
        }
    };
}
