const std = @import("std");
const sdl = @import("sdl");

pub const Renderer = struct {
    const Self = @This();

    renderer: *sdl.SDL_Renderer = undefined,
    window: *sdl.SDL_Window = undefined,

    pub fn init(self: *Self, window: *sdl.SDL_Window) !void {
        const renderer = sdl.SDL_CreateRenderer(window, null) orelse {
            std.debug.print("SDL_CreateRenderer failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlCreateRendererFailed;
        };
        self.renderer = renderer;
        self.window = window;
    }

    pub fn deinit(self: *Self) void {
        sdl.SDL_DestroyRenderer(self.renderer);
    }

    // find something to pass in
    pub fn render(self: *Self) !void {
        // 1. clear the framebuffer first (fills with current draw color)
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 12, 12, 24, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        try self.clear();

        // 2. switch to the point color and draw
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 255, 60, 60, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        if (!sdl.SDL_RenderPoint(self.renderer, 200, 200)) {
            std.debug.print("RenderPoint failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        if (!sdl.SDL_RenderPoint(self.renderer, 400, 200)) {
            std.debug.print("RenderPoint failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        if (!sdl.SDL_RenderPoint(self.renderer, 200, 600)) {
            std.debug.print("RenderPoint failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }

        // 3. only then show it on screen
        _ = sdl.SDL_RenderPresent(self.renderer);
    }

    // helper function
    fn clear(self: *Self) !void {
        if (!sdl.SDL_RenderClear(self.renderer)) {
            std.debug.print("RenderClear failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
    }
};
