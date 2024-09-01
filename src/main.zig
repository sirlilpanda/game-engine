const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const mat = @import("math/matrix.zig");
const vec = @import("math/vec.zig");
const time = std.time;
const Tuple = std.meta.Tuple;
const Allocator = std.mem.Allocator;

const shader = @import("opengl_wrappers/shader.zig");
const program = @import("opengl_wrappers/program.zig");
const render = @import("opengl_wrappers/render.zig");
const uni = @import("opengl_wrappers/uniform.zig");
const cam = @import("opengl_wrappers/camera.zig");
const window = @import("opengl_wrappers/window.zig");
const tex = @import("opengl_wrappers/texture.zig");
const cprint = @import("console_logger/coloured_text.zig");
const obj = @import("objects/object.zig");
const file = @import("file_loading/loadfile.zig");
const basic = @import("basic.zig");
const obj_loader = @import("objects/object_loader_service.zig");

var angle: f32 = 0;
const CDR: f32 = std.math.pi / 180.0;

var obj_loader_service: obj_loader.ObjectService = undefined;
var index: u32 = 0;
var crab: obj.Object = undefined;

var camera: cam.Camera = undefined;
var keep_running = false;

var prog: basic.BasicProgramTex = undefined;
var printer = cprint.ColourPrinter.init();

const screen_hight = 1080;
const screen_width = 1920;

const win_size = 256;
var win: @Vector(win_size, f32) = @splat(0);
var i: u8 = 0;

fn spin() void {
    printer.clear();
    while (!keep_running) {
        angle += 0.5;
        // std.debug.print("angle : {}\n", .{angle});
        if (angle > 360) angle = 0;
        printDebug();
        time.sleep(1000000);
    }
}

fn printDebug() void {
    printer.setFgColour(cprint.Colour.purple());
    const fps = @reduce(.Add, win);
    std.debug.print("fps:", .{});
    printer.print("{}\n", .{fps});

    std.debug.print("angle:", .{});
    printer.print("{}\n", .{angle});

    std.debug.print("pos:", .{});
    printer.vec3(camera.eye);
    std.debug.print("\nlookat:", .{});
    printer.vec3(camera.look_at_point);
    std.debug.print("\n", .{});
    printer.home();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const wind = try window.Window.init(screen_width, screen_hight);
    obj_loader_service = try obj_loader.ObjectService.init(allocator);
    prog = try basic.createBasicProgramWTexture(allocator);

    camera = cam.Camera.init(
        90,
        wind.getAspectRatio(),
        0.1,
        10000,
        vec.init3(0, 0, 0),
    );
    prog.camera = &camera;

    const text = try tex.Texture.init(allocator, "textures/Crab_D.tga");
    _ = text;

    mat.Mat4x4.debug_print_matrix(camera.projection_matrix);
    const light: vec.Vec4 = vec.init4(5, 10, 7, 1);
    const lighteye: vec.Vec4 = camera.view_matrix.MulVec(light);
    prog.uniforms.lgtUniform.sendVec4(lighteye);
    prog.uniforms.textureUniform.send1Uint(0);

    crab = try obj_loader_service.load("objects/Crab.obj", .obj);
    // const cube = try obj_loader_service.load("objects/Crab.obj", .obj);
    for (prog.objects, 0..) |_, dex| {
        var ject: obj.Object = undefined;

        ject = crab;
        ject.pos = vec.init3(
            5 * @sin(@as(f32, @floatFromInt(dex))),
            5 * @cos(@as(f32, @floatFromInt(dex))),
            0,
        );
        prog.objects[dex] = ject;
    }

    var anamation_thread = try std.Thread.spawn(.{}, spin, .{});
    anamation_thread.detach();

    gl.clearColor(0, 0, 0, 1);
    gl.enable(gl.DEPTH_TEST); // cull face
    gl.cullFace(gl.BACK); // cull back face
    wind.hideCursor();
    var timer = try time.Timer.start();
    while (!wind.shouldClose()) : (i +%= 1) {
        const delta_time = @as(f32, @floatFromInt(timer.lap())) * 0.000000001;
        const fps = @reduce(.Add, win);
        std.debug.print("fps : {:.3}\r", .{fps});
        win[i] = (1 / (delta_time)) / win_size;
        glfw.pollEvents();
        try input(&camera, delta_time, wind);
        GL_Render();
        wind.swapBuffer();
    }
    keep_running = true;
    printer.clear();
    obj_loader_service.deinit();
}

fn GL_Render() void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    prog.renderAll();
    gl.flush();
}

var last = vec.init2(0, 0);
var pressed: bool = false;
var speed: f32 = 3.0;

fn input(came: *cam.Camera, delta_time: f32, windor: window.Window) !void {
    const windr = windor.window;
    const sense = 100;
    const mouse_delta = windr.getCursorPos();
    const mouse_vec = vec.init2(@floatCast(mouse_delta.xpos), @floatCast(mouse_delta.ypos));
    const delta = mouse_vec.vec - last.vec;
    last = mouse_vec;

    var dir = vec.Vec3.zeros();

    came.yaw -= delta[0] * delta_time * sense;
    came.pitch -= (delta[1] * delta_time * sense);

    if (windr.getKey(glfw.Key.w) == glfw.Action.press)
        dir.set_x(speed * delta_time);
    if (windr.getKey(glfw.Key.s) == glfw.Action.press)
        dir.set_x(-speed * delta_time);
    if (windr.getKey(glfw.Key.a) == glfw.Action.press)
        dir.set_z(-speed * delta_time);
    if (windr.getKey(glfw.Key.d) == glfw.Action.press)
        dir.set_z(speed * delta_time);
    if (windr.getKey(glfw.Key.space) == glfw.Action.press)
        dir.set_y(speed * delta_time);
    if (windr.getKey(glfw.Key.left_control) == glfw.Action.press)
        dir.set_y(-speed * delta_time);

    if (windr.getKey(glfw.Key.minus) == glfw.Action.press)
        speed += 1;
    if (windr.getKey(glfw.Key.equal) == glfw.Action.press)
        speed -= 1;

    // if (windr.getKey(glfw.Key.f) == glfw.Action.press) {
    //     index +%= 1;
    //     if (index >= 512) index = 0;
    //     prog.objects[index] = crab;
    //     prog.objects[index].pos = camera.eye;
    // }

    if (windr.getKey(glfw.Key.r) == glfw.Action.press) {
        if (prog.reload() == shader.ShaderErrors.failed_to_compile) {
            std.debug.print("shader failed to complie\n", .{});
        }
    }
    if (windr.getKey(glfw.Key.escape) == glfw.Action.press) {
        windr.setShouldClose(true);
    }

    const screnshot = windr.getKey(glfw.Key.p) == glfw.Action.press;
    if (screnshot and !pressed) {
        try windor.saveImg("screenshot.tga");
        pressed = true;
    } else if (!screnshot and pressed) {
        pressed = false;
    }

    camera.updateFps(dir);
}
