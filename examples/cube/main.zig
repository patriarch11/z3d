const glfw = @import("zglfw");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.windowHint(.client_api, .no_api);

    const window = try glfw.Window.create(
        1280,
        720,
        "z3d - Cube",
        null,
        null,
    );
    defer window.destroy();

    while (!window.shouldClose()) {
        glfw.pollEvents();
    }
}
