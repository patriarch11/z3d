pub const BufferUsage = packed struct(u32) {
    // Buffer contains vertex data used as input for the vertex shader.
    vertex: bool = false,

    // Buffer contains vertex indices used for indexed drawing.
    index: bool = false,

    // Buffer contains read-only data accessible by shaders,
    // such as transformation matrices, colors, or camera parameters.
    uniform: bool = false,

    // Buffer contains data that shaders can read and potentially write.
    // Commonly used for compute shaders and large data arrays.
    storage: bool = false,

    // Buffer can be used as the source of a GPU copy operation.
    copy_src: bool = false,

    // Buffer can be used as the destination of a GPU copy operation.
    copy_dst: bool = false,

    // Reserved bits for future usage flags.
    // Ensures the structure occupies exactly 32 bits.
    _padding: u26 = 0,
};

pub const BufferDesc = struct {
    size: usize,
    usage: BufferUsage,
};

pub fn Buffer(comptime Impl: type) type {
    return struct {
        impl: Impl,

        const Self = @This();

        pub fn deinit(self: *Self) void {
            self.impl.deinit();
            self.* = undefined;
        }

        pub fn write(self: *const Self, offset: usize, data: []const u8) !void {
            try self.impl.write(offset, data);
        }
    };
}
