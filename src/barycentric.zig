const std = @import("std");

const Vec2 = @import("math.zig").Vec2;

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
