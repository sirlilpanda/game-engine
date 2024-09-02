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

    pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {
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
    hasDiffuseLighting: uni.Uniform = uni.Uniform.init("hasDiffuseLighting"),
    ambient_colour: uni.Uniform = uni.Uniform.init("ambient_colour"),
    obj_colour: uni.Uniform = uni.Uniform.init("obj_colour"),

    pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {
        // i dont know if this is faster
        // if the object has a texture swap to it
        if (object.texture) |tex| tex.useTexture();

        var model = mat.Mat4x4.idenity();

        model = model.mul(mat.Mat4x4.translate(object.pos))
            .mul(mat.Mat4x4.rotate(object.roation.vec[0], vec.init3(1, 0, 0)))
            .mul(mat.Mat4x4.rotate(object.roation.vec[1], vec.init3(0, 1, 0)))
            .mul(mat.Mat4x4.rotate(object.roation.vec[2], vec.init3(0, 0, 1)))
            .mul(mat.Mat4x4.scale(object.scale));
        self.mMatrixUniform.sendMatrix4(false, model);

        const mvMatrix = camera.view_matrix.mul(model);
        const mvpMatrix = camera.projection_matrix.mul(mvMatrix);
        const invMatrix = mvMatrix.inverseTranspose();

        //could queue in another thread to speed up times
        self.mvMatrixUniform.sendMatrix4(false, mvMatrix);
        self.mvpMatrixUniform.sendMatrix4(false, mvpMatrix);
        self.norMatrixUniform.sendMatrix4(true, invMatrix);
        // self.lgtUniform.sendVec4(vec.init4(camera.eye.vec[0], camera.eye.vec[1], camera.eye.vec[2], 0));
        object.draw();
    }

    pub fn reload(self: Self) void {
        self.hasDiffuseLighting.send1Uint(1);
        self.ambient_colour.sendVec4(vec.init4(0.2, 0.2, 0.2, 1));
        self.obj_colour.sendVec4(vec.init4(1, 1, 1, 1));
        const light: vec.Vec4 = vec.init4(5, 10, 7, 1);
        self.lgtUniform.sendVec4(light);
    }

    // pub fn updateLightPos(self: Self, camera: *cam.Camera) void {
    //     const lighteye: vec.Vec4 = camera.view_matrix.MulVec(light);
    //     self.uniforms.lgtUniform.sendVec4(lighteye);
    // }
};

pub const BasicProgramTex = program.Program(BasicUniformsText, 32);

const shader = @import("opengl_wrappers/shader.zig");

pub fn createBasicProgramWTexture(allocator: std.mem.Allocator) !BasicProgramTex {
    var prog = BasicProgramTex.init();
    const vert = try shader.Shader.init(allocator, "shaders/crab.vert", .vertex);
    const frag = try shader.Shader.init(allocator, "shaders/crab.frag", .frag);
    prog.load_shader(vert);
    prog.load_shader(frag);
    prog.link();
    prog.use();

    prog.uniforms.hasDiffuseLighting.send1Uint(1);
    prog.uniforms.ambient_colour.sendVec4(vec.init4(0.2, 0.2, 0.2, 1));
    const light: vec.Vec4 = vec.init4(5, 10, 7, 1);
    prog.uniforms.obj_colour.sendVec4(vec.init4(1, 1, 1, 1));
    prog.uniforms.lgtUniform.sendVec4(light);

    return prog;
}
