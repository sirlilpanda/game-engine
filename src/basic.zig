const program = @import("opengl_wrappers/program.zig");
const uni = @import("opengl_wrappers/uniform.zig");
const obj = @import("objects/object.zig");
const cam = @import("opengl_wrappers/camera.zig");
const mat = @import("math/matrix.zig");

//all the types in here must be uni forms
pub const BasicUniforms = struct {
    const Self = @This();
    mvMatrixUniform: uni.Uniform = uni.Uniform.init("mvMatrix"),
    mvpMatrixUniform: uni.Uniform = uni.Uniform.init("mvpMatrix"),
    norMatrixUniform: uni.Uniform = uni.Uniform.init("norMatrix"),
    lgtUniform: uni.Uniform = uni.Uniform.init("lightPos"),

    pub fn draw(self: Self, camera: cam.Camera, object: obj.Object) void {
        // i dont know if this is faster
        const mvMatrix = camera.view_matrix
            .mul(mat.Mat4x4.rotate_x(object.roation.vec[0]))
            .mul(mat.Mat4x4.rotate_y(object.roation.vec[1]))
            .mul(mat.Mat4x4.rotate_z(object.roation.vec[2]))
            .mul(mat.Mat4x4.translate(object.pos));

        const mvpMatrix = mvMatrix.mul(camera.projection_matrix);
        const invMatrix = mvMatrix.inverseTranspose();

        self.mvMatrixUniform.sendMatrix4(false, mvMatrix);
        self.mvpMatrixUniform.sendMatrix4(false, mvpMatrix);
        self.norMatrixUniform.sendMatrix4(false, invMatrix);
        object.draw();
    }
};

pub const BasicProgram = program.Program(BasicUniforms);
