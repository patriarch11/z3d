pub const Id = *anyopaque;
pub const Sel = *anyopaque;
pub const NsError = Id;

pub extern "objc" fn sel_registerName(
    name: [*:0]const u8,
) ?Sel;

pub extern "objc" fn objc_getClass(
    name: [*:0]const u8,
) ?Id;

pub extern "objc" fn objc_autoreleasePoolPush() *anyopaque;
pub extern "objc" fn objc_autoreleasePoolPop(pool: *anyopaque) void;

pub extern "objc" fn objc_msgSend() callconv(.c) void;

pub const SendFn = *const fn (
    Id,
    Sel,
) callconv(.c) ?Id;

pub const SendBoolFn = *const fn (
    Id,
    Sel,
    bool,
) callconv(.c) void;

pub const SendObjectFn = *const fn (
    Id,
    Sel,
    Id,
) callconv(.c) void;

pub const SendVoidFn = *const fn (
    Id,
    Sel,
) callconv(.c) void;

pub const SendIndexFn = *const fn (
    Id,
    Sel,
    usize,
) callconv(.c) ?Id;

pub const SendUsizeFn = *const fn (
    Id,
    Sel,
    usize,
) callconv(.c) void;

pub const SendObjectReturnFn = *const fn (
    Id,
    Sel,
    Id,
) callconv(.c) ?Id;

pub const SendCStringFn = *const fn (
    Id,
    Sel,
    [*:0]const u8,
) callconv(.c) ?Id;

pub const SendObjectErrorFn = *const fn (
    Id,
    Sel,
    Id,
    ?*?NsError,
) callconv(.c) ?Id;

pub const send: SendFn = @ptrCast(&objc_msgSend);
pub const send_bool: SendBoolFn = @ptrCast(&objc_msgSend);
pub const send_object: SendObjectFn = @ptrCast(&objc_msgSend);
pub const send_void: SendVoidFn = @ptrCast(&objc_msgSend);
pub const send_index: SendIndexFn = @ptrCast(&objc_msgSend);
pub const send_usize: SendUsizeFn = @ptrCast(&objc_msgSend);
pub const send_object_return: SendObjectReturnFn = @ptrCast(&objc_msgSend);
pub const send_cstring: SendCStringFn = @ptrCast(&objc_msgSend);
pub const send_object_error: SendObjectErrorFn = @ptrCast(&objc_msgSend);

pub const Error = error{
    ClassUnavailable,
    SelectorUnavailable,
    ObjectCreationFailed,
};

pub fn release(object: Id) void {
    const selector = sel_registerName("release") orelse unreachable;
    send_void(object, selector);
}

pub fn nsString(value: [*:0]const u8) !Id {
    const cls = objc_getClass("NSString") orelse
        return Error.ClassUnavailable;

    const selector = sel_registerName("stringWithUTF8String:") orelse
        return Error.SelectorUnavailable;

    return send_cstring(cls, selector, value) orelse
        Error.ObjectCreationFailed;
}
