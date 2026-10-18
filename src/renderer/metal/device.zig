const z3d = @import("z3d");
const rhi_errors = @import("../rhi/errors.zig"); // TODO: use absolute import path

const objc = z3d.platform.macos.objc;

extern "Metal" fn MTLCreateSystemDefaultDevice() ?objc.Id;

pub const Device = struct {
    handle: objc.Id,

    const Self = @This();

    pub fn init() rhi_errors.Error!Self {
        const handle = MTLCreateSystemDefaultDevice() orelse
            return rhi_errors.Error.DeviceUnavailable;

        return .{ .handle = handle };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.handle);
    }
};
