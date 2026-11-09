const std = @import("std");

const Vec2 = @import("vec2.zig").Vec2;

pub const Triangle = struct {
    const Self = @This();

    allocator: std.mem.Allocator = undefined,

    points: std.ArrayList(Vec2) = undefined,

    pub fn init(self: *Self, allocator: std.mem.Allocator) void {
        self.allocator = allocator;
        self.points = .empty;
    }

    pub fn deinit(self: *Self) void {
        self.points.deinit(self.allocator);
    }

    pub fn addPoint(self: *Self, point: Vec2) !void {
        try self.points.append(self.allocator, point);
    }
};
