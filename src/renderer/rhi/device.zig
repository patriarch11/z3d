pub fn Device(comptime Impl: type) type {
    return struct {
        impl: Impl,

        const Self = @This();

        pub fn init() !Self {
            return .{
                .impl = try Impl.init(),
            };
        }

        pub fn deinit(self: *Self) void {
            self.impl.deinit();
        }
    };
}
