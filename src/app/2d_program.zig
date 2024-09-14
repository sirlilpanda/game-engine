const program = @import("../opengl_wrappers/program.zig");
const uni = @import("../opengl_wrappers/uniform.zig");
const obj = @import("../objects/object.zig");
const cam = @import("../opengl_wrappers/camera.zig");
const mat = @import("../math/matrix.zig");
const vec = @import("../math/vec.zig");
const shader = @import("../opengl_wrappers/shader.zig");
const render = @import("../opengl_wrappers/render.zig");

const std = @import("std");
const gl = @import("gl");
/// this is a very basic program that sends the
/// model view matrix, the model view projection matrix
/// the nomral matrix, a light position, a object colour
/// and texture sampler
pub const BasicUniforms2d = struct {
    const Self = @This();
    colour: uni.Uniform = uni.Uniform.init("colour"),

    pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {
        _ = camera;
        self.colour.sendVec4(vec.init4(1, 0, 1, 1));

        gl.disable(gl.DEPTH_TEST);
        object.render.render_2d.render();
        gl.enable(gl.DEPTH_TEST);
    }

    /// reloads the some of the defualt values
    pub fn reload(self: Self) void {
        self.colour.sendVec4(vec.Vec4.ones());
    }
};

pub const BasicProgram2D = program.Program(BasicUniforms2d, 32);

/// init function for the BasicProgram2D program, i keep it here to show how to nicely init new programs
pub fn createBasic2DProgram(allocator: std.mem.Allocator) !BasicProgram2D {
    var prog = BasicProgram2D.init();

    const vert = try shader.Shader.init(allocator, "shaders/basic_2d.vert", .vertex);
    const frag = try shader.Shader.init(allocator, "shaders/basic_2d.frag", .frag);

    prog.loadShader(vert);
    prog.loadShader(frag);
    prog.link();
    prog.use();

    return prog;
}
