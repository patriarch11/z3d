const metal = @import("../metal/device.zig"); // TODO: use absolute import path after new api would be done
const device = @import("device.zig");

pub const Backend = enum {
    metal,
    vulkan,
    d3d12,
};

pub fn API(comptime backend: Backend) type {
    const Impl = switch (backend) {
        .metal => metal.Device,
        .vulkan => @compileError("Vulkan is not implemented yet"),
        .d3d12 => @compileError("Direct3D 12 is not implemented yet"),
    };

    return struct {
        pub const Device = device.Device(Impl);
    };
}
