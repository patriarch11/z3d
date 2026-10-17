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

const send: SendFn = @ptrCast(&objc_msgSend);
const send_bool: SendBoolFn = @ptrCast(&objc_msgSend);
const send_object: SendObjectFn = @ptrCast(&objc_msgSend);
const send_void: SendVoidFn = @ptrCast(&objc_msgSend);
const send_index: SendIndexFn = @ptrCast(&objc_msgSend);
const send_usize: SendUsizeFn = @ptrCast(&objc_msgSend);
const send_clear_color: SendClearColorFn = @ptrCast(&objc_msgSend);

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

fn release(object: ObjcId) void {
    const selector = sel_registerName("release") orelse unreachable;
    send_void(object, selector);
}
pub const NsWindow = struct {
    ns_window: ObjcId,
    content_view_sel: ObjcSel,

    const Self = @This();

    pub fn init(window: *glfw.Window) !Self {
        const ns_window = glfw.getCocoaWindow(window) orelse
            return ObjcErr.CocoaWindowUnavailable;

        std.debug.print("NSWindow: {*}\n", .{ns_window});

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

        std.debug.print("NSView: {*}\n", .{objc_ns_view});

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

    const Self = @This();

    pub fn init() !Self {
        const metal_layer_class = objc_getClass("CAMetalLayer") orelse
            return ObjcErr.CAMetalLayerClassUnavailable;

        std.debug.print("CAMetalLayer class: {*}\n", .{metal_layer_class});

        const layer_sel = sel_registerName("layer") orelse
            return ObjcErr.CAMetalLayerSelectorUnavailable;

        const metal_layer = send(metal_layer_class, layer_sel) orelse
            return ObjcErr.CAMetalLayerCreationFailed;

        std.debug.print("CAMetalLayer: {*}\n", .{metal_layer});

        const set_device_sel = sel_registerName("setDevice:") orelse
            return ObjcErr.SetDeviceSelectorUnavailable;

        const next_drawable_sel = sel_registerName("nextDrawable") orelse
            return ObjcErr.NextDrawableSelectorUnavailable;

        return .{
            .metal_layer = metal_layer,
            .set_device_sel = set_device_sel,
            .next_drawable_sel = next_drawable_sel,
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

        std.debug.print("MTLDevice: {*}\n", .{device});

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

        std.debug.print("MTLCommandQueue: {*}\n", .{command_queue});

        return MTLCommandQueue.init(command_queue);
    }
};

pub const MTLCommandQueue = struct {
    command_queue: ObjcId,

    const Self = @This();

    pub fn init(command_queue: ObjcId) Self {
        return .{ .command_queue = command_queue };
    }

    pub fn deinit(self: *const Self) void {
        release(self.command_queue);
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

        std.debug.print("MTLRenderPassDescriptor: {*}\n", .{descriptor});

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

        std.debug.print("ColorAttachment[0]: {*}\n", .{attachment});

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

    const ns_window = try NsWindow.init(window);
    const ns_view = try ns_window.contentView();
    const metal_layer = try CAMetalLayer.init();

    const mtl_device = try MTLDevice.init();
    defer mtl_device.deinit();

    const mtl_cmd_q = try mtl_device.newCommandQueue();
    defer mtl_cmd_q.deinit();

    ns_view.setWantsLayer(true);
    ns_view.setLayer(metal_layer);
    metal_layer.setDevice(mtl_device);

    const drawable = (try metal_layer.nextDrawable()) orelse
        return ObjcErr.DrawableUnavailable;

    std.debug.print("CAMetalDrawable: {*}\n", .{drawable.drawable});

    const texture = try drawable.texture();

    std.debug.print("MTLTexture: {*}\n", .{texture.texture});

    const mtl_render_pass_descriptor = try MTLRenderPassDescriptor.init();

    const attachments_arr = try mtl_render_pass_descriptor.colorAttachments();

    const attachment = try attachments_arr.sub(0);

    attachment.setTexture(texture);
    attachment.setLoadAction(.clear);
    attachment.setStoreAction(.store);

    attachment.setClearColor(.{
        .red = 0.1,
        .green = 0.2,
        .blue = 0.8,
        .alpha = 1.0,
    });

    while (!window.shouldClose()) {
        glfw.pollEvents();
    }
}
