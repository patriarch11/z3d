const z3d = @import("z3d");
const std = @import("std");

const rhi = z3d.renderer.rhi;

const Vertex = z3d.geometry.vertex.PositionColor;
const Window = z3d.platform.window.Window;

const vertices = [_]Vertex{
    // Front
    .{ .position = .{ -0.5, -0.5, 0.5 }, .color = .{ 1, 0, 0, 1 } }, // 0
    .{ .position = .{ 0.5, -0.5, 0.5 }, .color = .{ 0, 1, 0, 1 } }, // 1
    .{ .position = .{ 0.5, 0.5, 0.5 }, .color = .{ 0, 0, 1, 1 } }, // 2
    .{ .position = .{ -0.5, 0.5, 0.5 }, .color = .{ 1, 1, 0, 1 } }, // 3

    // Back
    .{ .position = .{ -0.5, -0.5, -0.5 }, .color = .{ 1, 0, 1, 1 } }, // 4
    .{ .position = .{ 0.5, -0.5, -0.5 }, .color = .{ 0, 1, 1, 1 } }, // 5
    .{ .position = .{ 0.5, 0.5, -0.5 }, .color = .{ 1, 1, 1, 1 } }, // 6
    .{ .position = .{ -0.5, 0.5, -0.5 }, .color = .{ 0.3, 0.3, 0.3, 1 } }, // 7
};

const indices = [_]u16{
    // Front (+Z)
    0, 1, 2,
    0, 2, 3,

    // Back (-Z)
    5, 4, 7,
    5, 7, 6,

    // Left (-X)
    4, 0, 3,
    4, 3, 7,

    // Right (+X)
    1, 5, 6,
    1, 6, 2,

    // Top (+Y)
    3, 2, 6,
    3, 6, 7,

    // Bottom (-Y)
    4, 5, 1,
    4, 1, 0,
};

pub fn main() !void {
    const gfx = rhi.API(.metal);

    var device = try gfx.Device.init();
    defer device.deinit();

    var window = try Window.init(.{
        .width = 1280,
        .height = 720,
        .title = "z3d",
    });
    defer window.deinit();

    const native_window = try window.nativeHandle();

    var surface = try gfx.Surface.init(&device, native_window);
    defer surface.deinit();

    var vertex_buffer = try device.createBuffer(.{
        .size = @sizeOf(Vertex) * vertices.len,
        .usage = .{
            .vertex = true,
            .copy_dst = true,
        },
    });
    defer vertex_buffer.deinit();

    var index_buffer = try device.createBuffer(.{
        .size = @sizeOf(u16) * indices.len,
        .usage = .{
            .index = true,
            .copy_dst = true,
        },
    });
    defer index_buffer.deinit();

    try device.writeBuffer(&vertex_buffer, 0, std.mem.sliceAsBytes(vertices[0..]));
    try device.writeBuffer(&index_buffer, 0, std.mem.sliceAsBytes(indices[0..]));
}
