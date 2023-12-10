const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const file_reader = @import("loadfile.zig");

const log = std.log.scoped(.Engine);

var program: gl.GLuint = undefined;
var VAO: gl.GLuint = undefined;

// A single triangle
const verts = [_]gl.GLfloat{ -0.8, -0.8, 0.8, -0.8, 0.0, 0.8 };
// Color for each vertex
const cols = [_]gl.GLfloat{ 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0 };

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(640, 480, "mach-glfw + zig-opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 5,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    try GL_init();

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        glfw.pollEvents();

        // gl.clearColor(1, 0, 1, 1);
        // gl.clear(gl.COLOR_BUFFER_BIT);
        GL_Render();
        window.swapBuffers();
    }
}

fn GL_init() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const vert_file: []u8 = try file_reader.loadfile(allocator, "shaders/basic.vert");
    const frag_file: []u8 = try file_reader.loadfile(allocator, "shaders/basic.frag");
    defer allocator.free(vert_file);
    defer allocator.free(frag_file);

    std.debug.print("\nvert : {s}\n", .{vert_file});
    std.debug.print("=========================\n", .{});
    std.debug.print("frag : {s}\n", .{frag_file});

    var uiVertexShader = gl.createShader(gl.VERTEX_SHADER);
    gl.shaderSource(uiVertexShader, 1, @ptrCast(&vert_file), null);
    gl.compileShader(uiVertexShader);

    chech_status(uiVertexShader);

    var uiFragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(uiFragmentShader, 1, @ptrCast(&frag_file), null);
    gl.compileShader(uiFragmentShader);
    // defer gl.deleteShader(gl.VERTEX_SHADER);
    // defer gl.deleteShader(gl.FRAGMENT_SHADER);
    chech_status(uiFragmentShader);


    program = gl.createProgram();
    gl.attachShader(program, uiVertexShader);
    gl.attachShader(program, uiFragmentShader);
    gl.linkProgram(program);
    gl.useProgram(program);

    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);

    var VBO_points: gl.GLuint = undefined;
    var VBO_colour: gl.GLuint = undefined;
    
    gl.genBuffers(1, &VBO_points);
    gl.genBuffers(1, &VBO_colour);
    // std.debug.print("VBO {} {}", .{ VBO[0], VBO[1] });

    gl.bindBuffer(gl.ARRAY_BUFFER, VBO_points);
    gl.bufferData(gl.ARRAY_BUFFER, verts.len * @sizeOf(gl.GLfloat), &verts, gl.STATIC_DRAW);
    gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, null);

    gl.bindBuffer(gl.ARRAY_BUFFER, VBO_colour);
    gl.bufferData(gl.ARRAY_BUFFER, cols.len * @sizeOf(gl.GLfloat), &cols, gl.STATIC_DRAW);
    gl.vertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, 0, null);
    gl.enableVertexAttribArray(0);
    gl.enableVertexAttribArray(1);

    // gl.enable(gl.CULL_FACE); // cull face
    gl.cullFace(gl.BACK); // cull back face
    gl.frontFace(gl.CW); // GL_CCW for counter clock-wise

    // gl.clearColor(0, 0, 0, 1);
}

fn GL_Render() void {
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.bindVertexArray(VAO);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    gl.flush();
}

// fn GL_loadShader(ShaderType: gl.GLenum, p_cShader: ?[*]const u8) gl.GLuint {

//     return Shader;
// }

fn chech_status(shader: gl.GLuint) void {
    var status: gl.GLint = undefined;
    gl.getShaderiv(shader, gl.COMPILE_STATUS, &status);
    if (status == gl.FALSE) {
        std.debug.print("shader failed", .{});
    }
}
