const z3d = @import("z3d");

const rhi = z3d.renderer.rhi;
const gfx = rhi.API(.metal);

pub fn main() !void {
    var device = try gfx.Device.init();
    defer device.deinit();
}
