const glfw = @import("zglfw");
const objc = @import("macos/objc.zig");

pub const NativeWindowHandle = union(enum) {
    cocoa: *anyopaque,

    win32: struct {
        hwnd: *anyopaque,
        hinstance: *anyopaque,
    },

    xlib: struct {
        display: *anyopaque,
        window: usize,
    },

    wayland: struct {
        display: *anyopaque,
        surface: *anyopaque,
    },
};

pub const WindowDesc = struct {
    width: u32 = 1280,
    height: u32 = 720,
    title: [:0]const u8 = "z3d",
};

pub const Error = error{
    NativeWindowUnavailable,
};

pub const Window = struct {
    handle: *glfw.Window,

    const Self = @This();

    pub fn init(desc: WindowDesc) !Self {
        try glfw.init();
        glfw.windowHint(.client_api, .no_api);
        return .{
            .handle = try glfw.Window.create(
                @intCast(desc.width),
                @intCast(desc.height),
                desc.title,
                null,
                null,
            ),
        };
    }

    pub fn deinit(self: *Self) void {
        self.handle.destroy();
        glfw.terminate();
        self.* = undefined;
    }

    pub fn shouldClose(self: *const Self) bool {
        return self.handle.shouldClose();
    }

    pub fn pollEvents(self: *Self) void {
        _ = self;
        glfw.pollEvents();
    }

    pub fn getFramebufferSize(self: *const Self) [2]i32 {
        return self.handle.getFramebufferSize();
    }

    pub fn nativeHandle(self: *const Self) !NativeWindowHandle {
        // TODO: add platform specific
        // macOS -> glfw.getCocoaWindow(self.handle)
        // Windows -> glfw.getWin32Window(self.handle)
        // Linux -> corresponding native window
        const cocoa_window = glfw.getCocoaWindow(self.handle) orelse
            return Error.NativeWindowUnavailable;

        return .{
            .cocoa = cocoa_window,
        };
    }
};
