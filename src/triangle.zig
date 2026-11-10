const std = @import("std");

const Vec2 = @import("math.zig").Vec2;
const Color3 = @import("math.zig").Color3;
const edgeCross = @import("barycentric.zig").edgeFunction;

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

    pub fn checkPoint(self: *Self, point: Vec2) bool {
        const verticies: []const Vertex = self.vertices.items;
        if (edgeCross(verticies[0].position, verticies[1].position, point) < 0) return false;
        if (edgeCross(verticies[1].position, verticies[2].position, point) < 0) return false;
        if (edgeCross(verticies[2].position, verticies[0].position, point) < 0) return false;

        return true;
    }
};
