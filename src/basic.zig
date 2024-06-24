const program = @import("opengl_wrappers/program.zig");
const uni = @import("opengl_wrappers/uniform.zig");
const obj = @import("objects/object.zig");
const cam = @import("opengl_wrappers/camera.zig");
const mat = @import("math/matrix.zig");
const vec = @import("math/vec.zig");
const std = @import("std");

pub const BasicUniforms = struct {
    const Self = @This();
    mvMatrixUniform: uni.Uniform = uni.Uniform.init("mvMatrix"),
    mvpMatrixUniform: uni.Uniform = uni.Uniform.init("mvpMatrix"),
    norMatrixUniform: uni.Uniform = uni.Uniform.init("norMatrix"),
    lgtUniform: uni.Uniform = uni.Uniform.init("lightPos"),

    pub fn draw(self: Self, camera: cam.Camera, object: obj.Object) void {
        // i dont know if this is faster
        var model = mat.Mat4x4.idenity();

        model = model.mul(mat.Mat4x4.translate(object.pos)).mul(mat.Mat4x4.rotate(object.roation.vec[1], vec.init3(1, 1, 0)));

        const mvMatrix = camera.view_matrix.mul(model);
        const mvpMatrix = camera.projection_matrix.mul(mvMatrix);
        const invMatrix = mvMatrix.inverseTranspose();

        //could queue in another thread to speed up times
        self.mvMatrixUniform.sendMatrix4(false, mvMatrix);
        self.mvpMatrixUniform.sendMatrix4(false, mvpMatrix);
        self.norMatrixUniform.sendMatrix4(false, invMatrix);
        // self.lgtUniform.sendVec4(vec.init4(camera.eye.vec[0], camera.eye.vec[1], camera.eye.vec[2], 0));
        object.draw();
    }
};

pub const BasicProgram = program.Program(BasicUniforms);

pub const BasicUniformsText = struct {
    const Self = @This();
    mMatrixUniform: uni.Uniform = uni.Uniform.init("mMatrix"),
    mvMatrixUniform: uni.Uniform = uni.Uniform.init("mvMatrix"),
    mvpMatrixUniform: uni.Uniform = uni.Uniform.init("mvpMatrix"),
    norMatrixUniform: uni.Uniform = uni.Uniform.init("norMatrix"),
    lgtUniform: uni.Uniform = uni.Uniform.init("lightPos"),
    textureUniform: uni.Uniform = uni.Uniform.init("tSampler"),

    pub fn draw(self: Self, camera: cam.Camera, object: obj.Object) void {
        // i dont know if this is faster

        var model = mat.Mat4x4.idenity();

        model = model.mul(mat.Mat4x4.translate(object.pos))
            .mul(mat.Mat4x4.rotate(object.roation.vec[1], vec.init3(1, 1, 0)));
        self.mMatrixUniform.sendMatrix4(false, model);

        const mvMatrix = camera.view_matrix.mul(model);
        const mvpMatrix = camera.projection_matrix.mul(mvMatrix);
        const invMatrix = mvMatrix.inverseTranspose();

        //could queue in another thread to speed up times
        self.mvMatrixUniform.sendMatrix4(false, mvMatrix);
        self.mvpMatrixUniform.sendMatrix4(false, mvpMatrix);
        self.norMatrixUniform.sendMatrix4(false, invMatrix);
        // self.lgtUniform.sendVec4(vec.init4(camera.eye.vec[0], camera.eye.vec[1], camera.eye.vec[2], 0));
        object.draw();
    }
};

pub const BasicProgramTex = program.Program(BasicUniformsText);
