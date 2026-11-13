const std = @import("std");
const math = std.math;

var global_prng: std.Random.DefaultPrng = undefined;

pub fn randomInit(io: std.Io) void {
    var seed_byte: [8]u8 = undefined;
    io.random(&seed_byte);
    const random_seed = std.mem.readInt(u64, &seed_byte, .native);
    global_prng = std.Random.DefaultPrng.init(random_seed);
}

pub fn getRandom(comptime T: type) T {
    return switch (@typeInfo(T)) {
        .comptime_float, .float => global_prng.random().float(T),
        .comptime_int, .int => global_prng.random().int(T),
        else => @compileError("not implement for " ++ @typeName(T)),
    };
}

pub fn getRandomInRange(comptime T: type, min: T, max: T) T {
    return getRandom(T) * (max - min) + min;
}

pub const Vec2 = @Vector(2, f32);
pub const Vec3 = @Vector(3, f64);
pub const Color3 = @Vector(3, u8);

// use this function for different number init, use @splat for same num
pub inline fn vec2Init(x: f32, y: f32) Vec2 {
    return .{ x, y };
}

pub inline fn rvec2Init(xmin: f32, xmax: f32, ymin: f32, ymax: f32) Vec2 {
    return .{
        getRandomInRange(f32, xmin, xmax),
        getRandomInRange(f32, ymin, ymax),
    };
}

pub inline fn vec3Init(x: f32, y: f32, z: f32) Vec3 {
    return .{ x, y, z };
}

pub inline fn color3Init(x: u8, y: u8, z: u8) Color3 {
    return .{ x, y, z };
}
