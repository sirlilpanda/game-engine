const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const file_reader = @import("loadfile.zig");
const mat = @import("math/matrix.zig");
const vec = @import("math/vec.zig");
const time = std.time;
const Tuple = std.meta.Tuple;

const shader = @import("opengl_wrappers/shader.zig");
const program = @import("opengl_wrappers/program.zig");
const render = @import("opengl_wrappers/render.zig");
const uni = @import("opengl_wrappers/uniform.zig");

const log = std.log.scoped(.Engine);

var mvpMatrixUniform: uni.Uniform = undefined;
var mvMatrixUniform: uni.Uniform = undefined;
var norMatrixUniform: uni.Uniform = undefined;
var lgtUniform: uni.Uniform = undefined;

var angle: f32 = 0;
const CDR: f32 = std.math.pi / 180.0;

var seaShell1: render.renderer = undefined;
var seaShell2: render.renderer = undefined;

var viewMatrix: mat.Mat4x4 = undefined;
var projMatrix: mat.Mat4x4 = undefined;
var num_triangles: usize = undefined;
var keep_running = false;

const screen_hight = 1080;
const screen_width = 1920;

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
    const window = glfw.Window.create(screen_width, screen_hight, "game-shit-dwag", null, null, .{
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
        GL_Render();
        window.swapBuffers();
    }
    keep_running = true;
}

fn GL_init() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const light: vec.Vec4 = vec.init4(-20, 5, 0, 1);

    var prog = program.Program.init();
    try prog.add_vert_n_frag(
        allocator,
        "shaders/Seashell.vert",
        "shaders/Seashell.frag",
    );
    prog.link();
    prog.use();

    mvMatrixUniform = prog.addUniform("mvMatrix");
    mvpMatrixUniform = prog.addUniform("mvpMatrix");
    norMatrixUniform = prog.addUniform("norMatrix");
    lgtUniform = prog.addUniform("lightPos");

    projMatrix = mat.Mat4x4.perspective(40.0 * CDR, screen_width / screen_hight, 1, 1000);
    viewMatrix = mat.Mat4x4.lookAt(
        vec.init3(1, 1, 3),
        vec.init3(0, 0, 0),
        vec.init3(0, 1, 0),
    );
    const lighteye: vec.Vec4 = viewMatrix.MulVec(light);
    lgtUniform.sendVec4(lighteye);

    // gl.uniform4fv(lgtLoc, 1, @ptrCast(&lighteye.vec[0]));

    gl.clearColor(1, 1, 1, 1);
    gl.enable(gl.DEPTH_TEST); // cull face
    gl.cullFace(gl.BACK); // cull back face

    // try loadSeaShell();
    seaShell1 = render.renderer.init();
    seaShell2 = render.renderer.init();
    try seaShell1.loadDatFile(allocator, "objects/Seashell.dat");
    try seaShell2.loadDatFile(allocator, "objects/Seashell.dat");

    // gl.frontFace(gl.CW); // GL_CCW for counter clock-wise

}

fn GL_Render() void {
    // const ident: mat.Mat4x4 = mat.Mat4x4.idenity();
    // _ = ident;
    // const rotationMatrix = ident.rotate(angle * CDR, vec.init3(0, 0, 1));
    // const invMatrix = mvMatrix.t();
    // const mvMatrix = viewMatrix.mul(rotationMatrix);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    const mvMatrix = viewMatrix.mul(mat.Mat4x4.rotate_y(angle * CDR));
    const mvpMatrix = mvMatrix.mul(projMatrix);
    const invMatrix = mvMatrix.inverseTranspose();

    mvMatrixUniform.sendMatrix4(gl.FALSE, mvMatrix);
    mvpMatrixUniform.sendMatrix4(gl.FALSE, mvpMatrix);
    norMatrixUniform.sendMatrix4(gl.FALSE, invMatrix);

    seaShell1.render();
    // mvMatrix.debug_print_matrix();

    const mvMatrix1 = viewMatrix.mul(mat.Mat4x4.rotate_y(angle * CDR))
        .mul(mat.Mat4x4.translate(vec.init3(0, 0, 0)));

    const mvpMatrix1 = mvMatrix1.mul(projMatrix);
    const invMatrix1 = mvMatrix1.inverseTranspose();

    mvMatrixUniform.sendMatrix4(gl.FALSE, mvMatrix1);
    mvpMatrixUniform.sendMatrix4(gl.FALSE, mvpMatrix1);
    norMatrixUniform.sendMatrix4(gl.FALSE, invMatrix1);

    seaShell2.render();

    // gl.clear();
    // gl.bindVertexArray(VAO);
    // gl.drawElements(gl.TRIANGLES, @as(gl.GLsizei, @intCast(num_triangles)), gl.UNSIGNED_INT, null);

    gl.flush();
}
