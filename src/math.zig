const std = @import("std");

pub const getRandomRange = @import("helper.zig").getRandomInRange;

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f64);
pub const Color3 = @Vector(3, u8);

// use this function for different number init, use @splat for same num
pub inline fn vec2Init(x: f32, y: f32) Vec2 {
    return .{ x, y };
}

pub inline fn rvec2Init(xmin: f32, xmax: f32, ymin: f32, ymax: f32) Vec2 {
    return .{
        getRandomRange(f32, xmin, xmax),
        getRandomRange(f32, ymin, ymax),
    };
}

pub inline fn vec3Init(x: f32, y: f32, z: f32) Vec3 {
    return .{ x, y, z };
}

pub inline fn color3Init(x: u8, y: u8, z: u8) Color3 {
    return .{ x, y, z };
}

// maybe in future
// pub fn interolate
// pub fn dot product
