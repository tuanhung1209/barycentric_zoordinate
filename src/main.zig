const std = @import("std");
const sdl = @import("sdl");
const helper = @import("helper.zig");

const Renderer = @import("renderer.zig").Renderer;

pub fn main(init: std.process.Init) !void {
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

    var renderer: Renderer = undefined;
    try renderer.init(window);

    var quit = false;
    while (!quit) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            if (event.type == sdl.SDL_EVENT_QUIT) quit = true;
        }
        try renderer.render();
    }

    std.debug.print("clean exit\n", .{});
}
