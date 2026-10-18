const metal = @import("../metal/mod.zig"); // TODO: use absolute import path after new api would be done
pub const device = @import("device.zig");
pub const buffer = @import("buffer.zig");

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
    };
}
