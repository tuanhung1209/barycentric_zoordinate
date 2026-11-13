const std = @import("std");
const sdl = @import("sdl");
const helper = @import("helper.zig");

const Renderer = @import("renderer.zig").Renderer;
const Triangle = @import("triangle.zig").Triangle;
const Vertex = @import("triangle.zig").Vertex;

const Vec2 = helper.Vec2;

const WINDOW_WIDTH: u32 = 1000;
const WINDOW_HEIGHT: u32 = 1000;

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
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
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
        .position = helper.rvec2Init(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT / 2),
        .color = helper.color3Init(255, 0, 0),
    });
    try triangle.appendVertex(.{
        // bottom right half
        .position = helper.rvec2Init(WINDOW_WIDTH / 2, WINDOW_WIDTH, WINDOW_HEIGHT / 2, WINDOW_HEIGHT),
        .color = helper.color3Init(0, 255, 0),
    });
    try triangle.appendVertex(.{
        // bottom left half
        .position = helper.rvec2Init(0, WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, WINDOW_HEIGHT),
        .color = helper.color3Init(0, 0, 255),
    });

    // TODO : a debug message with the 3 weight and their caculation
    // weight
    // mouse position
    // indisde or outside the triangle

    var renderer: Renderer = undefined;
    try renderer.init(window, WINDOW_WIDTH, WINDOW_HEIGHT);
    defer renderer.deinit();

    var showBarycentric: bool = false;

    var quit = false;
    while (!quit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            if (event.type == sdl.SDL_EVENT_QUIT) {
                quit = true;
            } else if (event.type == sdl.SDL_EVENT_KEY_DOWN) {
                if (event.key.key == sdl.SDLK_E) {
                    showBarycentric = !showBarycentric;
                }
            }
        }

        try renderer.render(&triangle, showBarycentric);
    }

    std.debug.print("clean exit\n", .{});
}
