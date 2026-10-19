const z3d = @import("z3d");
const device = @import("device.zig");

const NativeWindowHandle = z3d.platform.window.NativeWindowHandle;

pub const SurfaceDesc = struct {
    window: NativeWindowHandle,
};

pub fn Surface(comptime Impl: type) type {
    return struct {
        impl: Impl.Surface,

        const Self = @This();

        pub fn init(
            d: *device.Device(Impl),
            window: NativeWindowHandle,
        ) !Self {
            return .{
                .impl = try Impl.Surface.init(&d.impl, window),
            };
        }

        pub fn deinit(self: *Self) void {
            self.impl.deinit();
            self.* = undefined;
        }
    };
}
