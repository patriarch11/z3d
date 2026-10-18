const objc = @import("z3d").platform.macos.objc;
const cocoa = @import("z3d").platform.macos.cocoa;

pub const SendClearColorFn = *const fn (
    objc.Id,
    objc.Sel,
    MTLClearColor,
) callconv(.c) void;

pub const SendSizeFn = *const fn (
    objc.Id,
    objc.Sel,
    cocoa.CGSize,
) callconv(.c) void;

pub const SendDrawPrimitivesFn = *const fn (
    objc.Id,
    objc.Sel,
    usize,
    usize,
    usize,
) callconv(.c) void;

pub const SendNewBufferFn = *const fn (
    objc.Id,
    objc.Sel,
    [*]const u8,
    usize,
    usize,
) callconv(.c) ?objc.Id;

pub const SendVertexBufferFn = *const fn (
    objc.Id,
    objc.Sel,
    objc.Id,
    usize,
    usize,
) callconv(.c) void;

pub const SendDrawIndexedPrimitivesFn = *const fn (
    objc.Id,
    objc.Sel,
    usize, // primitive type
    usize, // index count
    usize, // index type
    objc.Id, // index buffer
    usize, // index buffer offset
) callconv(.c) void;

pub const SendVertexBytesFn = *const fn (
    objc.Id,
    objc.Sel,
    *const anyopaque,
    usize,
    usize,
) callconv(.c) void;

pub const MTLLoadAction = enum(usize) {
    dont_care = 0,
    load = 1,
    clear = 2,
};

pub const MTLStoreAction = enum(usize) {
    dont_care = 0,
    store = 1,
};

pub const MTLClearColor = extern struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

pub const MTLPixelFormat = enum(usize) {
    invalid = 0,
    bgra8_unorm = 80,
};

pub const MTLPrimitiveType = enum(usize) {
    point = 0,
    line = 1,
    line_strip = 2,
    triangle = 3,
    triangle_strip = 4,
};

pub const MTLIndexType = enum(usize) {
    uint16 = 0,
    uint32 = 1,
};
