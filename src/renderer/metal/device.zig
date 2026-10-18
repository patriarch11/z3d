const z3d = @import("z3d");
const buffer = @import("buffer.zig");

const objc = z3d.platform.macos.objc;
const errors = z3d.renderer.rhi.errors;
const rhi_device = z3d.renderer.rhi.device;
const rhi_buffer = z3d.renderer.rhi.buffer;

const Error = errors.Error;

extern "Metal" fn MTLCreateSystemDefaultDevice() ?objc.Id;

const SendNewBufferWithLengthFn = *const fn (
    objc.Id,
    objc.Sel,
    usize, // length
    usize, // options
) callconv(.c) ?objc.Id;

const send_new_buffer_with_lenght_fn: SendNewBufferWithLengthFn = @ptrCast(&objc.objc_msgSend);

pub const Device = struct {
    handle: objc.Id,
    new_buffer_sel: objc.Sel,

    const Self = @This();

    pub fn init() rhi_device.InitError!Self {
        const handle = MTLCreateSystemDefaultDevice() orelse
            return Error.DeviceUnavailable;
        const new_buffer_sel = objc.sel_registerName("newBufferWithLength:options:") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .handle = handle,
            .new_buffer_sel = new_buffer_sel,
        };
    }

    pub fn deinit(self: *Self) void {
        objc.release(self.handle);
        self.* = undefined;
    }

    pub fn createBuffer(self: *const Self, desc: rhi_buffer.BufferDesc) Error!buffer.Buffer {
        const handle = send_new_buffer_with_lenght_fn(
            self.handle,
            self.new_buffer_sel,
            desc.size,
            0,
        ) orelse return Error.BufferCreationFailed;

        return .{ .handle = handle, .size = desc.size };
    }

    pub fn writeBuffer(self: *const Self, buff: *buffer.Buffer, offset: usize, data: []const u8) !void {
        _ = self;
        try buff.write(offset, data);
    }
};
