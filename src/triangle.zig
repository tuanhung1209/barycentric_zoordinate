const std = @import("std");

const Vec2 = @import("math.zig").Vec2;
const Color3 = @import("math.zig").Color3;

// tempoary
pub const Vertex = struct {
    position: Vec2 = undefined,
    color: Color3 = undefined,
};

pub const Triangle = struct {
    const Self = @This();

    allocator: std.mem.Allocator = undefined,

    vertices: std.ArrayList(Vertex) = undefined,

    pub fn init(self: *Self, allocator: std.mem.Allocator) void {
        self.allocator = allocator;
        self.vertices = .empty;
    }

    pub fn deinit(self: *Self) void {
        self.vertices.deinit(self.allocator);
    }

    pub fn addVertex(self: *Self, vertex: Vertex) !void {
        try self.vertices.append(self.allocator, vertex);
    }
};
