//! camera type

const vec = @import("../math/vec.zig");
const mat = @import("../math/matrix.zig");
const std = @import("std");
const gl = @import("gl");
const program = @import("program.zig");

const CDR: f32 = std.math.pi / 180.0;

const default_look_at = vec.Vec3.number(1);
/// the approximate up vector
const default_up = vec.init3(0, 1, 0);

/// an abstraction on a camera type
pub const Camera = struct {
    const Self = @This();
    pitch: f32,
    yaw: f32,
    fov: f32,
    aspect: f32,
    /// the near cliping field
    znear: f32,
    /// the far cliping field
    zfar: f32,
    /// the cameras position
    eye: vec.Vec3,
    /// where the camera is looking at
    look_at_point: vec.Vec3,
    /// the up right vector
    up: vec.Vec3,
    /// the projection matrix
    projection_matrix: mat.Mat4x4,
    /// the view matrix
    view_matrix: mat.Mat4x4,

    /// creates a new camera
    pub fn init(fov: f32, aspect: f32, znear: f32, zfar: f32, eye: vec.Vec3) Self {
        return Self{
            .pitch = 0,
            .yaw = 0,
            .fov = fov,
            .aspect = aspect,
            .znear = znear,
            .zfar = zfar,
            .eye = eye,
            .look_at_point = default_look_at,
            .up = default_up,
            .projection_matrix = mat.Mat4x4.perspective(
                fov * CDR,
                aspect,
                znear,
                zfar,
            ),
            .view_matrix = mat.Mat4x4.lookAt(
                eye,
                vec.Vec3.number(1),
                default_up,
            ),
        };
    }

    inline fn clip(min_val: f32, max_val: f32, val: f32) f32 {
        if (val <= min_val) return min_val;
        if (val >= max_val) return max_val;
        return val;
    }

    /// updates the camera as if it was an fps camera
    ///  the direction is the desired direction of travel of the eye relitve to the eye and look at point
    ///  so the x compoent of direction is how far you want to move forward/back
    ///  y : up/down
    ///  z : right/left
    pub fn updateFps(self: *Self, direction: vec.Vec3) void {
        self.pitch = clip(-89.99, 89.99, self.pitch);

        self.eye.vec[0] += direction.vec[0] * @sin(self.yaw * CDR) - direction.vec[2] * @cos(self.yaw * CDR);
        self.eye.vec[1] += direction.vec[1];
        self.eye.vec[2] += direction.vec[0] * @cos(self.yaw * CDR) + direction.vec[2] * @sin(self.yaw * CDR);

        self.look_at_point.vec[0] = self.eye.vec[0] + (@sin(self.yaw * CDR));
        self.look_at_point.vec[1] = self.eye.vec[1] + (@tan(self.pitch * CDR)) + direction.vec[1];
        self.look_at_point.vec[2] = self.eye.vec[2] + (@cos(self.yaw * CDR));

        self.view_matrix = mat.Mat4x4.lookAt(
            self.eye,
            self.look_at_point,
            self.up,
        );
    }

    // pub fn perspective_update(self : *Self) void {
    //     self.yaw =

    // }

};
