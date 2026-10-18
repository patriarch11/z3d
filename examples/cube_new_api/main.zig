const z3d = @import("z3d");

const rhi = z3d.renderer.rhi;
const gfx = rhi.API(.metal);

pub fn main() !void {
    var device = try gfx.Device.init();
    defer device.deinit();

    var vertex_buffer = try device.createBuffer(.{
        .size = 10,
        .usage = .{
            .vertex = true,
            .copy_dst = true,
        },
    });
    defer vertex_buffer.deinit();
}
