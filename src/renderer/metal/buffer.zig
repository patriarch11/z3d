const z3d = @import("z3d");

const objc = z3d.platform.macos.objc;

pub const Buffer = struct {
    handle: objc.Id,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        objc.release(self.handle);
    }
};
