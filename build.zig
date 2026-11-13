const std = @import("std");
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const exe = b.addExecutable(.{
        .name = "barycentric_zoordinates",
        .root_module = exe_mod,
    });

    const sdl_dep = b.dependency("sdl", .{ .target = target, .optimize = optimize });
    const sdl_lib = sdl_dep.artifact("SDL3");
    exe_mod.linkLibrary(sdl_lib);

    const translate_c_dep = b.dependency("translate_c", .{});
    const translator: Translator = .init(translate_c_dep, .{
        .c_source_file = b.addWriteFiles().add("sdl_shim.h",
            \\#define SDL_DISABLE_OLD_NAMES
            \\#include <SDL3/SDL.h>
            \\#define SDL_MAIN_HANDLED
            \\#include <SDL3/SDL_main.h>
        ),
        .target = target,
        .optimize = optimize,
    });
    translator.linkLibrary(sdl_lib);

    exe_mod.addImport("sdl", translator.mod);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.addPassthruArgs();
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
