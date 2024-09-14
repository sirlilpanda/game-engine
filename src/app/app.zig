const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const mat = @import("../math/matrix.zig");
const vec = @import("../math/vec.zig");
const time = std.time;
const Tuple = std.meta.Tuple;
const Allocator = std.mem.Allocator;

const wrapper = @import("../utils/meta_wrapper.zig");
const TimeStamp = @import("../utils/time_stamp.zig").TimeStamp;
const shader = @import("../opengl_wrappers/shader.zig");
const program = @import("../opengl_wrappers/program.zig");
const render = @import("../opengl_wrappers/render.zig");
const uni = @import("../opengl_wrappers/uniform.zig");
const cam = @import("../opengl_wrappers/camera.zig");
const Window = @import("../opengl_wrappers/window.zig").Window;
const tex = @import("../opengl_wrappers/texture.zig");
const cprint = @import("../console_logger/coloured_text.zig");
const obj = @import("../objects/object.zig");
const file = @import("../file_loading/loadfile.zig");
const basic = @import("basic_program.zig");
const obj_loader = @import("../objects/object_loader_service.zig");

const prog_error = error{
    program_not_in_provided_programs,
};
var speed: f32 = 10;

/// the App is where everything lives the GLFW window, the opengl programs
/// the camera, an allocator, etc. basically this is the final abstraction
/// layer
pub fn App(comptime Programs: type) type {
    return struct {
        const Self = @This();

        /// window size for the low pass filter, its 256 since this allows a u8 to roll over
        const win_size = 256;
        /// a moving average filter to slow low pass the high freqs
        fps_low_pass_window: @Vector(win_size, f32) = @splat(0),
        /// the current index of where the window is
        fps_low_pass_window_index: u8 = 0,
        /// the main window
        window: Window,
        /// the struct of where are the opengl programs is stored
        programs: Programs,
        /// a list of physics objects currently not implemented
        physic_objects: std.ArrayList(*obj.Object),
        /// a service for loading and caching objects good flyweight pattern
        obj_loader_service: obj_loader.ObjectService,
        /// due to alot of the opengl programs using the same camera one can be stored here
        camera: cam.Camera,
        /// a global GPA allocator in case you need it
        alloc: Allocator,
        /// the time differnce between the last shouldStop call, since this should be directly related to frame rate
        delta_time: f32,
        /// the timer for getting the delta time
        timer: time.Timer,

        // [TODO] work out how to write this
        // fn check_prog_struct(self: Self) void {
        //     inline for (std.meta.fields(Programs)) |f| {
        //     }
        // }

        /// creates a new window with the given screen width and height
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
                100000,
                vec.init3(0, 0, 0),
            );

            gl.clearColor(0, 0, 0, 1);
            gl.enable(gl.DEPTH_TEST); // cull face
            gl.cullFace(gl.BACK); // cull back face

            self.window.hideCursor();

            return self;
        }

        /// gets the current fps
        pub fn fps(self: Self) f32 {
            return @reduce(.Add, self.fps_low_pass_window);
        }

        /// to check if the current window should be closed
        pub fn shouldStop(self: *Self) bool {
            self.delta_time = @as(f32, @floatFromInt(self.timer.lap())) * 0.000000001;
            self.fps_low_pass_window[self.fps_low_pass_window_index] = (1 / (self.delta_time)) / win_size;
            self.fps_low_pass_window_index +%= 1;
            return self.window.shouldClose();
        }

        /// program name must be what you called it with the struct you passed into the app
        pub fn changeProgram(self: Self, program_name: []const u8) !void {
            inline for (std.meta.fields(Programs)) |f| {
                if (wrapper.trait_check(f.type, "use")) {
                    @field(self.programs, program_name).use();
                } else {
                    return prog_error.program_not_in_provided_programs;
                }
            }
        }

        /// renders all objects that are attached to all programs
        pub fn render(self: Self) void {
            gl.clear(gl.DEPTH_BUFFER_BIT);

            inline for (std.meta.fields(Programs)) |f| {
                if (wrapper.trait_check(f.type, "use")) {
                    @field(self.programs, f.name).use();
                } else {
                    std.debug.print("program doesnt have function use", .{});
                    std.process.exit(1);
                }
                if (wrapper.trait_check(f.type, "renderAll")) {
                    @field(self.programs, f.name).renderAll();
                } else {
                    std.debug.print("program doesnt have function renderAll", .{});
                    std.process.exit(1);
                }
            }
            self.window.swapBuffer();

            // gl.flush();
        }

        /// gets the current and updates the camera, also handles screenshots, and program reloading
        /// this will be replaced in the future with some form of input struct, following the command pattern
        pub fn input(self: *Self) void {
            // std.debug.print("delta time {}\n", .{self.delta_time});
            glfw.pollEvents();
            const sense = 50.0;
            const delta = self.window.getCursorDelta();
            var dir = vec.Vec3.zeros();
            self.camera.yaw -= delta.x() * self.delta_time * sense;
            self.camera.pitch -= (delta.y() * self.delta_time * sense);

            if (self.window.window.getKey(glfw.Key.w) == glfw.Action.press) {
                // std.debug.print("w : pressed\n", .{});
                dir.set_x(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.s) == glfw.Action.press) {
                // std.debug.print("s : pressed\n", .{});
                dir.set_x(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.a) == glfw.Action.press) {
                // std.debug.print("a : pressed\n", .{});
                dir.set_z(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.d) == glfw.Action.press) {
                // std.debug.print("d : pressed\n", .{});
                dir.set_z(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.space) == glfw.Action.press) {
                // std.debug.print("space : pressed\n", .{});
                dir.set_y(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.left_control) == glfw.Action.press) {
                // std.debug.print("left_control : pressed\n", .{});
                dir.set_y(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.minus) == glfw.Action.press)
                speed += 1;
            if (self.window.window.getKey(glfw.Key.equal) == glfw.Action.press)
                speed -= 1;

            self.camera.updateFps(dir);

            if (self.window.window.getKey(glfw.Key.r) == glfw.Action.press) {
                inline for (std.meta.fields(Programs)) |f| {
                    if (@field(self.programs, f.name).reload() == shader.ShaderErrors.failed_to_compile) {
                        std.debug.print("shader failed to complie\n", .{});
                    }
                }
            }

            if (self.window.window.getKey(glfw.Key.escape) == glfw.Action.press) {
                self.window.window.setShouldClose(true);
            }

            if (self.window.window.getKey(glfw.Key.p) == glfw.Action.press) {
                const now = TimeStamp.current();

                const filename = std.fmt.allocPrint(self.alloc, "screen_shot-{name}.bmp", .{now}) catch "";
                defer self.alloc.free(filename);
                if (std.fs.cwd().access(filename, .{}) == std.fs.Dir.AccessError.FileNotFound) {
                    std.debug.print("name : {s}\n", .{filename});
                    std.debug.print("screenshot\n", .{});
                    self.window.saveImg(filename) catch |err| {
                        std.debug.print("screenshot error : {any}\n", .{err});
                    };
                } else {
                    std.debug.print("file {s} already exists\n", .{filename});
                }
            }
        }

        /// frees all the programs and unloads other services
        pub fn free(self: *Self) void {
            inline for (std.meta.fields(Programs)) |f| {
                @field(self.programs, f.name).unload();
            }
            self.window.deinit();
            self.obj_loader_service.deinit();
        }
    };
}

/// struct for basic progams, this only only contains
/// the basicProgramTex type which supports phong lighting
/// and texture
pub const BasicPrograms = struct {
    basic_program_texture: basic.BasicProgramTex,
    // basic_program: basic.BasicProgram,
};

/// the type of a basic app that uses the BasicProgramTex program
pub const BasicApp = App(BasicPrograms);
