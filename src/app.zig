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

pub fn App(comptime Programs: type) type {
    return struct {
        const Self = @This();
        window: Window,
        programs: Programs,
        physic_objects: std.ArrayList(*obj.Object),
        obj_loader_service: obj_loader.ObjectService,
        camera: cam.Camera,
        alloc: Allocator, // just incase you want a global alloc
        delta_time: f32,
        timer: time.Timer,

        // [TODO] work out how to write this
        // fn check_prog_struct(self: Self) void {
        //     inline for (std.meta.fields(Programs)) |f| {
        //     }
        // }

        pub fn init(screen_width: u32, screen_hight: u32, alloc: Allocator, programs: Programs) !Self {
            var self = Self{
                .window = undefined,
                .programs = programs,
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

            self.window.hideCursor();

            return self;
        }

        pub fn shouldStop(self: *Self) bool {
            self.delta_time = @as(f32, @floatFromInt(self.timer.lap())) * 0.000000001;
            return self.window.shouldClose();
        }

        // program name must be what you called it with the struct you passed into the app
        pub fn change_program(self: Self, program_name: []const u8) !void {
            inline for (std.meta.fields(Programs)) |f| {
                if (wrapper.trait_check(f.type, "use")) {
                    @field(self.programs, program_name).use();
                } else {
                    return prog_error.program_not_in_provided_programs;
                }
            }
        }

        pub fn render(self: Self) void {
            gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

            inline for (std.meta.fields(Programs)) |f| {
                @field(self.programs, f.name).use();
                @field(self.programs, f.name).renderAll();
            }
            self.window.swapBuffer();

            gl.flush();
        }

        pub fn input(self: *Self) void {
            std.debug.print("delta time {}\n", .{self.delta_time});
            glfw.pollEvents();
            const sense = 10.0;
            const delta = self.window.getCursorDelta();
            var speed: f32 = 10;
            var dir = vec.Vec3.zeros();
            self.camera.yaw -= delta.x() * self.delta_time * sense;
            self.camera.pitch -= (delta.y() * self.delta_time * sense);

            if (self.window.window.getKey(glfw.Key.w) == glfw.Action.press) {
                std.debug.print("w : pressed\n", .{});
                dir.set_x(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.s) == glfw.Action.press) {
                std.debug.print("s : pressed\n", .{});
                dir.set_x(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.a) == glfw.Action.press) {
                std.debug.print("a : pressed\n", .{});
                dir.set_z(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.d) == glfw.Action.press) {
                std.debug.print("d : pressed\n", .{});
                dir.set_z(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.space) == glfw.Action.press) {
                std.debug.print("space : pressed\n", .{});
                dir.set_y(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.left_control) == glfw.Action.press) {
                std.debug.print("left_control : pressed\n", .{});
                dir.set_y(-speed * self.delta_time);
            }
            // std.debug.print("dir", .{});
            // if (self.window.getKey(glfw.Key.minus) == glfw.Action.press)
            //     speed += 1;
            // if (self.window.getKey(glfw.Key.equal) == glfw.Action.press)
            //     speed -= 1;

            // if (self.window.getKey(glfw.Key.r) == glfw.Action.press) {
            //     if (self.prog.reload() == shader.ShaderErrors.failed_to_compile) {
            //         std.debug.print("shader failed to complie\n", .{});
            //     }
            // }

            if (self.window.window.getKey(glfw.Key.escape) == glfw.Action.press) {
                self.window.window.setShouldClose(true);
            }

            self.camera.updateFps(dir);

            // if (self.window.getKey(glfw.Key.p) == glfw.Action.up) ;
            // if (screnshot and !pressed) {
            //     try windor.saveImg("screenshot.tga");
            //     pressed = true;
            // } else if (!screnshot and pressed) {
            //     pressed = false;
            // }

            // return dir;
        }

        // current program
        // camera
        // render_thread
        // physics_thread
        // loader
        // alloc

        pub fn free(self: *Self) void {
            self.window.deinit();
            inline for (std.meta.fields(Programs)) |f| {
                @field(self.programs, f.name).unload();
            }
            self.obj_loader_service.deinit();
        }
    };
}

pub const BasicPrograms = struct {
    basic_program_texture: basic.BasicProgramTex,
    // basic_program: basic.BasicProgram,
};

pub const BasicApp = App(BasicPrograms);
