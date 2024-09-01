const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const mat = @import("math/matrix.zig");
const vec = @import("math/vec.zig");
const time = std.time;
const Tuple = std.meta.Tuple;
const Allocator = std.mem.Allocator;

const wrapper = @import("meta_wrapper.zig");
const shader = @import("opengl_wrappers/shader.zig");
const program = @import("opengl_wrappers/program.zig");
const render = @import("opengl_wrappers/render.zig");
const uni = @import("opengl_wrappers/uniform.zig");
const cam = @import("opengl_wrappers/camera.zig");
const Window = @import("opengl_wrappers/window.zig").Window;
const tex = @import("opengl_wrappers/texture.zig");
const cprint = @import("console_logger/coloured_text.zig");
const obj = @import("objects/object.zig");
const file = @import("file_loading/loadfile.zig");
const basic = @import("basic.zig");
const obj_loader = @import("objects/object_loader_service.zig");

const prog_error = error{
    program_not_in_provided_programs,
};

pub const App = struct {
    const Self = @This();
    window: Window,
    physic_objects: std.ArrayList(*obj.Object),
    obj_loader_service: obj_loader.ObjectService,
    camera: cam.Camera,
    alloc: Allocator, // just incase you want a global alloc
    delta_time: f32,
    timer: time.Timer,

    pub fn init(screen_width: u32, screen_hight: u32, alloc: Allocator) !Self {
        var self = Self{
            .window = undefined,
            .physic_objects = undefined,
            .obj_loader_service = try obj_loader.ObjectService.init(alloc),
            .camera = undefined,
            .alloc = alloc,
            .delta_time = 0,
            .timer = try time.Timer.start(),
        };

        self.window = try Window.init(screen_width, screen_hight);
        self.camera = cam.Camera.init(
            90,
            self.window.getAspectRatio(),
            0.1,
            10000,
            vec.init3(0, 0, 0),
        );

        gl.clearColor(0, 0, 0, 1);
        gl.enable(gl.DEPTH_TEST); // cull face
        gl.cullFace(gl.BACK); // cull back face

        return self;
    }

    pub fn shouldStop(self: *Self) bool {
        self.delta_time = @as(f32, @floatFromInt(self.timer.lap())) * 0.000000001;
        return self.window.shouldClose();
    }

    pub fn input(self: *Self) void {
        const sense = 1000;
        const delta = self.window.getCursorDelta();
        var speed: f32 = 100;
        var dir = vec.Vec3.zeros();
        self.camera.yaw -= delta.x() * self.delta_time * sense;
        self.camera.pitch -= (delta.y() * self.delta_time * sense);

        if (self.window.window.getKey(glfw.Key.w) == glfw.Action.press) {
            std.debug.print("w : pressed", .{});
            dir.set_x(speed * self.delta_time);
        }
        if (self.window.window.getKey(glfw.Key.s) == glfw.Action.press) {
            std.debug.print("s : pressed", .{});
            dir.set_x(-speed * self.delta_time);
        }
        if (self.window.window.getKey(glfw.Key.a) == glfw.Action.press) {
            std.debug.print("a : pressed", .{});
            dir.set_z(-speed * self.delta_time);
        }
        if (self.window.window.getKey(glfw.Key.d) == glfw.Action.press) {
            std.debug.print("d : pressed", .{});
            dir.set_z(speed * self.delta_time);
        }
        if (self.window.window.getKey(glfw.Key.space) == glfw.Action.press) {
            std.debug.print("space : pressed", .{});
            dir.set_y(speed * self.delta_time);
        }
        if (self.window.window.getKey(glfw.Key.left_control) == glfw.Action.press) {
            std.debug.print("left_control : pressed", .{});
            dir.set_y(-speed * self.delta_time);
        }

        if (self.window.window.getKey(glfw.Key.escape) == glfw.Action.press) {
            self.window.window.setShouldClose(true);
        }

        self.camera.updateFps(dir);
    }
    // current program
    // camera
    // render_thread
    // physics_thread
    // loader
    // alloc

    pub fn free(self: *Self) void {
        self.window.deinit();
        self.obj_loader_service.deinit();
    }
};

// const App = @import("app.zig");
// const basic = @import("basic.zig");
// const std = @import("std");
// const shader = @import("/opengl_wrappers/shader.zig");
// const tex = @import("opengl_wrappers/texture.zig");
// const gl = @import("gl");
// const glfw = @import("mach-glfw");

// pub fn main() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();

//     var app = try App.App.init(
//         1920,
//         1080,
//         allocator,
//     );

//     var basic_program_texture = try basic.createBasicProgramWTexture(allocator);
//     basic_program_texture.camera = &app.camera;

//     basic_program_texture.objects[0] = try app.obj_loader_service.load("objects/Crab.obj", .obj);
//     _ = try tex.Texture.init(allocator, "textures/Crab_D.tga");

//     std.debug.print("obj : {any}\n", .{basic_program_texture.objects[0]});

//     while (!app.shouldStop()) {
//         app.input();

//         basic_program_texture.renderAll();

//         std.time.sleep(10000000);
//     }

//     app.free();
// }
