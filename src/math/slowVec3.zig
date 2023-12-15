const VecError = error{
    invalidVec,
};

pub fn Vec3(comptime T: type) type {
    return packed struct {
        const Self = @This();
        x: T,
        y: T,
        z: T,

        pub fn init(x: T, y: T, z: T) Self {
            return Self{ .x = x, .y = y, .z = z };
        }

        pub fn number(num: T) Self {
            return Self{ .x = num, .y = num, .z = num };
        }

        pub fn max(a: Self) T {
            if ((a.x >= a.z) and (a.x > a.y)) return a.x;
            if ((a.z >= a.x) and (a.z > a.y)) return a.z;
            if ((a.y >= a.z) and (a.y > a.x)) return a.y;
            return a.z;
        }

        pub fn min(a: Self) T {
            if ((a.x <= a.z) and (a.x <= a.y)) return a.x;
            if ((a.z <= a.x) and (a.z <= a.y)) return a.z;
            if ((a.y <= a.z) and (a.y <= a.x)) return a.y;
            return a.x;
        }

        pub fn dot(a: Self, b: Self) T {
            return a.x * b.x + a.y * b.y + a.z * b.z;
        }

        pub fn sum(a: Self) T {
            return a.x + a.y + a.z;
        }

        pub fn len(a: Self) T {
            return @sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
        }

        pub fn norm(a: Self) Self {
            const den: T = len(a);
            return a.scale(1 / den);
        }

        pub fn add(a: Self, b: Self) Self {
            return Self{
                .x = a.x + b.x,
                .y = a.y + b.y,
                .z = a.z + b.z,
            };
        }

        pub fn sub(a: Self, b: Self) Self {
            return Self{
                .x = a.x - b.x,
                .y = a.y - b.y,
                .z = a.z - b.z,
            };
        }

        pub fn mul(a: Self, b: Self) Self {
            return Self{
                .x = a.x * b.x,
                .y = a.y * b.y,
                .z = a.z * b.z,
            };
        }

        pub fn div(a: Self, b: Self) Self {
            return Self{
                .x = a.x / b.x,
                .y = a.y / b.y,
                .z = a.z / b.z,
            };
        }

        pub fn scale(a: Self, b: T) Self {
            return Self{
                .x = a.x * b,
                .y = a.y * b,
                .z = a.z * b,
            };
        }

        pub fn cross(a: Self, b: Self) Self {
            return Self{
                .x = a.y * b.z - a.z * b.y,
                .y = a.z * b.x - a.x * b.z,
                .z = a.x * b.y - a.y * b.x,
            };
        }

        pub fn eq(a: Self, b: Self) bool {
            return if (a.x == b.x and
                a.y == b.y and
                a.z == b.z) true else false;
        }

        // https://graphics.stanford.edu/courses/cs148-10-summer/docs/2006--degreve--reflection_refraction.pdf

        pub fn reflect(a: Self, b: Self) Self {
            const cosI = -a.dot(b);
            return b.add(a.scale(2 * cosI));
        }

        pub fn refract(a: Self, b: Self, n1: T, n2: T) VecError!Self {
            const n = n1 / n2;
            const cosI = -a.dot(b);
            const sinT2 = n * n * (1 - cosI * cosI);
            if (sinT2 > 1) return VecError.invalidVec;
            const cosT = @sqrt(1 - sinT2);
            return b.scale(n).add(a.scale(n * (cosI - cosT)));
        }

        // used for water or some shit, if its further away then its more refective or something like that
        pub fn reflectance(a: Self, b: Self, n1: T, n2: T) T {
            const n = n1 / n2;
            const cosI = -a.dot(b);
            const sinT2 = n * n * (1 - cosI * cosI);
            if (sinT2 > 1) return 1;
            const cosT = @sqrt(1 - sinT2);
            const r0rth = (n1 * cosI - n2 * cosT) / (n1 * cosI - n2 * cosT);
            const rPar = (n2 * cosI - n1 * cosT) / (n2 * cosI - n1 * cosT);
            return (r0rth * r0rth + rPar * rPar) / 2;
        }
    };
}
const std = @import("std");
const time = std.time;
const expect = std.testing.expect;
const Vec3f32 = Vec3(f32);
const times_run: u32 = 2000;

fn req(num1: f32, num2: f32, esp: f32) bool {
    return num2 - esp < num1 or num1 < num2 + esp;
}

test "init" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = Vec3f32.init(x, y, z);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const v3: Vec3f32 = Vec3f32.init(x, y, z);
    try expect(v3.x == x and v3.y == y and v3.z == z);
}

test "number" {
    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = Vec3f32.number(1);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const v3: Vec3f32 = Vec3f32.number(1);
    try expect(v3.x == 1 and v3.y == 1 and v3.z == 1);
}

test "max" {
    const x = 1;
    const y = 2;
    const z = 3;
    _ = z;
    const w = 4;

    const v3: Vec3f32 = Vec3f32.init(x, y, w);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.max();
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const max = v3.max();
    try expect(max == w);
}

test "min" {
    const x = 1;
    const y = 2;
    const z = 3;
    _ = z;
    const w = 4;
    const v3: Vec3f32 = Vec3f32.init(x, y, w);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.min();
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const min = v3.min();
    try expect(min == x);
}
test "dot" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);
    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.dot(v3);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const dot = v3.dot(v3);
    try expect(dot == 14);
}

test "sum" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.sum();
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const sum = v3.sum();

    try expect(sum == 6);
}

test "len" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;
    const v3: Vec3f32 = Vec3f32.init(x, y, z);
    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.len();
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const mag = v3.len();
    try expect(mag == comptime @sqrt(14.0));
}

test "norm" {
    const esp = 0.001;

    const v3: Vec3f32 = Vec3f32.init(3, 4, 1);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.norm();
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const norm = v3.norm();

    //vec 3
    try expect(req(norm.x, 3.0 / @sqrt(26.0), esp));
    try expect(req(norm.y, 4.0 / @sqrt(26.0), esp));
    try expect(req(norm.z, 1.0 / @sqrt(26.0), esp));
}

test "scale" {
    const x = 4;
    const y = 4;
    const z = 4;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.scale(0.25);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const scale = v3.scale(0.25);

    try expect(scale.x == 1 and scale.y == 1 and scale.z == 1);
}

test "eq" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.eq(v3);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const eq = v3.eq(v3);
    try expect(eq);
}

test "cross" {
    const a: Vec3f32 = Vec3f32.init(1, 0, 0);
    const b: Vec3f32 = Vec3f32.init(0, 1, 0);
    const c: Vec3f32 = Vec3f32.init(0, 0, 1);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = a.cross(b);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const cross = a.cross(b);

    try expect(cross.eq(c));
}

test "add3" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);

    // var timer = try time.Timer.start();
    // const r = v3.vec + v3.vec;
    // const v = Vec3f32.init(r[0], r[1], r[2]);
    // std.debug.print("took {}ns\n", .{timer.lap()});

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.add(v3);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const v = v3.add(v3);

    try expect(v.x == 2 and v.y == 4 and v.z == 6);
}

test "sub3" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.sub(v3);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const v = v3.sub(v3);

    try expect(v.x == 0 and v.y == 0 and v.z == 0);
}

test "mul3" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.mul(v3);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});
    const v = v3.mul(v3);

    try expect(v.x == 1 and v.y == 4 and v.z == 9);
}

test "div3" {
    const x = 1;
    const y = 2;
    const z = 3;
    const w = 4;
    _ = w;

    const v3: Vec3f32 = Vec3f32.init(x, y, z);

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = v3.div(v3);
    }
    std.debug.print("took {}ns\n", .{timer.lap()});

    const v = v3.div(v3);

    try expect(v.x == 1 and v.y == 1 and v.z == 1);
}
