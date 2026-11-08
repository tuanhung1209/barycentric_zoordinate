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
