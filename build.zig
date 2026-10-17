const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const z3d = b.addModule("z3d", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });

    const cube = b.addExecutable(.{
        .name = "cube",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/cube/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "z3d", .module = z3d },
                .{ .name = "zglfw", .module = zglfw.module("root") },
            },
        }),
    });

    cube.root_module.linkLibrary(zglfw.artifact("glfw"));
    cube.root_module.linkSystemLibrary("objc", .{});
    cube.root_module.linkFramework("QuartzCore", .{}); // CAMetalLayer
    cube.root_module.linkFramework("Metal", .{}); // MTLCreateSystemDefaultDevice

    const metal_compile = b.addSystemCommand(&.{
        "xcrun",
        "-sdk",
        "macosx",
        "metal",
        "-c",
    });

    metal_compile.addFileArg(b.path("examples/cube/shaders.metal"));
    metal_compile.addArg("-o");

    const air = metal_compile.addOutputFileArg("shaders.air");

    const metal_link = b.addSystemCommand(&.{
        "xcrun",
        "-sdk",
        "macosx",
        "metallib",
    });

    metal_link.addFileArg(air);
    metal_link.addArg("-o");

    const metallib = metal_link.addOutputFileArg("shaders.metallib");

    const install_metallib = b.addInstallFile(
        metallib,
        "shaders.metallib",
    );

    const cube_step = b.step("cube", "Run cube example");
    const run_cube = b.addRunArtifact(cube);

    run_cube.step.dependOn(&install_metallib.step);
    cube_step.dependOn(&run_cube.step);

    const tests = b.addTest(.{
        .root_module = z3d,
    });

    const test_step = b.step("test", "Run z3d tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
