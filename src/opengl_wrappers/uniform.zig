const gl = @import("gl");
const vec = @import("../math/vec.zig");
const mat = @import("../math/matrix.zig");

pub const Uniform = struct {
    const Self = @This();
    name: []const u8,
    location: gl.GLint,

    pub inline fn init(name: []const u8) Self {
        return Self{
            .name = name,
            .location = undefined,
        };
    }

    pub inline fn sendFloat(self: Self, v0: gl.GLfloat) void {
        gl.uniform1f(self.location, v0);
    }

    pub inline fn sendVec2(self: Self, v: vec.Vec2) void {
        gl.uniform2f(self.location, v.vec[0], v.vec[1]);
    }

    pub inline fn sendVec3(self: Self, v: vec.Vec3) void {
        gl.uniform3f(self.location, v.vec[0], v.vec[1], v.vec[2]);
    }

    pub inline fn sendVec4(self: Self, v: vec.Vec4) void {
        gl.uniform4f(self.location, v.vec[0], v.vec[1], v.vec[2], v.vec[3]);
    }

    pub inline fn sendInt(self: Self, v0: gl.GLint) void {
        gl.uniform1i(self.location, v0);
    }

    pub inline fn send2Int(self: Self, v0: gl.GLint, v1: gl.GLint) void {
        gl.uniform2i(self.location, v0, v1);
    }

    pub inline fn send3Int(self: Self, v0: gl.GLint, v1: gl.GLint, v2: gl.GLint) void {
        gl.uniform3i(self.location, v0, v1, v2);
    }

    pub inline fn send4Int(self: Self, v0: gl.GLint, v1: gl.GLint, v2: gl.GLint, v3: gl.GLint) void {
        gl.uniform4i(self.location, v0, v1, v2, v3);
    }

    pub inline fn send1Uint(self: Self, v0: gl.GLuint) void {
        gl.uniform1ui(self.location, v0);
    }

    pub inline fn send2Uint(self: Self, v0: gl.GLuint, v1: gl.GLuint) void {
        gl.uniform2ui(self.location, v0, v1);
    }

    pub inline fn send3Uint(self: Self, v0: gl.GLuint, v1: gl.GLuint, v2: gl.GLuint) void {
        gl.uniform3ui(self.location, v0, v1, v2);
    }

    pub inline fn send4Uint(self: Self, v0: gl.GLuint, v1: gl.GLuint, v2: gl.GLuint, v3: gl.GLuint) void {
        gl.uniform4ui(self.location, v0, v1, v2, v3);
    }

    pub inline fn sendFloatArray(self: Self, count: gl.GLsizei, value: []gl.GLfloat) void {
        gl.uniform1fv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn sendVec2Array(self: Self, count: gl.GLsizei, value: []gl.GLfloat) void {
        gl.uniform2fv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn sendVec3Array(self: Self, count: gl.GLsizei, value: []gl.GLfloat) void {
        gl.uniform3fv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn sendVec4Array(self: Self, count: gl.GLsizei, value: []vec.Vec4) void {
        gl.uniform4fv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send1IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform1iv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send2IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform2iv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send3IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform3iv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send4IntArray(self: Self, count: gl.GLsizei, value: []gl.GLint) void {
        gl.uniform4iv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send1UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform1uiv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send2UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform2uiv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send3UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform3uiv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn send4UIntArray(self: Self, count: gl.GLsizei, value: []gl.GLuint) void {
        gl.uniform4uiv(self.location, count, @ptrCast(&value[0]));
    }

    pub inline fn sendMatrix2(self: Self, transpose: gl.GLboolean, m: mat.Matrix(2, 2)) void {
        gl.uniformMatrix2fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix3(self: Self, transpose: gl.GLboolean, m: mat.Mat3x3) void {
        gl.uniformMatrix3fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix4(self: Self, transpose: gl.GLboolean, m: mat.Mat4x4) void {
        gl.uniformMatrix4fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix2x3(self: Self, transpose: gl.GLboolean, m: mat.Matrix(2, 3)) void {
        gl.uniformMatrix2x3fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix3x2(self: Self, transpose: gl.GLboolean, m: mat.Matrix(3, 2)) void {
        gl.uniformMatrix3x2fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix2x4(self: Self, transpose: gl.GLboolean, m: mat.Matrix(2, 4)) void {
        gl.uniformMatrix2x4fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix4x2(self: Self, transpose: gl.GLboolean, m: mat.Matrix(4, 2)) void {
        gl.uniformMatrix4x2fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix3x4(self: Self, transpose: gl.GLboolean, m: mat.Matrix(3, 4)) void {
        gl.uniformMatrix3x4fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix4x3(self: Self, transpose: gl.GLboolean, m: mat.Matrix(4, 3)) void {
        gl.uniformMatrix4x3fv(
            self.location,
            1,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }
    /////////////////////////////////////

    pub inline fn sendMatrix2Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Matrix(2, 2)) void {
        gl.uniformMatrix2fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix3Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Mat3x3) void {
        gl.uniformMatrix3fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix4Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Mat4x4) void {
        gl.uniformMatrix4fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix2x3Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Matrix(2, 3)) void {
        gl.uniformMatrix2x3fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix3x2Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Matrix(3, 2)) void {
        gl.uniformMatrix3x2fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix2x4Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Matrix(2, 4)) void {
        gl.uniformMatrix2x4fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix4x2Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Matrix(4, 2)) void {
        gl.uniformMatrix4x2fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix3x4Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Matrix(3, 4)) void {
        gl.uniformMatrix3x4fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }

    pub inline fn sendMatrix4x3Array(self: Self, count: gl.GLsizei, transpose: gl.GLboolean, m: mat.Matrix(4, 3)) void {
        gl.uniformMatrix4x3fv(
            self.location,
            count,
            transpose,
            @ptrCast(&m.vec[0]),
        );
    }
};
