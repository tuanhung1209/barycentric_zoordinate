const std = @import("std");
const sdl = @import("sdl");

const Vec2 = @import("vec2.zig").Vec2;

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
    pub fn render(self: *Self, points: []const Vec2) !void {
        // 1. clear the framebuffer first (fills with current draw color)
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 12, 12, 24, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        try self.clear();

        // 2. switch to the point color and draw
        try self.renderPoints(points);
        try self.renderLine(points);

        // 3. only then show it on screen
        _ = sdl.SDL_RenderPresent(self.renderer);
    }

    // it a state machine, how can i architec this
    // seem like eacch function to do a percific thing then pass that function into render() ?
    // pass the data in to render() make more sense ?
    // i need to somehow architec sdl
    //pub fn renderTriangle(){}

    // helper function
    fn clear(self: *Self) !void {
        if (!sdl.SDL_RenderClear(self.renderer)) {
            std.debug.print("RenderClear failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
    }

    fn renderLine(self: *Self, points: []const Vec2) !void {
        std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 60, 60, 255, 255)) {
            return error.SdlRenderFailed;
        }

        for (points) |point1| {
            for (points) |point2| {
                if (!sdl.SDL_RenderLine(self.renderer, point1[0], point1[1], point2[0], point2[1])) {
                    std.debug.print("RenderPoint failed: {s}\n", .{sdl.SDL_GetError()});
                    return error.SdlRenderFailed;
                }
            }
        }
    }

    fn renderPoints(self: *Self, points: []const Vec2) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 255, 60, 60, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }

        for (points) |point| {
            if (!sdl.SDL_RenderPoint(self.renderer, point[0], point[1])) {
                std.debug.print("RenderPoint failed: {s}\n", .{sdl.SDL_GetError()});
                return error.SdlRenderFailed;
            }
        }
    }
};
