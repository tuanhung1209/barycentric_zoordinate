const std = @import("std");
const sdl = @import("sdl");
const helper = @import("helper.zig");

const Renderer = @import("renderer.zig").Renderer;
const Triangle = @import("triangle.zig").Triangle;

const Vec2 = @import("vec2.zig").Vec2;
const vec2 = @import("vec2.zig");

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
        600,
        sdl.SDL_WINDOW_RESIZABLE,
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
    try triangle.addPoint(vec2.init(400, 200));
    try triangle.addPoint(vec2.init(600, 600));
    try triangle.addPoint(vec2.init(200, 600));

    var renderer: Renderer = undefined;
    try renderer.init(window);

    var quit = false;
    while (!quit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            if (event.type == sdl.SDL_EVENT_QUIT) quit = true;
        }
        try renderer.render(triangle.points.items);
    }

    std.debug.print("clean exit\n", .{});
}
