const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const z3d = b.addModule("z3d", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    z3d.addImport("z3d", z3d);

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });

    //------------------------
    // example cube render with low-lewel metal api
    //------------------------
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

    //------------------------
    // example cube render with new abstract api
    //------------------------
    const cube_new_api = b.addExecutable(.{
        .name = "cube",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/cube_new_api/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "z3d", .module = z3d },
                .{ .name = "zglfw", .module = zglfw.module("root") },
            },
        }),
    });

    cube_new_api.root_module.linkLibrary(zglfw.artifact("glfw"));
    cube_new_api.root_module.linkSystemLibrary("objc", .{});
    cube_new_api.root_module.linkFramework("QuartzCore", .{}); // CAMetalLayer
    cube_new_api.root_module.linkFramework("Metal", .{}); // MTLCreateSystemDefaultDevice

    //------------------------
    // metal shaders compilation
    //------------------------
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
    // ---
    // old cube example
    // ---
    const cube_step = b.step("cube", "Run cube example");
    const run_cube = b.addRunArtifact(cube);

    run_cube.step.dependOn(&install_metallib.step);
    cube_step.dependOn(&run_cube.step);

    // ---
    // new
    // ---
    const new_api_cube_step = b.step("cube-new-api", "Run cube example");
    const run_new_api_cube_step = b.addRunArtifact(cube_new_api);

    run_new_api_cube_step.step.dependOn(&install_metallib.step);
    new_api_cube_step.dependOn(&run_new_api_cube_step.step);

    // ---
    // tests
    // ---
    const tests = b.addTest(.{
        .root_module = z3d,
    });

    const test_step = b.step("test", "Run z3d tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
