const std = @import("std");
const glfw = @import("zglfw");
const z3d = @import("z3d");

const objc = z3d.platform.macos.objc;
const cocoa = z3d.platform.macos.cocoa;
const metal = z3d.renderer.metal;
const mat = z3d.math.mat;

const Vertex = extern struct {
    position: [3]f32,
    color: [4]f32,
};

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

const windowWidth: c_int = 1280;
const windowHeight: c_int = 720;

const projection = mat.perspective(
    std.math.degreesToRadians(60.0),
    @as(f32, windowWidth) / @as(f32, windowHeight),
    0.1,
    100.0,
);
const view = mat.translation(.{ 0, 0, -3, 0 });

const mvp = mat.mulMat(view, projection);

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.client_api, .no_api);

    const window = try glfw.Window.create(
        windowWidth,
        windowHeight,
        "z3d - Cube",
        null,
        null,
    );
    defer window.destroy();

    const init_pool = objc.objc_autoreleasePoolPush();
    defer objc.objc_autoreleasePoolPop(init_pool);

    const cocoa_window = glfw.getCocoaWindow(window) orelse
        return error.CocoaWindowUnavailable;

    const ns_window = try cocoa.NsWindow.init(cocoa_window);
    const ns_view = try ns_window.contentView();
    const metal_layer = try metal.CAMetalLayer.init();

    const mtl_device = try metal.MTLDevice.init();
    defer mtl_device.deinit();

    const vertex_buffer = try mtl_device.newBuffer(
        std.mem.sliceAsBytes(vertices[0..]),
    );
    defer vertex_buffer.deinit();

    const index_buffer = try mtl_device.newBuffer(
        std.mem.sliceAsBytes(indices[0..]),
    );
    defer index_buffer.deinit();

    const mtl_library = try metal.MTLLibrary.init(
        mtl_device,
        "zig-out/shaders.metallib",
    );
    defer mtl_library.deinit();

    std.debug.print("MTLLibrary: {*}\n", .{mtl_library.library});

    const vertex_fn = try mtl_library.newFunctionWithName("vertex_main");
    defer vertex_fn.deinit();

    const fragment_fn = try mtl_library.newFunctionWithName("fragment_main");
    defer fragment_fn.deinit();

    const pipeline_desc = try metal.MTLRenderPipelineDescriptor.init();
    defer pipeline_desc.deinit();

    pipeline_desc.setVertexFunction(vertex_fn);
    pipeline_desc.setFragmentFunction(fragment_fn);

    const pipeline_attachments = try pipeline_desc.colorAttachments();
    const pipeline_attachment = try pipeline_attachments.sub(0);

    pipeline_attachment.setPixelFormat(.bgra8_unorm);

    const pipeline = try mtl_device.newRenderPipelineState(pipeline_desc);
    defer pipeline.deinit();

    std.debug.print("MTLRenderPipelineState: {*}\n", .{pipeline.pipeline});
    std.debug.print("Vertex function: {*}\n", .{vertex_fn.function});
    std.debug.print("Fragment function: {*}\n", .{fragment_fn.function});

    const mtl_cmd_q = try mtl_device.newCommandQueue();
    defer mtl_cmd_q.deinit();

    ns_view.setWantsLayer(true);
    ns_view.setLayer(metal_layer.metal_layer);
    metal_layer.setDevice(mtl_device);

    var r: f64 = 0.0;
    var g: f64 = 0.0;
    var b: f64 = 0.0;
    var a: f64 = 0.0;

    while (!window.shouldClose()) : ({
        r += 0.0035;
        g += 0.0015;
        b += 0.0025;
        a += 0.0005;
    }) {
        if (r >= 2) {
            r, g, b, a = .{ 0, 0, 0, 0 };
        }

        glfw.pollEvents();

        const pool = objc.objc_autoreleasePoolPush();
        defer objc.objc_autoreleasePoolPop(pool);

        const cmd_buffer = try mtl_cmd_q.commandBuffer();

        const framebuffer_size = window.getFramebufferSize();

        if (framebuffer_size[0] <= 0 or framebuffer_size[1] <= 0) {
            continue;
        }

        metal_layer.setDrawableSize(
            @floatFromInt(framebuffer_size[0]),
            @floatFromInt(framebuffer_size[1]),
        );

        const drawable = (try metal_layer.nextDrawable()) orelse
            return error.DrawableUnavailable;

        const texture = try drawable.texture();

        const mtl_render_pass_descriptor = try metal.MTLRenderPassDescriptor.init();
        const attachments_arr = try mtl_render_pass_descriptor.colorAttachments();
        const attachment = try attachments_arr.sub(0);

        attachment.setTexture(texture);
        attachment.setLoadAction(.clear);
        attachment.setStoreAction(.store);
        attachment.setClearColor(.{
            .red = r,
            .green = g,
            .blue = b,
            .alpha = a,
        });

        const encoder = try cmd_buffer.renderCommandEncoder(
            mtl_render_pass_descriptor,
        );

        encoder.setRenderPipelineState(pipeline);
        encoder.setVertexBuffer(vertex_buffer, 0, 0);
        encoder.setVertexBytes(std.mem.asBytes(&mvp), 1);

        encoder.drawIndexedPrimitives(
            .triangle,
            indices.len,
            .uint16,
            index_buffer,
            0,
        );
        encoder.endEncoding();
        cmd_buffer.presentDrawable(drawable);
        cmd_buffer.commit();
    }
}
