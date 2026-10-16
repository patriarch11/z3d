//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

test {
    _ = @import("math/_vec_test.zig");
    _ = @import("math/mat_test.zig");
    _ = @import("math/transform_test.zig");
}
