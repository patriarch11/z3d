const std = @import("std");
const z3d = @import("z3d");

const objc = z3d.platform.macos.objc;
const errors = z3d.renderer.rhi.errors;

const Error = errors.Error;

const SendContentsFn = *const fn (
    objc.Id,
    objc.Sel,
) callconv(.c) ?[*]u8;

const send_contents: SendContentsFn = @ptrCast(&objc.objc_msgSend);

pub const Buffer = struct {
    handle: objc.Id,
    size: usize,

    const Self = @This();

    pub fn deinit(self: *Self) void {
        objc.release(self.handle);
        self.* = undefined;
    }

    pub fn write(self: *Self, offset: usize, data: []const u8) !void { // TODO: continue from here
        if (offset > self.size or
            data.len > self.size - offset)
        {
            return Error.BufferOutOfBounds;
        }

        const contents_sel = objc.sel_registerName("contents") orelse
            return objc.Error.SelectorUnavailable;

        const ptr = send_contents(
            self.handle,
            contents_sel,
        ) orelse return Error.BufferNotMappable;

        @memcpy(
            ptr[offset..][0..data.len],
            data,
        );
    }
};
