const z3d = @import("z3d");

const Device = @import("device.zig").Device;

const objc = z3d.platform.macos.objc;
const errors = z3d.renderer.rhi.errors;
const NativeWindowHandle = z3d.platform.window.NativeWindowHandle;

const Error = errors.Error;

pub const Surface = struct {
    layer: objc.Id,
    view: objc.Id,

    const Self = @This();

    pub fn init(
        device: *Device,
        window: NativeWindowHandle,
    ) !Self {
        const cocoa_window = switch (window) {
            .cocoa => |handle| handle,
            else => return Error.UnsupportedWindowHandle,
        };

        const content_view_sel = objc.sel_registerName("contentView") orelse
            return objc.Error.SelectorUnavailable;

        // view
        const view = objc.send(cocoa_window, content_view_sel) orelse
            return Error.SurfaceCreationFailed;

        const layer_class = objc.objc_getClass("CAMetalLayer") orelse
            return objc.Error.ClassUnavailable;
        const alloc_sel = objc.sel_registerName("alloc").?;
        const init_sel = objc.sel_registerName("init").?;

        const allocated = objc.send(layer_class, alloc_sel) orelse
            return Error.SurfaceCreationFailed;

        // layer
        const layer = objc.send(allocated, init_sel) orelse
            return Error.SurfaceCreationFailed;

        const set_device_sel = objc.sel_registerName("setDevice:") orelse
            return objc.Error.SelectorUnavailable;

        // set device
        objc.send_object(layer, set_device_sel, device.handle);

        const set_wants_layer_sel = objc.sel_registerName("setWantsLayer:") orelse
            return objc.Error.SelectorUnavailable;
        const set_layer_sel = objc.sel_registerName("setLayer:") orelse
            return objc.Error.SelectorUnavailable;

        // set wants layer
        objc.send_bool(view, set_wants_layer_sel, true);
        // set layer
        objc.send_object(view, set_layer_sel, layer);

        return .{ .layer = layer, .view = view };
    }

    pub fn deinit(self: *Self) void {
        const set_layer_sel = objc.sel_registerName("setLayer:").?;

        objc.send_optional_object(self.view, set_layer_sel, null);

        objc.release(self.layer);

        self.* = undefined;
    }
};
