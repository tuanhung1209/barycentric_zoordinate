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

        const white: Color3 = @splat(255);
        try self.renderDebugText(10, 10, white, "show barycentric: {}", .{show_barycentric});

        try self.renderLine(triangle);
        try self.renderPoints(triangle);
        if (show_barycentric) {
            try self.bakeTriangleTexture(triangle);
            if (!sdl.SDL_RenderTexture(self.renderer, self.barycentric_tex, null, null)) {
                std.debug.print("SDL_RenderTexture failed: {s}\n", .{sdl.SDL_GetError()});
                return error.SdlRenderFailed;
            }
        }
        try self.renderLineToPoint(triangle);

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
                        4.0,
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

        const is_inside = triangle.checkPoint(.{ x, y });
        const white: Color3 = @splat(255);
        try self.renderDebugText(10, 25, white, "mouse position: ({d:.0}, {d:.0})", .{ x, y });
        try self.renderDebugText(10, 40, white, "is inside triangle: {}", .{is_inside});

        if (is_inside) {
            const weights: Vec3 = barycentric(triangle, .{ x, y });
            const color: Color3 = interpolate(triangle, weights);

            try self.renderDebugText(
                10,
                55,
                color,
                "w1: {d:.2} ({d}), w2: {d:.2} ({d}), w3: {d:.2} ({d})",
                .{ weights[0], color[0], weights[1], color[1], weights[2], color[2] },
            );

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

    fn renderLine(self: *Self, triangle: *const Triangle) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, 255, 255, 255, 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }

        for (triangle.vertices.items) |vertex1| {
            for (triangle.vertices.items) |vertex2| {
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

    fn renderPoints(self: *Self, triangle: *const Triangle) !void {
        var i: u32 = 0;

        const centroid: Vec2 = triangle.centroid();

        for (triangle.vertices.items) |vertex| {
            try self.renderDebugText(
                ((vertex.position[0] - centroid[0]) * 1.05) + centroid[0],
                ((vertex.position[1] - centroid[1]) * 1.05) + centroid[1],
                vertex.color,
                "v{d}",
                .{i},
            );
            i = i + 1;

            try self.renderBigPoint(vertex.position[0], vertex.position[1], 1);
        }
    }

    fn renderDebugText(
        self: *Self,
        x: f32,
        y: f32,
        color: Color3,
        comptime fmt: []const u8,
        args: anytype,
    ) !void {
        if (!sdl.SDL_SetRenderDrawColor(self.renderer, color[0], color[1], color[2], 255)) {
            std.debug.print("SetRenderDrawColor failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
        }

        var buf: [128]u8 = undefined;
        const text: []const u8 = try std.mem.printSentinel(&buf, fmt, args, 0);

        if (!sdl.SDL_RenderDebugText(self.renderer, x, y, text.ptr)) {
            std.debug.print("render debug text failed: {s}\n", .{sdl.SDL_GetError()});
            return error.SdlRenderFailed;
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
