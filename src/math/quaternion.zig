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
    pub fn fromAngles(pitch: f32, yaw: f32, roll: f32) Self {
        //https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
        // yes i stole the code from wikipedia you stole your primary school report from it too
        // roll (x), pitch (y), yaw (z), angles are in degrees
        const cr: f32 = @cos(roll * 0.5 * math.pi / 180.0);
        const sr: f32 = @sin(roll * 0.5 * math.pi / 180.0);
        const cp: f32 = @cos(pitch * 0.5 * math.pi / 180.0);
        const sp: f32 = @sin(pitch * 0.5 * math.pi / 180.0);
        const cy: f32 = @cos(yaw * 0.5 * math.pi / 180.0);
        const sy: f32 = @sin(yaw * 0.5 * math.pi / 180.0);

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
            self.getPitch(),
            self.getYaw(),
            self.getRoll(),
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
            .q3 = q.q3.scale(p.q0) + p.q3.scale(q.q0) + vec.cross(p.q3, q.q3),
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

    /// rotates the given vec
    pub fn rotate(self: Self, v: vec.Vec3) vec.Vec3 {
        // https://graphics.stanford.edu/courses/cs348a-17-winter/Papers/quaternion.pdf
        const magna = self.q3.mag(); // as much as i trust the complier i want to make sure this
        // isnt calculated more than once
        // look good math always leads to bad looking code
        return v.scale(self.q0 * self.q0 - magna * magna).add(self.q3.scale(v.dot(self.q3) * (2))).add(vec.cross(self.q3, v).scale(2 * self.q0));
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
        const R = self.toMatrix3x3();
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

test "sanity" {
    const qaud: Quaternion = Quaternion.fromAngles(180, 0, 0);
    const pitch: f32 = qaud.getPitch();
    std.debug.print("qaud : {}\n", .{qaud});
    std.debug.print("pitch : {}\n", .{pitch});
}
