//! these are untested and is my next step
const vec = @import("vec.zig");
const mat = @import("matrix.zig");
const math = @import("std").math;
const ColourPrinter = @import("../utils/string.zig").String;
const Colour = @import("../utils/colour.zig").Colour;

/// Quaternion type
pub const Quaternion = struct {
    const Self = @This();
    q0: f32,
    q3: vec.Vec3,

    /// create a new Quaternion with give q0 and q3
    pub fn init(q0: f32, q3: vec.Vec3) Self {
        return Self{
            .q0 = q0,
            .q3 = q3,
        };
    }

    /// creates a new Quaternion from the given eular angles
    /// roll (x), pitch (y), yaw (z), angles are in rads
    pub fn fromAngles(roll: f32, pitch: f32, yaw: f32) Self {
        //https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
        // yes i stole the code from wikipedia you stole your primary school report from it too
        // roll (x), pitch (y), yaw (z), angles are in degrees
        const cr: f32 = @cos(roll * 0.5);
        const sr: f32 = @sin(roll * 0.5);

        const cp: f32 = @cos(pitch * 0.5);
        const sp: f32 = @sin(pitch * 0.5);

        const cy: f32 = @cos(yaw * 0.5);
        const sy: f32 = @sin(yaw * 0.5);

        return Self{
            .q0 = cr * cp * cy + sr * sp * sy,
            .q3 = vec.init3(
                sr * cp * cy - cr * sp * sy,
                cr * sp * cy + sr * cp * sy,
                cr * cp * sy - sr * sp * cy,
            ),
        };
    }

    /// creates a new Quaternion from the given eular angles in a vec3
    pub fn fromEular(angles: vec.Vec3) Self {
        return Self.fromAngles(angles.x(), angles.y(), angles.z());
    }

    /// converts the Quaternion to eular angles
    pub fn toEular(self: Self) vec.Vec3 {
        return vec.init3(
            self.getRoll(),
            self.getPitch(),
            self.getYaw(),
        );
    }

    /// get the pitch of the Quaternion
    pub fn getPitch(self: Self) f32 {
        // pitch (y-axis rotation)
        const sinp: f32 = @sqrt(1.0 + 2.0 * (self.q0 * self.q3.y() - self.q3.x() * self.q3.z()));
        const cosp: f32 = @sqrt(1.0 - 2.0 * (self.q0 * self.q3.y() - self.q3.x() * self.q3.z()));
        return 2.0 * math.atan2(sinp, cosp) - math.pi / 2.0;
    }

    /// get the yaw of the Quaternion
    pub fn getYaw(self: Self) f32 {
        // yaw (z-axis rotation)
        const siny_cosp: f32 = 2.0 * (self.q0 * self.q3.z() + self.q3.x() * self.q3.y());
        const cosy_cosp: f32 = 1.0 - 2.0 * (self.q3.y() * self.q3.y() + self.q3.z() * self.q3.z());
        return math.atan2(siny_cosp, cosy_cosp);
    }

    /// get the roll of the Quaternion
    pub fn getRoll(self: Self) f32 {
        // roll (x-axis rotation)
        const sinr_cosp: f32 = 2.0 * (self.q0 * self.q3.x() + self.q3.y() * self.q3.z());
        const cosr_cosp: f32 = 1.0 - 2.0 * (self.q3.x() * self.q3.x() + self.q3.y() * self.q3.y());
        return math.atan2(sinr_cosp, cosr_cosp);
    }

    /// multiplies 2 Quaternion together
    pub fn mul(p: Self, q: Self) Self {
        return Self{
            .q0 = p.q0 * q.q0 - p.q3.dot(q.q3),
            .q3 = q.q3.scale(p.q0).add(p.q3.scale(q.q0)).add(vec.cross(p.q3, q.q3)),
        };
    }

    /// adds 2 Quaternion together
    pub fn add(self: Self, other: Self) Self {
        return Self{
            .q0 = self.q0 + other.q0,
            .q3 = self.q3.add(other.q3),
        };
    }

    /// sub 2 Quaternion together
    pub fn sub(self: Self, other: Self) Self {
        return Self{
            .q0 = self.q0 - other.q0,
            .q3 = self.q3.sub(other.q3),
        };
    }

    /// divs 2 Quaternion together
    pub fn div(self: Self, other: Self) Self {
        _ = self;
        _ = other;
        @compileError("div not yet implemented the math looked scary");
    }

    /// scales the Quaternion by a given value
    pub fn scale(self: Self, a: f32) Self {
        return Self{
            .q0 = self.q0 * a,
            .q3 = self.q3.scale(a),
        };
    }

    /// computes the conjugate of the Quaternion
    pub fn conj(self: Self) Self {
        return Self{
            .q0 = self.q0,
            .q3 = self.q3.scale(-1),
        };
    }

    /// computes the normalized Quaternion
    pub fn norm(self: Self) Self {
        // https://lucidar.me/en/quaternions/quaternion-normalization/
        return self.scale(self.mag());
    }

    /// computes the magintue of the Quaternion
    pub fn mag(self: Self) f32 {
        return @sqrt(self.q0 * self.q0 + self.q3.dot(self.q3));
    }

    /// computes the inverse of the Quaternion
    pub fn inv(self: Self) Self {
        return self.conj().scale(self.mag());
    }

    /// this does not normalise to check, one checks the actual value
    pub fn eq(self: Self, other: Self) bool {
        return @reduce(.And, self.q3.vec == other.q3.vec) and self.q0 == other.q0;
    }

    /// this does not normalise to check, one checks the actual value
    pub fn req(self: Self, other: Self, epsilon: f32) bool {
        return @reduce(.And, @abs(self.q3.vec - other.q3.vec) <= vec.Vec3.number(epsilon).vec) and @abs(self.q0 - other.q0) <= epsilon;
    }

    /// rotates the given vec
    pub fn rotate(self: Self, v: vec.Vec3) vec.Vec3 {
        // https://graphics.stanford.edu/courses/cs348a-17-winter/Papers/quaternion.pdf
        const magna = self.q3.mag(); // as much as i trust the complier i want to make sure this
        // isnt calculated more than once
        // look good math always leads to bad looking code
        return v.scale(self.q0 * self.q0 - magna * magna)
            .add(self.q3.scale(v.dot(self.q3) * (2)))
            .add(vec.cross(self.q3, v)
            .scale(2 * self.q0));
    }

    /// converts to a 3x3 matrix
    pub fn toMatrix3x3(q: Self) mat.Mat3x3 {
        const q0 = q.q0;
        const q1 = q.q3.x();
        const q2 = q.q3.y();
        const q3 = q.q3.z();
        const q0_2 = q0 * q0;
        const q1_2 = q1 * q1;
        const q2_2 = q2 * q2;
        const q3_2 = q3 * q3;

        return mat.Mat3x3{ //will be slightly faster and just a bit more readable
            .vec = @Vector(9, f32){
                q0_2 + q1_2 - q2_2 - q3_2, 2.0 * (q1 * q2 - q0 * q3), 2.0 * (q1 * q3 - q0 * q2),
                2.0 * (q1 * q2 - q0 * q3), q0_2 - q1_2 + q2_2 - q3_2, 2.0 * (q2 * q3 - q0 * q1),
                2.0 * (q1 * q3 - q0 * q2), 2.0 * (q2 * q3 - q0 * q1), q0_2 - q1_2 - q2_2 + q3_2,
            },
        };
    }

    /// converts to a 4x4 matrix
    pub fn toMatrix4x4(self: Self) mat.Mat4x4 {
        const R = self.toMatrix3x3().vec;
        return mat.Mat4x4{ //will be slightly faster and just a bit more readable
            .vec = @Vector(16, f32){
                R[0], R[1], R[2], 0,
                R[3], R[4], R[5], 0,
                R[6], R[7], R[8], 0,
                0,    0,    0,    1,
            },
        };
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        var colour_text = ColourPrinter.initNoString();
        colour_text.setFgColour(Colour.red());
        try writer.print("Quat[{start}{}{end}, ", .{ colour_text, self.q0, colour_text });

        colour_text.setFgColour(Colour.yellow());
        try writer.print("{start}{}{end}, ", .{ colour_text, self.q3.x(), colour_text });

        colour_text.setFgColour(Colour.green());
        try writer.print("{start}{}{end}, ", .{ colour_text, self.q3.y(), colour_text });

        colour_text.setFgColour(Colour.lightBlue());
        try writer.print("{start}{}{end}]", .{ colour_text, self.q3.z(), colour_text });
    }
};

// i need to write tests
const std = @import("std");
const pi = std.math.pi;
const expect = std.testing.expect;

test "init" {
    _ = Quaternion.init(1, vec.init3(2, 3, 4));
}

test "eq" {
    const qaut1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const qaut2 = Quaternion.init(1, vec.init3(2, 3, 4));

    try expect(qaut1.eq(qaut2));
}

test "!eq q0" {
    const qaut1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const qaut2 = Quaternion.init(4, vec.init3(2, 3, 4));

    try expect(!qaut1.eq(qaut2));
}

test "!eq q3" {
    const qaut1 = Quaternion.init(1, vec.init3(2, 2, 4));
    const qaut2 = Quaternion.init(1, vec.init3(2, 4, 4));

    try expect(!qaut1.eq(qaut2));
}

test "req is eq" {
    const qaut1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const qaut2 = Quaternion.init(1, vec.init3(2, 3, 4));

    try expect(qaut1.req(qaut2, 0));
}

test "req" {
    const qaut1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const qaut2 = Quaternion.init(1, vec.init3(2.1, 3.1, 4.1));

    try expect(qaut1.req(qaut2, 0.1));
}

test "!req q0" {
    const qaut1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const qaut2 = Quaternion.init(2, vec.init3(2.1, 3.1, 4.1));

    try expect(!qaut1.req(qaut2, 0.1));
}

test "!req q3" {
    const qaut1 = Quaternion.init(1, vec.init3(2, 2, 4));
    const qaut2 = Quaternion.init(1, vec.init3(2.1, 3.1, 4.1));

    try expect(!qaut1.req(qaut2, 0.1));
}

test "fromAnglesX" {
    const angle: f32 = pi / 2.0;
    const qaud_res = Quaternion.init(0.7071067811865476, vec.init3(0.7071067811865475, 0.0, 0.0));
    const res = Quaternion.fromAngles(angle, 0, 0);
    // std.debug.print("res {}\n", .{res});
    // std.debug.print("qaud_res {}\n", .{qaud_res});
    try expect(res.req(qaud_res, 0.001));
}

test "fromAnglesY" {
    const angle: f32 = pi / 2.0;
    const qaud_res = Quaternion.init(0.7071067811865476, vec.init3(-0.0, 0.7071067811865475, 0.0));
    const res = Quaternion.fromAngles(0, angle, 0);
    // std.debug.print("res {}\n", .{res});
    // std.debug.print("qaud_res {}\n", .{qaud_res});
    try expect(res.req(qaud_res, 0.001));
}

test "fromAnglesZ" {
    const angle: f32 = pi / 2.0;
    const qaud_res = Quaternion.init(0.7071067811865476, vec.init3(0.0, 0.0, 0.7071067811865475));
    const res = Quaternion.fromAngles(0, 0, angle);
    // std.debug.print("res {}\n", .{res});
    // std.debug.print("qaud_res {}\n", .{qaud_res});
    try expect(res.req(qaud_res, 0.001));
}

test "fromAngles" {
    const angles = vec.init3(pi / 3.0, pi / 4.0, pi / 2.0);
    const qaud_res = Quaternion.init(0.7010573846499779, vec.init3(0.0922959556412572, 0.5609855267969309, 0.4304593345768795));
    const res = Quaternion.fromAngles(angles.x(), angles.y(), angles.z());
    // std.debug.print("res {}\n", .{res});
    // std.debug.print("qaud_res {}\n", .{qaud_res});

    try expect(res.req(qaud_res, 0.001));
}

test "fromEular" {
    const angles = vec.init3(pi / 3.0, pi / 4.0, pi / 2.0);
    const qaud_res = Quaternion.init(0.7010573846499779, vec.init3(0.0922959556412572, 0.5609855267969309, 0.4304593345768795));

    const res = Quaternion.fromEular(angles);
    try expect(res.req(qaud_res, 0.001));
}

test "getPitch" {
    const angles = vec.init3(0, pi / 2.0, 0);
    const q = Quaternion.fromEular(angles);
    const res = q.getPitch();

    // std.debug.print("q : {}\n", .{q});
    // std.debug.print("angle : {}\n", .{angles});
    // std.debug.print("res : {}\n", .{res});

    try expect(@abs(res - angles.y()) <= 0.001);
}

test "getYaw" {
    const angles = vec.init3(0, 0, pi / 2.0);
    const q = Quaternion.fromEular(angles);
    const res = q.getYaw();

    // std.debug.print("q : {}\n", .{q});
    // std.debug.print("angle : {}\n", .{angles});
    // std.debug.print("res : {}\n", .{res});

    try expect(@abs(res - angles.z()) <= 0.001);
}

test "getRoll" {
    const angles = vec.init3(pi / 2.0, 0, 0);
    const q = Quaternion.fromEular(angles);
    const res = q.getRoll();

    // std.debug.print("q : {}\n", .{q});
    // std.debug.print("angle : {}\n", .{angles});
    // std.debug.print("res : {}\n", .{res});

    try expect(@abs(res - angles.x()) <= 0.001);
}

test "toEular" {
    const angles = vec.init3(pi / 3.0, pi / 4.0, pi / 2.0);
    const q = Quaternion.fromEular(angles);
    const res = Quaternion.toEular(q);

    try expect(res.req(angles, 0.001));
}

test "mul" {
    const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q2 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q3 = Quaternion.init(-28, vec.init3(4, 6, 8));

    const res = q1.mul(q2);

    try expect(res.eq(q3));
}

test "add" {
    const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q2 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q3 = Quaternion.init(2, vec.init3(4, 6, 8));

    const res = q1.add(q2);

    try expect(res.eq(q3));
}

test "sub" {
    const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q2 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q3 = Quaternion.init(0, vec.init3(0, 0, 0));

    const res = q1.sub(q2);

    try expect(res.eq(q3));
}

test "scale" {
    const scale: f32 = 2;
    const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q2 = Quaternion.init(1 * scale, vec.init3(2, 3, 4).scale(scale));

    const res = q1.scale(2);

    try expect(res.eq(q2));
}

test "conj" {
    // 1 - 2i - 3j - 4k
    const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q1_conj = Quaternion.init(1, vec.init3(-2, -3, -4));

    const res = q1.conj();

    try expect(res.eq(q1_conj));
}

test "norm" {
    const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const q1_conj = Quaternion.init(1, vec.init3(-2, -3, -4));

    const res = q1.conj();

    try expect(res.eq(q1_conj));
}

test "mag" {
    const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    const v4 = vec.init4(1, 2, 3, 4);

    const res = q1.mag();

    try expect(v4.mag() == res);
}

test "inv" {
    const q1 = Quaternion.init(0.5, vec.init3(0.5, 0.5, 0.5));
    const q1_inv = Quaternion.init(0.5, vec.init3(-0.5, -0.5, -0.5));

    const res = q1.inv();

    try expect(res.eq(q1_inv));
}

test "rotate" {
    // const q1 = Quaternion.init(1, vec.init3(2, 3, 4));
    // const q2 = Quaternion.init(1, vec.init3(2, 3, 4));
    // const q3 = Quaternion.init(0, vec.init3(0, 0, 0));

    // const res = q1.rotate(q2);

    // try expect(res.eq(q3));
}

test "toMatrix3x3" {
    // const q1 = Quaternion.init(1, vec.init3(2, 2, 1)).norm();
    // const matrix = mat.Mat3x3.makeFromArray(
    //     [9]f32{
    //         -0.6000000, 0.0000000, 0.8000000,
    //         0.8000000,  0.0000000, 0.6000000,
    //         0.0000000,  1.0000000, 0.0000000,
    //     },
    // );

    // //  -6e0, 0e0, 0e0,
    // //  0e0, 0e0, 6e0,
    // //  0e0, 6e0, 0e0

    // const res = q1.toMatrix3x3();
    // std.debug.print("res {}\n", .{res});

    // try expect(res.eq(matrix));
}

test "toMatrix4x4" {
    // const point = vec.init4(1, 1, 1, 1);
    // const q1 = Quaternion.fromAngles(pi / 2.0, 0, 0);
    // const matrix = mat.Mat4x4.rotate_x(45);

    // const res_q = q1.toMatrix4x4().MulVec(point).norm();
    // const res_m = matrix.MulVec(point).norm();

    // std.debug.print("res_q : {}\n", .{res_q});
    // std.debug.print("res_m : {}\n", .{res_m});

    // try expect(res_q.eq(res_m));
}
