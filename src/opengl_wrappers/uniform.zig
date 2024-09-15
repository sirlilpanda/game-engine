const gl = @import("gl");
const vec = @import("../math/vec.zig");
const mat = @import("../math/matrix.zig");
const std = @import("std");

// const uniform_logger = std.log.scoped(.Uniform);

/// a simple wrapper of a uniform
pub const Uniform = struct {
    const Self = @This();
    /// name of the uniform
    name: []const u8,

    /// opengl location of the uniform
    location: gl.GLint,

    /// creates a new uniform
    pub inline fn init(name: []const u8) Self {
        return Self{
            .name = name,
            .location = undefined,
        };
    }

    /// adds the given location
    pub fn addLocation(self: *Self, location: gl.GLint) void {
        self.location = location;
    }

    /// sends a Float to the gpu
    pub inline fn sendFloat(self: Self, v0: gl.GLfloat) void {
        gl.uniform1f(self.location, v0);
    }

    /// sends a Vec2 to the gpu
    pub inline fn sendVec2(self: Self, v: vec.Vec2) void {
        gl.uniform2f(self.location, v.vec[0], v.vec[1]);
    }

    /// sends a Vec3 to the gpu
    pub inline fn sendVec3(self: Self, v: vec.Vec3) void {
        gl.uniform3f(self.location, v.vec[0], v.vec[1], v.vec[2]);
    }

    /// sends a Vec4 to the gpu
    pub inline fn sendVec4(self: Self, v: vec.Vec4) void {
        gl.uniform4f(self.location, v.vec[0], v.vec[1], v.vec[2], v.vec[3]);
    }

    /// sends a Int to the gpu
    pub inline fn sendInt(self: Self, v0: gl.GLint) void {
        gl.uniform1i(self.location, v0);
    }

    /// sends a 2Int to the gpu
    pub inline fn send2Int(self: Self, v0: gl.GLint, v1: gl.GLint) void {
        gl.uniform2i(self.location, v0, v1);
    }

    /// sends a 3Int to the gpu
    pub inline fn send3Int(self: Self, v0: gl.GLint, v1: gl.GLint, v2: gl.GLint) void {
        gl.uniform3i(self.location, v0, v1, v2);
    }

    /// sends a 4Int to the gpu
    pub inline fn send4Int(self: Self, v0: gl.GLint, v1: gl.GLint, v2: gl.GLint, v3: gl.GLint) void {
        gl.uniform4i(self.location, v0, v1, v2, v3);
    }

    /// sends a 1Uint to the gpu
    pub inline fn send1Uint(self: Self, v0: gl.GLuint) void {
        gl.uniform1ui(self.location, v0);
    }

    /// sends a 2Uint to the gpu
    pub inline fn send2Uint(self: Self, v0: gl.GLuint, v1: gl.GLuint) void {
        gl.uniform2ui(self.location, v0, v1);
    }

    /// sends a 3Uint to the gpu
    pub inline fn send3Uint(self: Self, v0: gl.GLuint, v1: gl.GLuint, v2: gl.GLuint) void {
        gl.uniform3ui(self.location, v0, v1, v2);
    }

    /// sends a 4Uint to the gpu
    pub inline fn send4Uint(self: Self, v0: gl.GLuint, v1: gl.GLuint, v2: gl.GLuint, v3: gl.GLuint) void {
        gl.uniform4ui(self.location, v0, v1, v2, v3);
    }

    /// sends a FloatArray to the gpu
    pub inline fn sendFloatArray(self: Self, count: gl.GLsizei, value: []gl.GLfloat) void {
        gl.uniform1fv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a Vec2Array to the gpu
    pub inline fn sendVec2Array(self: Self, count: gl.GLsizei, value: []gl.GLfloat) void {
        gl.uniform2fv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a Vec3Array to the gpu
    pub inline fn sendVec3Array(self: Self, count: gl.GLsizei, value: []gl.GLfloat) void {
        gl.uniform3fv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a Vec4Array to the gpu
    pub inline fn sendVec4Array(self: Self, count: gl.GLsizei, value: []vec.Vec4) void {
        gl.uniform4fv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 1IntArray to the gpu
    pub inline fn send1IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform1iv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 2IntArray to the gpu
    pub inline fn send2IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform2iv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 3IntArray to the gpu
    pub inline fn send3IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform3iv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 4IntArray to the gpu
    pub inline fn send4IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform4iv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 1UIntArray to the gpu
    pub inline fn send1UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform1uiv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 2UIntArray to the gpu
    pub inline fn send2UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform2uiv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 3UIntArray to the gpu
    pub inline fn send3UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform3uiv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a 4UIntArray to the gpu
    pub inline fn send4UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform4uiv(self.location, count, @ptrCast(&value[0]));
    }

    /// sends a Matrix2 to the gpu
    pub inline fn sendMatrix2(self: Self, transpose: bool, m: mat.Matrix(2, 2)) void {
        gl.uniformMatrix2fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix3 to the gpu
    pub inline fn sendMatrix3(self: Self, transpose: bool, m: mat.Mat3x3) void {
        gl.uniformMatrix3fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix4 to the gpu
    pub inline fn sendMatrix4(self: Self, transpose: bool, m: mat.Mat4x4) void {
        gl.uniformMatrix4fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix2x3 to the gpu
    pub inline fn sendMatrix2x3(self: Self, transpose: bool, m: mat.Matrix(2, 3)) void {
        gl.uniformMatrix2x3fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix3x2 to the gpu
    pub inline fn sendMatrix3x2(self: Self, transpose: bool, m: mat.Matrix(3, 2)) void {
        gl.uniformMatrix3x2fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix2x4 to the gpu
    pub inline fn sendMatrix2x4(self: Self, transpose: bool, m: mat.Matrix(2, 4)) void {
        gl.uniformMatrix2x4fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix4x2 to the gpu
    pub inline fn sendMatrix4x2(self: Self, transpose: bool, m: mat.Matrix(4, 2)) void {
        gl.uniformMatrix4x2fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix3x4 to the gpu
    pub inline fn sendMatrix3x4(self: Self, transpose: bool, m: mat.Matrix(3, 4)) void {
        gl.uniformMatrix3x4fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix4x3 to the gpu
    pub inline fn sendMatrix4x3(self: Self, transpose: bool, m: mat.Matrix(4, 3)) void {
        gl.uniformMatrix4x3fv(
            self.location,
            1,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }
    /// sends a Matrix2Array to the gpu
    pub inline fn sendMatrix2Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Matrix(2, 2)) void {
        gl.uniformMatrix2fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix3Array to the gpu
    pub inline fn sendMatrix3Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Mat3x3) void {
        gl.uniformMatrix3fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix4Array to the gpu
    pub inline fn sendMatrix4Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Mat4x4) void {
        gl.uniformMatrix4fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix2x3Array to the gpu
    pub inline fn sendMatrix2x3Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Matrix(2, 3)) void {
        gl.uniformMatrix2x3fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix3x2Array to the gpu
    pub inline fn sendMatrix3x2Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Matrix(3, 2)) void {
        gl.uniformMatrix3x2fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix2x4Array to the gpu
    pub inline fn sendMatrix2x4Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Matrix(2, 4)) void {
        gl.uniformMatrix2x4fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix4x2Array to the gpu
    pub inline fn sendMatrix4x2Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Matrix(4, 2)) void {
        gl.uniformMatrix4x2fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix3x4Array to the gpu
    pub inline fn sendMatrix3x4Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Matrix(3, 4)) void {
        gl.uniformMatrix3x4fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }

    /// sends a Matrix4x3Array to the gpu
    pub inline fn sendMatrix4x3Array(self: Self, count: gl.GLsizei, transpose: bool, m: mat.Matrix(4, 3)) void {
        gl.uniformMatrix4x3fv(
            self.location,
            count,
            if (transpose) gl.TRUE else gl.FALSE,
            @ptrCast(&m.vec[0]),
        );
    }
};
