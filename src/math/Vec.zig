pub const VecError = error{
    VecLengthNot3,
};

pub const Vec2 = Vec(2);
pub const Vec3 = Vec(3);
pub const Vec4 = Vec(4);

//tested
pub fn init2(x: f32, y: f32) Vec2 {
    return Vec2{ .vec = @Vector(2, f32){ x, y } };
}

//tested
pub fn init3(x: f32, y: f32, z: f32) Vec3 {
    return Vec3{ .vec = @Vector(3, f32){ x, y, z } };
}

//tested
pub fn init4(x: f32, y: f32, z: f32, w: f32) Vec4 {
    return Vec4{ .vec = @Vector(4, f32){ x, y, z, w } };
}

pub fn cross(a: Vec3, b: Vec3) Vec3 {
    const V3 = @Vector(3, f32);

    const mask1 = @Vector(3, i32){ 1, 2, 0 };
    const mask2 = @Vector(3, i32){ 2, 0, 1 };

    const temp1: V3 = @shuffle(f32, a.vec, undefined, mask1);
    const temp2: V3 = @shuffle(f32, b.vec, undefined, mask2);
    const temp12: V3 = temp1 * temp2;
    const temp3: V3 = @shuffle(f32, a.vec, undefined, mask2);
    const temp4: V3 = @shuffle(f32, b.vec, undefined, mask1);
    const temp34: V3 = temp3 * temp4;
    return Vec3{ .vec = temp12 - temp34 };

    // return Self{
    //     .x = a.y * b.z - a.z * b.y,
    //     .y = a.z * b.x - a.x * b.z,
    //     .z = a.x * b.y - a.y * b.x,
    // };
}

pub fn Vec(comptime length: comptime_int) type {
    return struct {
        const Self = @This();
        vec: @Vector(length, f32),

        //tested
        pub fn zeros() Self {
            return comptime number(0);
        }

        //tested
        pub fn ones() Self {
            return comptime number(1);
        }

        //tested
        pub fn number(scalar: f32) Self {
            return Self{ .vec = @splat(scalar) };
        }

        //tested
        pub fn max(a: Self) f32 {
            return @reduce(.Max, a.vec);
        }

        //tested
        pub fn min(a: Self) f32 {
            return @reduce(.Min, a.vec);
        }

        //tested
        pub fn dot(a: Self, b: Self) f32 {
            return @reduce(.Add, a.vec * b.vec);
        }

        //tested
        pub fn sum(a: Self) f32 {
            return @reduce(.Add, a.vec);
        }

        //tested
        pub fn mag(a: Self) f32 {
            return @sqrt(@reduce(.Add, a.vec * a.vec));
        }

        //tested
        pub fn norm(a: Self) Self {
            return Self{ .vec = a.vec / number(a.mag()).vec };
            // const den: f32 = len(a);
            // return a.scale(1 / den);
        }

        //tested
        pub fn scale(a: Self, b: f32) Self {
            return Self{ .vec = a.vec * number(b).vec };
        }

        //tested
        pub fn eq(a: Self, b: Self) bool {
            return if (@reduce(.Add, a.vec - b.vec) == 0) return true else false;
        }

        pub fn debug_print_vector(vec: Self) void {
            std.debug.print("vec[", .{});
            var i: usize = 0;
            while (i < length) : (i += 1) {
                std.debug.print("{},", .{vec.vec[i]});
            }
            std.debug.print("]", .{});
        }

        // https://graphics.stanford.edu/courses/cs148-10-summer/docs/2006--degreve--reflection_refraction.pdf

        // pub fn reflect(a: Self, b: Self) Self {
        //     const cosI = -a.dot(b);
        //     return b.add(a.scale(2 * cosI));
        // }

        // pub fn refract(a: Self, b: Self, n1: T, n2: T) VecError!Self {
        //     const n = n1 / n2;
        //     const cosI = -a.dot(b);
        //     const sinT2 = n * n * (1 - cosI * cosI);
        //     if (sinT2 > 1) return VecError.invalidVec;
        //     const cosT = @sqrt(1 - sinT2);
        //     return b.scale(n).add(a.scale(n * (cosI - cosT)));
        // }

        // // used for water or some shit, if its further away then its more refective or something like that
        // pub fn reflectance(a: Self, b: Self, n1: T, n2: T) f32 {
        //     const n = n1 / n2;
        //     const cosI = -a.dot(b);
        //     const sinT2 = n * n * (1 - cosI * cosI);
        //     if (sinT2 > 1) return 1;
        //     const cosT = @sqrt(1 - sinT2);
        //     const r0rth = (n1 * cosI - n2 * cosT) / (n1 * cosI - n2 * cosT);
        //     const rPar = (n2 * cosI - n1 * cosT) / (n2 * cosI - n1 * cosT);
        //     return (r0rth * r0rth + rPar * rPar) / 2;
        // }
    };
}

const std = @import("std");
const expect = std.testing.expect;

fn req(num1: f32, num2: f32, esp: f32) bool {
    return num2 - esp < num1 or num1 < num2 + esp;
}

test "init" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;

    const v2: Vec2 = init2(x, y);
    const v3: Vec3 = init3(x, y, z);
    const v4: Vec4 = init4(x, y, z, w);

    try expect(v2.vec[0] == x and v2.vec[1] == y);
    try expect(v3.vec[0] == x and v3.vec[1] == y and v3.vec[2] == z);
    try expect(v4.vec[0] == x and v4.vec[1] == y and v4.vec[2] == z and v4.vec[3] == w);
}

test "number" {
    const v2: Vec2 = Vec2.number(1);
    const v3: Vec3 = Vec3.number(1);
    const v4: Vec4 = Vec4.number(1);

    try expect(v2.vec[0] == 1 and v2.vec[1] == 1);
    try expect(v3.vec[0] == 1 and v3.vec[1] == 1 and v3.vec[2] == 1);
    try expect(v4.vec[0] == 1 and v4.vec[1] == 1 and v4.vec[2] == 1 and v4.vec[3] == 1);
}

test "max" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;

    const v2: Vec2 = init2(x, w);
    const v3: Vec3 = init3(x, y, w);
    const v4: Vec4 = init4(x, y, z, w);

    try expect(Vec2.max(v2) == w);
    try expect(Vec3.max(v3) == w);
    try expect(Vec4.max(v4) == w);
}

test "min" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;

    const v2: Vec2 = init2(x, w);
    const v3: Vec3 = init3(x, y, w);
    const v4: Vec4 = init4(x, y, z, w);

    try expect(Vec2.min(v2) == x);
    try expect(Vec3.min(v3) == x);
    try expect(Vec4.min(v4) == x);
}

test "dot" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;

    const v2: Vec2 = init2(x, y);
    const v3: Vec3 = init3(x, y, z);
    const v4: Vec4 = init4(x, y, z, w);
    // std.debug.print("\n", .{});

    // v2.debug_print_vector();
    // std.debug.print(" . = {}\n", .{v2.dot(v2)});

    // v3.debug_print_vector();
    // std.debug.print(" . = {}\n", .{v3.dot(v3)});

    // v4.debug_print_vector();
    // std.debug.print(" . = {}\n", .{v4.dot(v4)});

    try expect(v2.dot(v2) == 5);
    try expect(v3.dot(v3) == 14);
    try expect(v4.dot(v4) == 30);
}

test "sum" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;

    const v2: Vec2 = init2(x, y);
    const v3: Vec3 = init3(x, y, z);
    const v4: Vec4 = init4(x, y, z, w);

    try expect(v2.sum() == 3);
    try expect(v3.sum() == 6);
    try expect(v4.sum() == 10);
}

test "len" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;

    const v2: Vec2 = init2(x, y);
    const v3: Vec3 = init3(x, y, z);
    const v4: Vec4 = init4(x, y, z, w);

    try expect(v2.mag() == comptime @sqrt(5.0));
    try expect(v3.mag() == comptime @sqrt(14.0));
    try expect(v4.mag() == comptime @sqrt(30.0));
}

test "norm" {
    const esp = 0.001;

    const v2: Vec2 = init2(3, 4);
    const v3: Vec3 = init3(3, 4, 1);
    const v4: Vec4 = init4(4, 4, 4, 4);

    //vec 2
    try expect(req(v2.vec[0], 3.0 / 5.0, esp));
    try expect(req(v2.vec[1], 4.0 / 5.0, esp));

    //vec 3
    try expect(req(v3.vec[0], 3.0 / @sqrt(26.0), esp));
    try expect(req(v3.vec[1], 4.0 / @sqrt(26.0), esp));
    try expect(req(v3.vec[2], 1.0 / @sqrt(26.0), esp));

    //vec 4
    try expect(req(v4.vec[0], 1 / 2, esp));
    try expect(req(v4.vec[1], 1 / 2, esp));
    try expect(req(v4.vec[2], 1 / 2, esp));
    try expect(req(v4.vec[3], 1 / 2, esp));
}

test "scale" {
    const x = 4;
    const y = 4;
    const z = 4;
    const w = 4;

    const v2: Vec2 = init2(x, y).scale(0.25);
    const v3: Vec3 = init3(x, y, z).scale(0.25);
    const v4: Vec4 = init4(x, y, z, w).scale(0.25);

    try expect(v2.vec[0] == 1 and v2.vec[1] == 1);
    try expect(v3.vec[0] == 1 and v3.vec[1] == 1 and v3.vec[2] == 1);
    try expect(v4.vec[0] == 1 and v4.vec[1] == 1 and v4.vec[2] == 1 and v4.vec[3] == 1);
}

test "eq" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;

    const v2: Vec2 = init2(x, y);
    const v3: Vec3 = init3(x, y, z);
    const v4: Vec4 = init4(x, y, z, w);

    try expect(v2.eq(v2));
    try expect(v3.eq(v3));
    try expect(v4.eq(v4));
}

test "cross" {
    const a: Vec3 = init3(1, 0, 0);
    const b: Vec3 = init3(0, 1, 0);
    const c: Vec3 = init3(0, 0, 1);

    try expect(cross(a, b).eq(c));
}
