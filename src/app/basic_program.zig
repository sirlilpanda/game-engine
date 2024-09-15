const program = @import("../opengl_wrappers/program.zig");
const uni = @import("../opengl_wrappers/uniform.zig");
const obj = @import("../objects/object.zig");
const cam = @import("../opengl_wrappers/camera.zig");
const mat = @import("../math/matrix.zig");
const vec = @import("../math/vec.zig");
const shader = @import("../opengl_wrappers/shader.zig");

const std = @import("std");

const basic_3d_program_logger = std.log.scoped(.Basic3dProgram);

// /// this is a very basic program that sends the
// /// model view matrix, the model view projection matrix
// /// the nomral matrix and a light position
// pub const BasicUniforms = struct {
//     const Self = @This();
//     mvMatrixUniform: uni.Uniform = uni.Uniform.init("mvMatrix"),
//     mvpMatrixUniform: uni.Uniform = uni.Uniform.init("mvpMatrix"),
//     norMatrixUniform: uni.Uniform = uni.Uniform.init("norMatrix"),
//     lgtUniform: uni.Uniform = uni.Uniform.init("lightPos"),

//     pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {
//         // i dont know if this is faster
//         var model = mat.Mat4x4.idenity();

//         model = model.mul(mat.Mat4x4.translate(object.pos)).mul(mat.Mat4x4.rotate(object.roation.vec[1], vec.init3(1, 1, 0)));

//         const mvMatrix = camera.view_matrix.mul(model);
//         const mvpMatrix = camera.projection_matrix.mul(mvMatrix);
//         const invMatrix = mvMatrix.inverseTranspose();

//         //could queue in another thread to speed up times
//         self.mvMatrixUniform.sendMatrix4(false, mvMatrix);
//         self.mvpMatrixUniform.sendMatrix4(false, mvpMatrix);
//         self.norMatrixUniform.sendMatrix4(false, invMatrix);
//         // self.lgtUniform.sendVec4(vec.init4(camera.eye.vec[0], camera.eye.vec[1], camera.eye.vec[2], 0));
//         object.draw();
//     }

//     pub fn reload(self: Self) void {
//         _ = self;
//     }
// };

// /// basic program that uses basic uniforms
// pub const BasicProgram = program.Program(BasicUniforms);

/// this is a very basic program that sends the
/// model view matrix, the model view projection matrix
/// the nomral matrix, a light position, a object colour
/// and texture sampler
pub const BasicUniformsText = struct {
    const Self = @This();
    hasDiffuseLighting: uni.Uniform = uni.Uniform.init("hasDiffuseLighting"),
    ambient_colour: uni.Uniform = uni.Uniform.init("ambient_colour"),
    norMatrixUniform: uni.Uniform = uni.Uniform.init("norMatrix"),
    mvpMatrixUniform: uni.Uniform = uni.Uniform.init("mvpMatrix"),
    mvMatrixUniform: uni.Uniform = uni.Uniform.init("mvMatrix"),
    textureUniform: uni.Uniform = uni.Uniform.init("tSampler"),
    mMatrixUniform: uni.Uniform = uni.Uniform.init("mMatrix"),
    obj_colour: uni.Uniform = uni.Uniform.init("obj_colour"),
    lgtUniform: uni.Uniform = uni.Uniform.init("lightPos"),

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

    /// reloads the some of the defualt values
    pub fn reload(self: Self) void {
        basic_3d_program_logger.info("reloading basic 3d program", .{});
        self.hasDiffuseLighting.send1Uint(0);
        self.ambient_colour.sendVec4(vec.init4(0.2, 0.2, 0.2, 1));
        self.obj_colour.sendVec4(vec.init4(1, 1, 1, 1));
        const light: vec.Vec4 = vec.init4(5, 10, 7, 1);
        self.lgtUniform.sendVec4(light);
    }

    pub fn updateLightPos(self: Self, light: vec.Vec3) void {
        self.uniforms.lgtUniform.sendVec4(light);
    }
};

pub const BasicProgramTex = program.Program(BasicUniformsText, 32);

/// init function for the BasicProgramTex program, i keep it here to show how to nicely init new programs
pub fn createBasicProgramWTexture(allocator: std.mem.Allocator) !BasicProgramTex {
    basic_3d_program_logger.info("attempting to create basic 3d program", .{});
    var prog = BasicProgramTex.init();

    const vert = try shader.Shader.init(allocator, "shaders/crab.vert", .vertex);
    const frag = try shader.Shader.init(allocator, "shaders/crab.frag", .frag);

    prog.loadShader(vert);
    prog.loadShader(frag);
    prog.link();
    prog.use();

    prog.uniforms.hasDiffuseLighting.send1Uint(1);
    prog.uniforms.ambient_colour.sendVec4(vec.init4(0.2, 0.2, 0.2, 1));
    const light: vec.Vec4 = vec.init4(5, 10, 7, 1);
    prog.uniforms.obj_colour.sendVec4(vec.init4(1, 1, 1, 1));
    prog.uniforms.lgtUniform.sendVec4(light);

    basic_3d_program_logger.info("created basic 3d program", .{});
    return prog;
}
