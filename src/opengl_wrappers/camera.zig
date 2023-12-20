const vec = @import("../math/vec.zig");
const mat = @import("../math/matrix.zig");
const std = @import("std");
const gl = @import("gl");
const program = @import("program.zig");

const CDR: f32 = std.math.pi / 180.0;

pub const camera = struct {
    const Self = @This();
    pitch: f32,
    yaw: f32,
    fov: f32,
    aspect: f32,
    znear: f32,
    zfar: f32,
    eye: vec.Vec3,
    look_at_point: vec.Vec3,
    up: vec.Vec3,
    projection_matrix: mat.Mat4x4,

    pub fn init(fov: f32, aspect: f32, znear: f32, zfar: f32, eye: vec.Vec3) Self {
        return Self{
            .pitch = 0,
            .yaw = 0,
            .fov = fov,
            .aspect = aspect,
            .znear = znear,
            .zfar = zfar,
            .eye = eye,
            .look_at_point = vec.Vec3.zeros(),
            .up = vec.init3(0, 1, 0),
            .projection_matrix = mat.Mat4x4.perspective(fov * CDR, aspect, znear, zfar),
        };
    }

    pub fn getViewMatrix(self: Self) mat.Mat4x4 {
        return mat.Mat4x4.lookAt(
            self.eye,
            self.look_at_point,
            self.up,
        );
    }
};
