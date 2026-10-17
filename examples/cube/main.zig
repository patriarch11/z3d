const std = @import("std");
const glfw = @import("zglfw");

const ObjcId = *anyopaque;
const ObjcSel = *anyopaque;

extern "objc" fn sel_registerName(
    name: [*:0]const u8,
) ?ObjcSel;

extern "objc" fn objc_getClass(
    name: [*:0]const u8,
) ?ObjcId;

extern "objc" fn objc_autoreleasePoolPush() *anyopaque;
extern "objc" fn objc_autoreleasePoolPop(pool: *anyopaque) void;

extern "objc" fn objc_msgSend() callconv(.c) void;

extern "Metal" fn MTLCreateSystemDefaultDevice() ?ObjcId;

const SendFn = *const fn (
    ObjcId,
    ObjcSel,
) callconv(.c) ?ObjcId;

const SendBoolFn = *const fn (
    ObjcId,
    ObjcSel,
    bool,
) callconv(.c) void;

const SendObjectFn = *const fn (
    ObjcId,
    ObjcSel,
    ObjcId,
) callconv(.c) void;

const SendVoidFn = *const fn (
    ObjcId,
    ObjcSel,
) callconv(.c) void;

const SendIndexFn = *const fn (
    ObjcId,
    ObjcSel,
    usize,
) callconv(.c) ?ObjcId;

const SendUsizeFn = *const fn (
    ObjcId,
    ObjcSel,
    usize,
) callconv(.c) void;

const SendClearColorFn = *const fn (
    ObjcId,
    ObjcSel,
    MTLClearColor,
) callconv(.c) void;

const SendObjectReturnFn = *const fn (
    ObjcId,
    ObjcSel,
    ObjcId,
) callconv(.c) ?ObjcId;

const SendSizeFn = *const fn (
    ObjcId,
    ObjcSel,
    CGSize,
) callconv(.c) void;

const SendCStringFn = *const fn (
    ObjcId,
    ObjcSel,
    [*:0]const u8,
) callconv(.c) ?ObjcId;

const SendObjectErrorFn = *const fn (
    ObjcId,
    ObjcSel,
    ObjcId,
    ?*?ObjcId,
) callconv(.c) ?ObjcId;

const send: SendFn = @ptrCast(&objc_msgSend);
const send_bool: SendBoolFn = @ptrCast(&objc_msgSend);
const send_object: SendObjectFn = @ptrCast(&objc_msgSend);
const send_void: SendVoidFn = @ptrCast(&objc_msgSend);
const send_index: SendIndexFn = @ptrCast(&objc_msgSend);
const send_usize: SendUsizeFn = @ptrCast(&objc_msgSend);
const send_clear_color: SendClearColorFn = @ptrCast(&objc_msgSend);
const send_object_return: SendObjectReturnFn = @ptrCast(&objc_msgSend);
const send_size: SendSizeFn = @ptrCast(&objc_msgSend);
const send_cstring: SendCStringFn = @ptrCast(&objc_msgSend);
const send_object_error: SendObjectErrorFn = @ptrCast(&objc_msgSend);

const ObjcErr = error{
    CocoaWindowUnavailable,
    ContentViewSelectorUnavailable,
    ContentViewUnavailable,
    CAMetalLayerClassUnavailable,
    CAMetalLayerSelectorUnavailable,
    CAMetalLayerCreationFailed,
    WantsLayerSelectorUnavailable,
    SetLayerSelectorUnavailable,
    MTLDeviceUnavailable,
    CommandQueueSelectorUnavailable,
    CommandQueueCreationFailed,
    SetDeviceSelectorUnavailable,
    NextDrawableSelectorUnavailable,
    TextureSelectorUnavailable,
    TextureUnavailable,
    DrawableUnavailable,
    RenderPassClassUnavailable,
    RenderPassSelectorUnavailable,
    RenderPassCreationFailed,
    ColorAttachmentsSelectorUnavailable,
    ColorAttachmentsUnavailable,
    AttachmentIndexSelectorUnavailable,
    ColorAttachmentUnavailable,
    SetTextureSelectorUnavailable,
    SetLoadActionSelectorUnavailable,
    SetStoreActionSelectorUnavailable,
    SetClearColorSelectorUnavailable,
    CommandBufferCreationFailed,
    CommandBufferSelectorUnavailable,
    RenderEncoderSelectorUnavailable,
    RenderEncoderCreationFailed,
    EndEncodingSelectorUnavailable,
    PresentDrawableSelectorUnavailable,
    CommitSelectorUnavailable,
    SetDrawableSizeSelectorUnavailable,
    NSStringSelectorUnavailable,
    NSStringCreationFailed,
    NewLibrarySelectorUnavailable,
    LibraryCreationFailed,
    NSStringClassUnavailable,
    NewFunctionSelectorUnavailable,
};

pub const MTLLoadAction = enum(usize) {
    dont_care = 0,
    load = 1,
    clear = 2,
};

pub const MTLStoreAction = enum(usize) {
    dont_care = 0,
    store = 1,
};

pub const MTLClearColor = extern struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

pub const CGSize = extern struct {
    width: f64,
    height: f64,
};

fn release(object: ObjcId) void {
    const selector = sel_registerName("release") orelse unreachable;
    send_void(object, selector);
}

fn nsString(value: [*:0]const u8) !ObjcId {
    const cls = objc_getClass("NSString") orelse
        return ObjcErr.NSStringClassUnavailable;

    const selector = sel_registerName("stringWithUTF8String:") orelse
        return ObjcErr.NSStringSelectorUnavailable;

    return send_cstring(cls, selector, value) orelse
        ObjcErr.NSStringCreationFailed;
}

pub const NsWindow = struct {
    ns_window: ObjcId,
    content_view_sel: ObjcSel,

    const Self = @This();

    pub fn init(window: *glfw.Window) !Self {
        const ns_window = glfw.getCocoaWindow(window) orelse
            return ObjcErr.CocoaWindowUnavailable;

        const content_view_sel = sel_registerName("contentView") orelse
            return ObjcErr.ContentViewSelectorUnavailable;

        return .{
            .ns_window = ns_window,
            .content_view_sel = content_view_sel,
        };
    }

    pub fn contentView(self: *const Self) !NsView {
        const objc_ns_view = send(self.ns_window, self.content_view_sel) orelse
            return ObjcErr.ContentViewUnavailable;

        return NsView.init(objc_ns_view);
    }
};

pub const NsView = struct {
    ns_view: ObjcId,
    set_wants_layer_sel: ObjcSel,
    set_layer_sel: ObjcSel,

    const Self = @This();

    pub fn init(ns_view: ObjcId) !Self {
        const set_wants_layer_sel = sel_registerName("setWantsLayer:") orelse
            return ObjcErr.WantsLayerSelectorUnavailable;

        const set_layer_sel = sel_registerName("setLayer:") orelse
            return ObjcErr.SetLayerSelectorUnavailable;

        return .{
            .ns_view = ns_view,
            .set_wants_layer_sel = set_wants_layer_sel,
            .set_layer_sel = set_layer_sel,
        };
    }

    pub fn setWantsLayer(self: *const Self, wants: bool) void {
        send_bool(self.ns_view, self.set_wants_layer_sel, wants);
    }

    pub fn setLayer(self: *const Self, layer: CAMetalLayer) void {
        send_object(self.ns_view, self.set_layer_sel, layer.metal_layer);
    }
};

pub const CAMetalLayer = struct {
    metal_layer: ObjcId,
    set_device_sel: ObjcSel,
    next_drawable_sel: ObjcSel,
    set_drawable_size_sel: ObjcSel,

    const Self = @This();

    pub fn init() !Self {
        const metal_layer_class = objc_getClass("CAMetalLayer") orelse
            return ObjcErr.CAMetalLayerClassUnavailable;

        const layer_sel = sel_registerName("layer") orelse
            return ObjcErr.CAMetalLayerSelectorUnavailable;
        const metal_layer = send(metal_layer_class, layer_sel) orelse
            return ObjcErr.CAMetalLayerCreationFailed;

        const set_device_sel = sel_registerName("setDevice:") orelse
            return ObjcErr.SetDeviceSelectorUnavailable;
        const next_drawable_sel = sel_registerName("nextDrawable") orelse
            return ObjcErr.NextDrawableSelectorUnavailable;
        const set_drawable_size_sel = sel_registerName("nextDrawable") orelse
            return ObjcErr.SetDrawableSizeSelectorUnavailable;

        return .{
            .metal_layer = metal_layer,
            .set_device_sel = set_device_sel,
            .next_drawable_sel = next_drawable_sel,
            .set_drawable_size_sel = set_drawable_size_sel,
        };
    }

    pub fn setDevice(self: *const Self, device: MTLDevice) void {
        send_object(self.metal_layer, self.set_device_sel, device.device);
    }

    pub fn nextDrawable(self: *const Self) !?CAMetalDrawable {
        const drawable = send(
            self.metal_layer,
            self.next_drawable_sel,
        ) orelse return null;

        return try CAMetalDrawable.init(drawable);
    }

    pub fn setDrawableSize(
        self: *const Self,
        width: f64,
        height: f64,
    ) void {
        send_size(self.metal_layer, self.set_drawable_size_sel, .{
            .width = width,
            .height = height,
        });
    }
};

pub const CAMetalDrawable = struct {
    drawable: ObjcId,
    texture_sel: ObjcSel,

    const Self = @This();

    pub fn init(drawable: ObjcId) !Self {
        const texture_sel = sel_registerName("texture") orelse
            return ObjcErr.TextureSelectorUnavailable;

        return .{ .drawable = drawable, .texture_sel = texture_sel };
    }

    pub fn texture(self: *const Self) !MTLTexture {
        const t = send(self.drawable, self.texture_sel) orelse
            return ObjcErr.TextureUnavailable;

        return MTLTexture.init(t);
    }
};

pub const MTLDevice = struct {
    device: ObjcId,
    new_queue_sel: ObjcSel,

    const Self = @This();

    pub fn init() !Self {
        const device = MTLCreateSystemDefaultDevice() orelse
            return ObjcErr.MTLDeviceUnavailable;

        const new_queue_sel = sel_registerName("newCommandQueue") orelse
            return ObjcErr.CommandQueueSelectorUnavailable;

        return .{ .device = device, .new_queue_sel = new_queue_sel };
    }

    pub fn deinit(self: *const Self) void {
        release(self.device);
    }

    pub fn newCommandQueue(self: *const Self) !MTLCommandQueue {
        const command_queue = send(self.device, self.new_queue_sel) orelse
            return ObjcErr.CommandQueueCreationFailed;

        return try MTLCommandQueue.init(command_queue);
    }
};

pub const MTLCommandQueue = struct {
    command_queue: ObjcId,
    cmd_buffer_sel: ObjcSel,

    const Self = @This();

    pub fn init(command_queue: ObjcId) !Self {
        const cmd_buffer_sel = sel_registerName("commandBuffer") orelse
            return ObjcErr.CommandBufferSelectorUnavailable;

        return .{
            .command_queue = command_queue,
            .cmd_buffer_sel = cmd_buffer_sel,
        };
    }

    pub fn deinit(self: *const Self) void {
        release(self.command_queue);
    }

    pub fn commandBuffer(self: *const Self) !MTLCommandBuffer {
        const buffer = send(self.command_queue, self.cmd_buffer_sel) orelse
            return ObjcErr.CommandBufferCreationFailed;

        return try MTLCommandBuffer.init(buffer);
    }
};

pub const MTLCommandBuffer = struct {
    buffer: ObjcId,
    render_cmd_encoder_with_desc_sel: ObjcSel,
    present_drawable_sel: ObjcSel,
    commit_sel: ObjcSel,

    const Self = @This();

    pub fn init(buffer: ObjcId) !Self {
        const render_cmd_encoder_with_desc_sel = sel_registerName(
            "renderCommandEncoderWithDescriptor:",
        ) orelse return ObjcErr.RenderEncoderSelectorUnavailable;

        const present_drawable_sel = sel_registerName("presentDrawable:") orelse
            return ObjcErr.PresentDrawableSelectorUnavailable;

        const commit_sel = sel_registerName("commit") orelse
            return ObjcErr.CommitSelectorUnavailable;

        return .{
            .buffer = buffer,
            .render_cmd_encoder_with_desc_sel = render_cmd_encoder_with_desc_sel,
            .present_drawable_sel = present_drawable_sel,
            .commit_sel = commit_sel,
        };
    }

    pub fn renderCommandEncoder(
        self: *const Self,
        descriptor: MTLRenderPassDescriptor,
    ) !MTLRenderCommandEncoder {
        const encoder = send_object_return(
            self.buffer,
            self.render_cmd_encoder_with_desc_sel,
            descriptor.descriptor,
        ) orelse return ObjcErr.RenderEncoderCreationFailed;

        return try MTLRenderCommandEncoder.init(encoder);
    }

    pub fn presentDrawable(
        self: *const Self,
        drawable: CAMetalDrawable,
    ) void {
        send_object(self.buffer, self.present_drawable_sel, drawable.drawable);
    }

    pub fn commit(self: *const Self) void {
        send_void(self.buffer, self.commit_sel);
    }
};

pub const MTLRenderCommandEncoder = struct {
    encoder: ObjcId,
    end_edncoding_sel: ObjcSel,

    const Self = @This();

    pub fn init(encoder: ObjcId) !Self {
        const end_edncoding_sel = sel_registerName("endEncoding") orelse
            return ObjcErr.EndEncodingSelectorUnavailable;

        return .{
            .encoder = encoder,
            .end_edncoding_sel = end_edncoding_sel,
        };
    }

    pub fn endEncoding(self: *const Self) void {
        send_void(self.encoder, self.end_edncoding_sel);
    }
};

pub const MTLTexture = struct {
    texture: ObjcId,

    const Self = @This();

    pub fn init(texture: ObjcId) Self {
        return .{ .texture = texture };
    }
};

pub const MTLRenderPassDescriptor = struct {
    descriptor: ObjcId,
    color_attachments_sel: ObjcSel,

    const Self = @This();

    pub fn init() !Self {
        const render_pass_class = objc_getClass("MTLRenderPassDescriptor") orelse
            return ObjcErr.RenderPassClassUnavailable;

        const descriptor_sel = sel_registerName("renderPassDescriptor") orelse
            return ObjcErr.RenderPassSelectorUnavailable;

        const descriptor = send(render_pass_class, descriptor_sel) orelse
            return ObjcErr.RenderPassCreationFailed;

        const color_attachements_sel = sel_registerName("colorAttachments") orelse
            return ObjcErr.ColorAttachmentsSelectorUnavailable;

        return .{
            .descriptor = descriptor,
            .color_attachments_sel = color_attachements_sel,
        };
    }

    pub fn colorAttachments(self: *const Self) !MTLRenderPassColorAttachmentDescriptorArray {
        const attachments = send(self.descriptor, self.color_attachments_sel) orelse
            return ObjcErr.ColorAttachmentsUnavailable;

        return MTLRenderPassColorAttachmentDescriptorArray.init(attachments);
    }
};

pub const MTLRenderPassColorAttachmentDescriptorArray = struct {
    attachments: ObjcId,
    index_sel: ObjcSel,

    const Self = @This();

    pub fn init(attachments: ObjcId) !Self {
        const index_sel = sel_registerName("objectAtIndexedSubscript:") orelse
            return ObjcErr.AttachmentIndexSelectorUnavailable;
        return .{
            .attachments = attachments,
            .index_sel = index_sel,
        };
    }

    pub fn sub(self: *const Self, idx: usize) !MTLRenderPassColorAttachmentDescriptor {
        const attachment = send_index(
            self.attachments,
            self.index_sel,
            idx,
        ) orelse return ObjcErr.ColorAttachmentUnavailable;

        return try MTLRenderPassColorAttachmentDescriptor.init(attachment);
    }
};

pub const MTLRenderPassColorAttachmentDescriptor = struct {
    attachment: ObjcId,
    set_texture_sel: ObjcSel,
    set_load_action_sel: ObjcSel,
    set_store_action_sel: ObjcSel,
    set_clear_color_sel: ObjcSel,

    const Self = @This();

    pub fn init(attachment: ObjcId) !Self {
        const set_texture_sel = sel_registerName("setTexture:") orelse
            return ObjcErr.SetTextureSelectorUnavailable;

        const set_load_action_sel = sel_registerName("setLoadAction:") orelse
            return ObjcErr.SetLoadActionSelectorUnavailable;

        const set_store_action_sel = sel_registerName("setStoreAction:") orelse
            return ObjcErr.SetStoreActionSelectorUnavailable;

        const set_clear_color_sel = sel_registerName("setClearColor:") orelse
            return ObjcErr.SetClearColorSelectorUnavailable;

        return .{
            .attachment = attachment,
            .set_texture_sel = set_texture_sel,
            .set_load_action_sel = set_load_action_sel,
            .set_store_action_sel = set_store_action_sel,
            .set_clear_color_sel = set_clear_color_sel,
        };
    }

    pub fn setTexture(self: *const Self, texture: MTLTexture) void {
        send_object(self.attachment, self.set_texture_sel, texture.texture);
    }

    pub fn setLoadAction(self: *const Self, action: MTLLoadAction) void {
        send_usize(self.attachment, self.set_load_action_sel, @backingInt(action));
    }

    pub fn setStoreAction(self: *const Self, action: MTLStoreAction) void {
        send_usize(self.attachment, self.set_store_action_sel, @backingInt(action));
    }

    pub fn setClearColor(self: *const Self, color: MTLClearColor) void {
        send_clear_color(
            self.attachment,
            self.set_clear_color_sel,
            color,
        );
    }
};

pub const MTLLibrary = struct {
    library: ObjcId,
    new_function_with_name_sel: ObjcSel,

    const Self = @This();

    pub fn init(
        device: MTLDevice,
        path: [*:0]const u8,
    ) !Self {
        const selector = sel_registerName("newLibraryWithFile:error:") orelse
            return ObjcErr.NewLibrarySelectorUnavailable;

        const ns_path = try nsString(path);

        var ns_error: ?ObjcId = null;

        const library = send_object_error(
            device.device,
            selector,
            ns_path,
            &ns_error,
        ) orelse return ObjcErr.LibraryCreationFailed;

        const new_function_with_name_sel = sel_registerName("newFunctionWithName:") orelse
            return ObjcErr.NewFunctionSelectorUnavailable;

        return .{
            .library = library,
            .new_function_with_name_sel = new_function_with_name_sel,
        };
    }

    pub fn deinit(self: *const Self) void {
        release(self.library);
    }

    pub fn newFunctionWithName(
        self: *const Self,
        name: [*:0]const u8,
    ) !MTLFunction {
        const ns_name = try nsString(name);

        const function = send_object_return(
            self.library,
            self.new_function_with_name_sel,
            ns_name,
        ) orelse return error.FunctionCreationFailed;

        return MTLFunction.init(function);
    }
};

pub const MTLFunction = struct {
    function: ObjcId,

    const Self = @This();

    pub fn init(function: ObjcId) Self {
        return .{ .function = function };
    }

    pub fn deinit(self: *const Self) void {
        release(self.function);
    }
};

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.client_api, .no_api);

    const window = try glfw.Window.create(
        1280,
        720,
        "z3d - Cube",
        null,
        null,
    );
    defer window.destroy();

    const init_pool = objc_autoreleasePoolPush();
    defer objc_autoreleasePoolPop(init_pool);

    const ns_window = try NsWindow.init(window);
    const ns_view = try ns_window.contentView();
    const metal_layer = try CAMetalLayer.init();

    const mtl_device = try MTLDevice.init();
    defer mtl_device.deinit();

    const mtl_library = try MTLLibrary.init(
        mtl_device,
        "examples/cube/shaders.metallib",
    );
    defer mtl_library.deinit();

    std.debug.print("MTLLibrary: {*}\n", .{mtl_library.library});

    const vertex_fn = try mtl_library.newFunctionWithName("vertex_main");
    defer vertex_fn.deinit();

    const fragment_fn = try mtl_library.newFunctionWithName("fragment_main");
    defer fragment_fn.deinit();

    std.debug.print("Vertex function: {*}\n", .{vertex_fn.function});
    std.debug.print("Fragment function: {*}\n", .{fragment_fn.function});

    const mtl_cmd_q = try mtl_device.newCommandQueue();
    defer mtl_cmd_q.deinit();

    ns_view.setWantsLayer(true);
    ns_view.setLayer(metal_layer);
    metal_layer.setDevice(mtl_device);

    var n: f64 = 0.0;

    while (!window.shouldClose()) : (n += 0.005) {
        glfw.pollEvents();

        const pool = objc_autoreleasePoolPush();
        defer objc_autoreleasePoolPop(pool);

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
            return ObjcErr.DrawableUnavailable;

        const texture = try drawable.texture();

        const mtl_render_pass_descriptor = try MTLRenderPassDescriptor.init();
        const attachments_arr = try mtl_render_pass_descriptor.colorAttachments();
        const attachment = try attachments_arr.sub(0);

        attachment.setTexture(texture);
        attachment.setLoadAction(.clear);
        attachment.setStoreAction(.store);
        attachment.setClearColor(.{
            .red = 0.1,
            .green = n,
            .blue = 0.8,
            .alpha = 1.0,
        });

        const encoder = try cmd_buffer.renderCommandEncoder(
            mtl_render_pass_descriptor,
        );

        encoder.endEncoding();
        cmd_buffer.presentDrawable(drawable);
        cmd_buffer.commit();
    }
}
