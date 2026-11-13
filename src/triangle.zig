const std = @import("std");

const Vec2 = @import("helper.zig").Vec2;
const Color3 = @import("helper.zig").Color3;
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
    // for loop only throught this triangle to render
    max_point_x: f32 = undefined,
    min_point_x: f32 = undefined,
    max_point_y: f32 = undefined,
    min_point_y: f32 = undefined,

    pub fn init(self: *Self, allocator: std.mem.Allocator) void {
        self.allocator = allocator;
        self.vertices = .empty;
        self.max_point_x = 0;
        self.min_point_x = std.math.floatMax(f32);
        self.max_point_y = 0;
        self.min_point_y = std.math.floatMax(f32);
    }

    pub fn deinit(self: *Self) void {
        self.vertices.deinit(self.allocator);
    }

    pub fn appendVertex(self: *Self, vertex: Vertex) !void {
        try self.vertices.append(self.allocator, vertex);
        // here then check for min point and max point
        for (self.vertices.items) |self_vertex| {
            self.max_point_x = @max(self.max_point_x, self_vertex.position[0]);
            self.min_point_x = @min(self.min_point_x, self_vertex.position[0]);
            self.max_point_y = @max(self.max_point_y, self_vertex.position[1]);
            self.min_point_y = @min(self.min_point_y, self_vertex.position[1]);
        }
    }

    pub fn popVertex(self: *Self) !void {
        _ = self.vertices.pop();
    }

    pub fn checkPoint(self: *const Self, point: Vec2) bool {
        const verticies: []const Vertex = self.vertices.items;
        if (edgeCross(verticies[0].position, verticies[1].position, point) < 0) return false;
        if (edgeCross(verticies[1].position, verticies[2].position, point) < 0) return false;
        if (edgeCross(verticies[2].position, verticies[0].position, point) < 0) return false;

        return true;
    }
};
