const std = @import("std");

pub const Vec2 = @Vector(2, f32);

// use this function for different number init, use @splat for same num
pub inline fn init(x: f32, y: f32) Vec2 {
    return .{ x, y };
}
