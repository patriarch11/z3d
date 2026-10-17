const objc = @import("objc.zig");

pub const Error = error{
    ContentViewUnavailable,
};

pub const CGSize = extern struct {
    width: f64,
    height: f64,
};

pub const NsWindow = struct {
    ns_window: objc.Id,
    content_view_sel: objc.Sel,

    const Self = @This();

    pub fn init(ns_window: objc.Id) !Self {
        const content_view_sel = objc.sel_registerName("contentView") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .ns_window = ns_window,
            .content_view_sel = content_view_sel,
        };
    }

    pub fn contentView(self: *const Self) !NsView {
        const objc_ns_view = objc.send(self.ns_window, self.content_view_sel) orelse
            return Error.ContentViewUnavailable;

        return NsView.init(objc_ns_view);
    }
};

pub const NsView = struct {
    ns_view: objc.Id,
    set_wants_layer_sel: objc.Sel,
    set_layer_sel: objc.Sel,

    const Self = @This();

    pub fn init(ns_view: objc.Id) !Self {
        const set_wants_layer_sel = objc.sel_registerName("setWantsLayer:") orelse
            return objc.Error.SelectorUnavailable;

        const set_layer_sel = objc.sel_registerName("setLayer:") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .ns_view = ns_view,
            .set_wants_layer_sel = set_wants_layer_sel,
            .set_layer_sel = set_layer_sel,
        };
    }

    pub fn setWantsLayer(self: *const Self, wants: bool) void {
        objc.send_bool(self.ns_view, self.set_wants_layer_sel, wants);
    }

    pub fn setLayer(self: *const Self, layer: objc.Id) void {
        objc.send_object(self.ns_view, self.set_layer_sel, layer);
    }
};
