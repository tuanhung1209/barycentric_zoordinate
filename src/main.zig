const std = @import("std");
const sdl = @import("sdl");
const helper = @import("helper.zig");

const Renderer = @import("renderer.zig").Renderer;
const Triangle = @import("triangle.zig").Triangle;
const Vertex = @import("triangle.zig").Vertex;

const Vec2 = @import("math.zig").Vec2;
const math = @import("math.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    helper.randomInit(io);

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        std.debug.print("SDL_Init failed: {s}\n", .{sdl.SDL_GetError()});
        return error.SdlInitFailed;
    }
    defer sdl.SDL_Quit();

    const window: *sdl.SDL_Window = sdl.SDL_CreateWindow(
        "barycentric zoordinates",
        800,
        800,
        0,
    ) orelse {
        std.debug.print("SDL_CreateWindow failed: {s}\n", .{sdl.SDL_GetError()});
        return error.SdlCreateWindowFailed;
    };
    defer sdl.SDL_DestroyWindow(window);
    std.debug.print("window up — close it to quit\n", .{});

    // a list of trigle or objecct would be better but meh
    var triangle: Triangle = undefined;
    triangle.init(allocator);
    defer triangle.deinit();
    try triangle.appendVertex(.{
        // top half
        .position = math.rvec2Init(0, 800, 0, 400),
        .color = math.color3Init(255, 0, 0),
    });
    try triangle.appendVertex(.{
        // bottom left half
        .position = math.rvec2Init(400, 800, 400, 800),
        .color = math.color3Init(0, 255, 0),
    });
    try triangle.appendVertex(.{
        // bottom right half
        .position = math.rvec2Init(0, 400, 400, 800),
        .color = math.color3Init(0, 0, 255),
    });

    // TODO : Then color/interpolate the triangle
    // TODO : a debug message with the 3 weight and their caculation

    var renderer: Renderer = undefined;
    try renderer.init(window);

    var quit = false;
    while (!quit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            if (event.type == sdl.SDL_EVENT_QUIT) quit = true;
        }
        try renderer.render(&triangle);
    }

    std.debug.print("clean exit\n", .{});
}
