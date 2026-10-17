const std = @import("std");
const glfw = @import("zglfw");

const ObjcId = *anyopaque;
const ObjcSel = *anyopaque;

extern "objc" fn sel_registerName(
    name: [*:0]const u8,
) ?ObjcSel;

extern "objc" fn objc_msgSend() callconv(.c) void;

const SendFn = *const fn (
    ObjcId,
    ObjcSel,
) callconv(.c) ?ObjcId;

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

    const ns_window = glfw.getCocoaWindow(window) orelse
        return error.CocoaWindowUnavailable;

    std.debug.print("NSWindow: {*}\n", .{ns_window});

    const content_view_sel = sel_registerName("contentView") orelse
        return error.SelectorUnavailable;

    const send: SendFn = @ptrCast(&objc_msgSend);

    const ns_view = send(ns_window, content_view_sel) orelse
        return error.ContentViewUnavailable;

    std.debug.print("NSView: {*}\n", .{ns_view});

    while (!window.shouldClose()) {
        glfw.pollEvents();
    }
}
