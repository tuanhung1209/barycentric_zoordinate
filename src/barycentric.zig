const std = @import("std");

const Vec2 = @import("helper.zig").Vec2;
const Vec3 = @import("helper.zig").Vec3;
const Color3 = @import("helper.zig").Color3;

const Triangle = @import("triangle.zig").Triangle;

// bassicly cross
// if result >= 0 => point to screen and to the right
// if all 3 point of p is to the right => inside triangle
pub inline fn edgeFunction(tpoint1: Vec2, tpoint2: Vec2, point: Vec2) f64 {
    // calculate the vector
    const v21: Vec2 = tpoint2 - tpoint1;
    const vp1: Vec2 = point - tpoint1;

    // the cross
    return v21[0] * vp1[1] - v21[1] * vp1[0];
}

pub inline fn barycentric(triangle: *const Triangle, point: Vec2) Vec3 {
    const p1: Vec2 = triangle.vertices.items[0].position;
    const p2: Vec2 = triangle.vertices.items[1].position;
    const p3: Vec2 = triangle.vertices.items[2].position;

    const area: f64 = edgeFunction(p1, p2, p3);

    const w1: f64 = edgeFunction(p2, p3, point) / area;
    const w2: f64 = edgeFunction(p3, p1, point) / area;
    const w3: f64 = 1 - w1 - w2;

    return .{ w1, w2, w3 };
}

pub inline fn interpolate(triangle: *const Triangle, weights: Vec3) Color3 {
    const p1: Color3 = triangle.vertices.items[0].color;
    const p2: Color3 = triangle.vertices.items[1].color;
    const p3: Color3 = triangle.vertices.items[2].color;

    // should be always equal to u8 ?
    const r: u8 = @trunc(@as(f64, @floatFromInt(p1[0])) * weights[0] + @as(f64, @floatFromInt(p2[0])) * weights[1] + @as(f64, @floatFromInt(p3[0])) * weights[2]);
    const g: u8 = @trunc(@as(f64, @floatFromInt(p1[1])) * weights[0] + @as(f64, @floatFromInt(p2[1])) * weights[1] + @as(f64, @floatFromInt(p3[1])) * weights[2]);
    const b: u8 = @trunc(@as(f64, @floatFromInt(p1[2])) * weights[0] + @as(f64, @floatFromInt(p2[2])) * weights[1] + @as(f64, @floatFromInt(p3[2])) * weights[2]);

    return .{ r, g, b };
}
