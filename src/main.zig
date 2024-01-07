const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const mat = @import("math/matrix.zig");
const vec = @import("math/vec.zig");
const time = std.time;
const Tuple = std.meta.Tuple;

const shader = @import("opengl_wrappers/shader.zig");
const program = @import("opengl_wrappers/program.zig");
const render = @import("opengl_wrappers/render.zig");
const uni = @import("opengl_wrappers/uniform.zig");
const cam = @import("opengl_wrappers/camera.zig");
const obj = @import("objects/object.zig");

const basic = @import("basic.zig");

var angle: f32 = 0;
const CDR: f32 = std.math.pi / 180.0;

var seaShell1: obj.Object = undefined;
var seaShell2: obj.Object = undefined;
var camera: cam.Camera = undefined;

// var viewMatrix: mat.Mat4x4 = undefined;
// var projMatrix: mat.Mat4x4 = undefined;
var num_triangles: usize = undefined;
var keep_running = false;

var prog: basic.BasicProgram = undefined;

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
        std.debug.print("{d:.2}, {d:.2}, pos : {}, lookat : {}\r", .{ @reduce(.Add, win), angle, camera.eye, camera.look_at_point });
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
        const delta_time = @as(f32, @floatFromInt(timer.lap())) * 0.000000001;
        win[i] = (1 / (delta_time)) / win_size;
        glfw.pollEvents();
        input(&camera, delta_time, window);
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

    const light: vec.Vec4 = vec.init4(0, 5, 0, 1);

    prog = basic.BasicProgram.init();

    const vert = try shader.Shader.init(allocator, "shaders/Seashell.vert", .vertex);
    const frag = try shader.Shader.init(allocator, "shaders/Seashell.frag", .frag);

    prog.load_shader(vert);
    prog.load_shader(frag);

    prog.link();
    prog.use();

    camera = cam.Camera.init(
        40,
        screen_width / screen_hight,
        1,
        100,
        vec.init3(0, 0, 2),
    );

    const lighteye: vec.Vec4 = camera.view_matrix.MulVec(light);
    prog.uniforms.lgtUniform.sendVec4(lighteye);

    // gl.uniform4fv(lgtLoc, 1, @ptrCast(&lighteye.vec[0]));

    gl.clearColor(1, 1, 1, 1);
    gl.enable(gl.DEPTH_TEST); // cull face
    gl.cullFace(gl.BACK); // cull back face

    var seaShell = render.renderer.init();
    try seaShell.loadDatFile(allocator, "objects/Seashell.dat");
    const basic_seaShell = obj.ObjectFactory.init(seaShell);

    seaShell1 = basic_seaShell.make(vec.Vec3.zeros(), vec.Vec3.zeros());
    seaShell2 = basic_seaShell.make(vec.Vec3.zeros(), vec.Vec3.zeros());

    // gl.frontFace(gl.CW); // GL_CCW for counter clock-wise

}

fn GL_Render() void {
    // const ident: mat.Mat4x4 = mat.Mat4x4.idenity()
    // _ = ident;
    // const rotationMatrix = ident.rotate(angle * CDR, vec.init3(0, 0, 1));
    // const invMatrix = mvMatrix.t();
    // const mvMatrix = viewMatrix.mul(rotationMatrix);

    camera.update();
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    // seaShell1.updateRoation(vec.Vec3.number());
    seaShell2.updateRoation(vec.Vec3.number(angle * CDR));

    prog.uniforms.draw(camera, seaShell1);
    prog.uniforms.draw(camera, seaShell2);

    // gl.clear();
    // gl.bindVertexArray(VAO);
    // gl.drawElements(gl.TRIANGLES, @as(gl.GLsizei, @intCast(num_triangles)), gl.UNSIGNED_INT, null);

    gl.flush();
}

fn input(came: *cam.Camera, delta_time: f32, window: glfw.Window) void {
    const speed = 1;
    const displacement = 10;
    if (window.getKey(glfw.Key.w) == glfw.Action.press) {
        camera.eye.vec[0] += delta_time * speed * @cos(came.yaw * CDR);
        camera.eye.vec[2] += delta_time * speed * @sin(came.yaw * CDR);
    }
    // Move backward
    if (window.getKey(glfw.Key.s) == glfw.Action.press) {
        camera.eye.vec[0] -= delta_time * speed * @cos(came.yaw * CDR);
        camera.eye.vec[2] -= delta_time * speed * @sin(came.yaw * CDR);
    }

    // Strafe left
    if (window.getKey(glfw.Key.a) == glfw.Action.press) {
        came.yaw -= delta_time * speed * 50;
    }
    // Strafe right
    if (window.getKey(glfw.Key.d) == glfw.Action.press) {
        came.yaw += delta_time * speed * 50;
    }

    if (came.yaw > 180) {
        came.yaw = -180;
    }
    if (came.yaw < -180) {
        came.yaw = 180;
    }

    camera.look_at_point.vec[0] = camera.eye.vec[0] + displacement * @cos(came.yaw * CDR);
    camera.look_at_point.vec[2] = camera.eye.vec[2] + displacement * @sin(came.yaw * CDR);
}
