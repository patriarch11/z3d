const z3d = @import("z3d");

const objc = z3d.platform.macos.objc;

extern "Metal" fn MTLCreateSystemDefaultDevice() ?objc.Id;

pub const Error = error{
    MTLDeviceUnavailable,
};

pub const Device = struct {
    handle: objc.Id,

    const Self = @This();

    pub fn init() !Self {
        const handle = MTLCreateSystemDefaultDevice() orelse
            return Error.MTLDeviceUnavailable;

        return .{ .handle = handle };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.handle);
    }
};
