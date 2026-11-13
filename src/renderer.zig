const std = @import("std");
const sdl = @import("sdl");

const Vec2 = @import("helper.zig").Vec2;
const Vec3 = @import("helper.zig").Vec3;
const Color3 = @import("helper.zig").Color3;
const Vertex = @import("triangle.zig").Vertex;
const Triangle = @import("triangle.zig").Triangle;
const vec = @import("helper.zig");
const barycentric = @import("barycentric.zig").barycentric;
const interpolate = @import("barycentric.zig").interpolate;

pub const Renderer = struct {
    const Self = @This();

    renderer: *sdl.SDL_Renderer = undefined,
    window: *sdl.SDL_Window = undefined,
    barycentric_tex: ?*sdl.SDL_Texture = null,

    width: u32 = undefined,
    height: u32 = undefined,

    pub fn init(self: *Self, window: *sdl.SDL_Window, width: u32, height: u32) !void {
        const renderer = sdl.SDL_CreateRenderer(window, null) orelse {
            std.debug.print("SDL_CreateRenderer failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlCreateRendererFailed;
        };
        self.width = width;
        self.height = height;
        self.renderer = renderer;
        self.window = window;
        self.barycentric_tex = null;
    }

    pub fn deinit(self: *Self) void {
        if (self.barycentric_tex) |tex| {
            sdl.SDL_DestroyTexture(tex);
        }
        sdl.SDL_DestroyRenderer(self.renderer);
    }

    pub fn render(self: *Self, triangle: *const Triangle, show_barycentric: bool) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 12, 12, 24, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        try self.clear();

        if (show_barycentric) {
            try self.bakeTriangleTexture(triangle);
            if (!sdl.SDL_RenderTexture(self.renderer, self.barycentric_tex, null, null)) {
                std.debug.print("SDL_RenderTexture failed: {s}\n", .{sdl.SDL_GetError()});
                return error.SdlRenderFailed;
            }
        }

        try self.renderLine(triangle.vertices.items);
        try self.renderLineToPoint(triangle);
        try self.renderPoints(triangle.vertices.items);

        _ = sdl.SDL_RenderPresent(self.renderer);
    }

    // helper function
    fn bakeTriangleTexture(self: *Self, triangle: *const Triangle) !void {
        if (self.barycentric_tex != null) return;

        var w: c_int = @intCast(self.width);
        var h: c_int = @intCast(self.height);
        _ = sdl.SDL_GetWindowSize(self.window, &w, &h);

        const tex = sdl.SDL_CreateTexture(
            self.renderer,
            sdl.SDL_PIXELFORMAT_RGBA8888,
            sdl.SDL_TEXTUREACCESS_TARGET,
            w,
            h,
        ) orelse {
            std.debug.print("SDL_CreateTexture failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlCreateTextureFailed;
        };

        _ = sdl.SDL_SetTextureBlendMode(tex, sdl.SDL_BLENDMODE_BLEND);

        if (!sdl.SDL_SetRenderTarget(self.renderer, tex)) {
            std.debug.print("SDL_SetRenderTarget failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }
        _ = sdl.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, 0);
        try self.clear();

        try self.renderFillTriangle(triangle);

        if (!sdl.SDL_SetRenderTarget(self.renderer, null)) {
            std.debug.print("SDL_SetRenderTarget reset failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }

        self.barycentric_tex = tex;
    }

    fn renderFillTriangle(self: *Self, triangle: *const Triangle) !void {
        const start_x: u32 = @trunc(triangle.min_point_x);
        const end_x: u32 = @trunc(triangle.max_point_x);
        const start_y: u32 = @trunc(triangle.min_point_y);
        const end_y: u32 = @trunc(triangle.max_point_y);

        // in here only render point that are in triangle
        // although it could be interesting to check what interpolate outside triangle

        for (start_x..end_x) |x| {
            for (start_y..end_y) |y| {
                const fx: f32 = @as(f32, @floatFromInt(x));
                const fy: f32 = @as(f32, @floatFromInt(y));
                if (triangle.checkPoint(.{ fx, fy })) {
                    const weights: Vec3 = barycentric(triangle, .{ fx, fy });
                    const color: Color3 = interpolate(triangle, weights);

                    if (!sdl.SDL_SetRenderDrawColor(self.renderer, color[0], color[1], color[2], 255)) {
                        std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
                        return error.SdlRenderFailed;
                    }
                    try self.renderBigPoint(
                        fx,
                        fy,
                        3.0,
                    );
                }
            }
        }
    }

    fn renderLineToPoint(self: *Self, triangle: *const Triangle) !void {
        var x: f32 = 0;
        var y: f32 = 0;
        const mouse: sdl.SDL_MouseButtonFlags = sdl.SDL_GetMouseState(&x, &y);
        _ = mouse;

        // print out the color weight
        if (triangle.checkPoint(.{ x, y })) {
            std.debug.print("this point is inside the triangle\n", .{});
            const weights: Vec3 = barycentric(triangle, .{ x, y });
            std.debug.print("w1 :{d:.2}, w2 :{d:.2}, w3 :{d:.2}\n", .{ weights[0], weights[1], weights[2] });

            if (!sdl.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255)) {
                std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
                return error.SdlRenderFailed;
            }

            for (triangle.vertices.items) |vertex| {
                if (!sdl.SDL_RenderLine(
                    self.renderer,
                    vertex.position[0],
                    vertex.position[1],
                    x,
                    y,
                )) {
                    std.debug.print("RenderPoint failed: {s}\n", .{sdl.SDL_GetError()});
                    return error.SdlRenderFailed;
                }
            }
        }
    }

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
            if (!sdl.SDL_RenderDebugText(self.renderer, vertex.position[0] - 30, vertex.position[1] - 30, vertex_name.ptr)) {
                std.debug.print("render debug text failed: {s}\n", .{sdl.SDL_GetError()});
                return error.SdlRenderFailed;
            }

            try self.renderBigPoint(vertex.position[0], vertex.position[1], 1);
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
