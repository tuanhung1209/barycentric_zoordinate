const std = @import("std");
const sdl = @import("sdl");

const Vec2 = @import("math.zig").Vec2;
const Color3 = @import("math.zig").Color3;
const Vertex = @import("triangle.zig").Vertex;
const Triangle = @import("triangle.zig").Triangle;

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

    pub fn render(self: *Self, triangle: *Triangle) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 12, 12, 24, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        try self.clear();

        try self.renderLine(triangle.vertices.items);
        try self.renderPoints(triangle.vertices.items);
        try self.renderCheck(triangle);

        _ = sdl.SDL_RenderPresent(self.renderer);
    }

    // it a state machine, how can i architec this
    // seem like eacch function to do a percific thing then pass that function into render() ?
    // pass the data in to render() make more sense ?
    // i need to somehow architec sdl
    //pub fn renderTriangle(){}
    fn renderCheck(self: *Self, triangle: *Triangle) !void {
        _ = self;
        var x: f32 = 0;
        var y: f32 = 0;

        const mouse: sdl.SDL_MouseButtonFlags = sdl.SDL_GetMouseState(&x, &y);
        _ = mouse;

        if (triangle.checkPoint(.{ x, y })) {
            std.debug.print("inside the triangle\n", .{});
        }
    }

    // helper function
    fn clear(self: *Self) !void {
        if (!sdl.SDL_RenderClear(self.renderer)) {
            std.debug.print("RenderClear failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
    }

    fn renderLine(self: *Self, verticies: []const Vertex) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }

        for (verticies) |vertex1| {
            for (verticies) |vertex2| {
                if (!sdl.SDL_RenderLine(
                    self.renderer,
                    vertex1.position[0],
                    vertex1.position[1],
                    vertex2.position[0],
                    vertex2.position[1],
                )) {
                    std.debug.print("RenderPoint failed: {s}\n", .{sdl.SDL_GetError()});
                    return error.SdlRenderFailed;
                }
            }
        }
    }

    fn renderPoints(self: *Self, verticies: []const Vertex) !void {
        var i: u32 = 0;
        for (verticies) |vertex| {
            if (!sdl.SDL_SetRenderDrawColor(
                self.renderer,
                vertex.color[0],
                vertex.color[1],
                vertex.color[2],
                255,
            )) {
                std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
                return error.SdlRenderFailed;
            }

            var buffer: [16]u8 = undefined;
            const vertex_name: []const u8 = try std.mem.printSentinel(&buffer, "v{d}", .{i}, 0);

            i = i + 1;
            // how can i offset this to make sense.ptr
            if (!sdl.SDL_RenderDebugText(self.renderer, vertex.position[0] - 30, vertex.position[1] - 30, vertex_name.ptr)) {
                std.debug.print("render debug text failed: {s}\n", .{sdl.SDL_GetError()});
                return error.SdlRenderFailed;
            }

            try self.renderBigPoint(vertex.position[0], vertex.position[1], 10.0);
        }
    }

    fn renderBigPoint(self: *Self, x: f32, y: f32, size: f32) !void {
        var rec: sdl.SDL_FRect = undefined;
        rec.x = x - (size / 2);
        rec.y = y - (size / 2);
        rec.w = size;
        rec.h = size;

        if (!sdl.SDL_RenderFillRect(self.renderer, &rec)) {
            std.debug.print("render big point failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
    }
};
