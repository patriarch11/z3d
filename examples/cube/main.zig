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

const send: SendFn = @ptrCast(&objc_msgSend);
const send_bool: SendBoolFn = @ptrCast(&objc_msgSend);
const send_object: SendObjectFn = @ptrCast(&objc_msgSend);

const ObjcErr = error{
    CocoaWindowUnavailable,
    ContentViewSelectorUnavailable,
    ContentViewUnavailable,
    CAMetalLayerClassUnavailable,
    CAMetalLayerSelectorUnavailable,
    CAMetalLayerCreationFailed,
    WantsLayerSelectorUnavailable,
    SetLayerSelectorUnavailable,
};

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

        return .{ .metal_layer = metal_layer };
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

    ns_view.setWantsLayer(true);
    ns_view.setLayer(metal_layer);

    while (!window.shouldClose()) {
        glfw.pollEvents();
    }
}
