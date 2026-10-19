pub const device = @import("device.zig");
pub const buffer = @import("buffer.zig");
pub const errors = @import("errors.zig");
pub const surface = @import("surface.zig");

const z3d = @import("z3d");

const metal = z3d.renderer.metal;

pub const Backend = enum {
    metal,
    vulkan,
    d3d12,
};

pub fn API(comptime backend: Backend) type {
    const Impl = switch (backend) {
        .metal => metal,
        .vulkan => @compileError("Vulkan is not implemented yet"),
        .d3d12 => @compileError("Direct3D 12 is not implemented yet"),
    };

    return struct {
        pub const Device = device.Device(Impl);
        pub const Buffer = buffer.Buffer(Impl.Buffer);
        pub const Surface = surface.Surface(Impl);
    };
}
