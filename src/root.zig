//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

pub const math = @import("math/mod.zig");
pub const geometry = @import("geometry/mod.zig");

pub const platform = struct {
    pub const macos = struct {
        pub const objc = @import("platform/macos/objc.zig");
        pub const cocoa = @import("platform/macos/cocoa.zig");
    };
};

pub const renderer = struct {
    pub const rhi = @import("renderer/rhi/mod.zig");
    pub const metal = @import("renderer/metal/mod.zig");
};

test {
    _ = @import("math/mod.zig");
}
