pub const Error = error{
    DeviceUnavailable,
    BufferCreationFailed,
    InvalidBufferUsage,
    BufferOutOfBounds,
    BufferNotMappable,
    UnsupportedWindowHandle,
    SurfaceCreationFailed,
};
