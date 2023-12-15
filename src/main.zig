const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const file_reader = @import("loadfile.zig");
const mat = @import("math/matrix.zig");
const vec = @import("math/vec.zig");
const time = std.time;
const Tuple = std.meta.Tuple;

const shader_loader = @import("opengl_wrappers/shader.zig");

const log = std.log.scoped(.Engine);

var VAO: gl.GLuint = undefined;
var mvpMatrixLoc: gl.GLint = undefined;
var mvMatrixLoc: gl.GLint = undefined;
var norMatrixLoc: gl.GLint = undefined;
var lgtLoc: gl.GLint = undefined;

var angle: f32 = 0;
const CDR: f32 = std.math.pi / 180.0;
var viewMatrix: mat.Mat4x4 = undefined;
var projMatrix: mat.Mat4x4 = undefined;

var num_triangles: usize = undefined;
var keep_running = false;

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

const win_size = 256;
var win: @Vector(win_size, f32) = @splat(0);
var i: u8 = 0;

fn spin() void {
    while (!keep_running) {
        std.debug.print("{d:.2}, {d:.2}\r", .{ @reduce(.Add, win), angle });
        angle += 0.5;
        // std.debug.print("angle : {}\n", .{angle});
        time.sleep(1000000);
    }
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(1920, 1080, "game-shit-dwag", null, null, .{
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

    var anamation_thread = try std.Thread.spawn(
        .{},
        spin,
        .{},
    );
    anamation_thread.detach();

    var timer = try time.Timer.start();
    while (!window.shouldClose()) : (i +%= 1) {
        win[i] = (1 / (@as(f32, @floatFromInt(timer.lap())) * 0.000000001)) / win_size;
        glfw.pollEvents();

        // std.debug.print("angle = {}\n", .{angle});
        // gl.clearColor(1, 0, 1, 1);
        // gl.clear(gl.COLOR_BUFFER_BIT);
        try GL_Render();
        window.swapBuffers();
    }
    keep_running = true;
}

fn loadSeaShell() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const dat = try file_reader.DatFile.loadDatFile(allocator, "objects/Seashell.dat");

    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);

    var VBOids: [3]gl.GLuint = undefined;

    gl.genBuffers(3, &VBOids);
    // std.debug.print("VBO {} {} {}", .{ VBOids[0], VBOids[1], VBOids[2] });

    gl.bindBuffer(gl.ARRAY_BUFFER, VBOids[0]);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @as(isize, @intCast(dat.verts.len * @sizeOf(gl.GLfloat))),
        @ptrCast(&dat.verts[0]),
        gl.STATIC_DRAW,
    );
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, null);

    gl.bindBuffer(gl.ARRAY_BUFFER, VBOids[1]);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @as(isize, @intCast(dat.normals.len * @sizeOf(f32))),
        @ptrCast(&dat.normals[0]),
        gl.STATIC_DRAW,
    );
    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 0, null);

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, VBOids[2]);
    gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        @as(isize, @intCast(dat.elements.len * @sizeOf(u32))),
        @ptrCast(&dat.elements[0]),
        gl.STATIC_DRAW,
    );

    num_triangles = dat.elements.len;

    dat.unload();

    gl.bindVertexArray(0);
}

fn GL_init() !void {
    const light: vec.Vec4 = vec.init4(-20, 5, 0, 1);

    var program = try shader_loader.createShaderProgram(
        "shaders/Seashell.vert",
        "shaders/Seashell.frag",
    );

    mvMatrixLoc = gl.getUniformLocation(program, "mvMatrix");
    mvpMatrixLoc = gl.getUniformLocation(program, "mvpMatrix");
    norMatrixLoc = gl.getUniformLocation(program, "norMatrix");
    lgtLoc = gl.getUniformLocation(program, "lightPos");

    projMatrix = mat.Mat4x4.perspective(40.0 * CDR, 1, 1, 10);
    viewMatrix = mat.Mat4x4.lookAt(
        vec.init3(-1, -1, 1),
        vec.init3(0, 0, 0),
        vec.init3(0, 1, 0),
    );
    const lighteye: vec.Vec4 = viewMatrix.MulVec(light);
    gl.uniform4fv(lgtLoc, 1, @ptrCast(&lighteye.vec[0]));

    gl.clearColor(1, 1, 1, 1);
    gl.enable(gl.DEPTH_TEST); // cull face
    // gl.cullFace(gl.BACK); // cull back face

    try loadSeaShell();

    // gl.frontFace(gl.CW); // GL_CCW for counter clock-wise

}

fn GL_Render() !void {
    // const ident: mat.Mat4x4 = mat.Mat4x4.idenity();
    // _ = ident;
    // const rotationMatrix = ident.rotate(angle * CDR, vec.init3(0, 0, 1));

    const mvMatrix = viewMatrix.rotate(angle * CDR, vec.init3(1, 1, 1)); // roatating camera

    // const mvMatrix = viewMatrix.mul(rotationMatrix);
    const mvpMatrix = mvMatrix.mul(projMatrix);
    const invMatrix = mvMatrix.inverseTranspose();

    // std.debug.print("mv\n", .{});
    // rotationMatrix.debug_print_matrix();
    // viewMatrix.debug_print_matrix();
    // mvMatrix.debug_print_matrix(); //
    // mvpMatrix.debug_print_matrix(); //
    // invMatrix.debug_print_matrix();

    gl.uniformMatrix4fv(mvMatrixLoc, 1, gl.FALSE, @ptrCast(&mvMatrix.vec[0]));
    gl.uniformMatrix4fv(mvpMatrixLoc, 1, gl.FALSE, @ptrCast(&mvpMatrix.vec[0]));
    gl.uniformMatrix4fv(norMatrixLoc, 1, gl.FALSE, @ptrCast(&invMatrix.vec[0]));
    // mvMatrix.debug_print_matrix();

    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    // gl.clear();
    gl.bindVertexArray(VAO);
    gl.drawElements(gl.TRIANGLES, @as(gl.GLsizei, @intCast(num_triangles)), gl.UNSIGNED_INT, null);
    gl.flush();
}
