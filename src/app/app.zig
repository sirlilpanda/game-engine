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
const obj = @import("../objects/object.zig");
const file = @import("../file_loading/loadfile.zig");
const basic = @import("basic_program.zig");
const obj_loader = @import("../objects/object_loader_service.zig");
const tex_loader = @import("../textures/texture_loader_service.zig");
const prog_2d = @import("2d_program.zig");
const prog_text = @import("text_program.zig");
const prog_error = error{
    program_not_in_provided_programs,
};
var speed: f32 = 10;

const app_logger = std.log.scoped(.App);

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
        /// a service for loading and caching textures good flyweight pattern
        texture_loader_service: tex_loader.TextureService,
        /// due to alot of the opengl programs using the same camera one can be stored here
        camera: cam.Camera,
        /// a global GPA allocator in case you need it
        alloc: Allocator,
        /// the time differnce between the last shouldStop call, since this should be directly related to frame rate
        delta_time: f32,
        /// the timer for getting the delta time
        timer: time.Timer,
        /// for making sure inputs to get pushed to much
        input_lap: i64 = 0,
        /// text renderer
        text_rendering_program: prog_text.BasicProgramText,
        /// text to render
        text: std.ArrayList([]const u8),

        const fps_error_str = "fps :             ";

        /// creates a new window with the given screen width and height
        pub fn init(screen_width: u32, screen_hight: u32, alloc: Allocator, programs: Programs) !Self {
            app_logger.info("attempting to create app", .{});
            var self = Self{
                .window = undefined,
                .programs = programs,
                .physic_objects = undefined,
                .obj_loader_service = obj_loader.ObjectService.init(alloc),
                .texture_loader_service = tex_loader.TextureService.init(alloc),
                .camera = undefined,
                .alloc = alloc,
                .delta_time = 0,
                .timer = try time.Timer.start(),
                .text_rendering_program = undefined,
                .text = std.ArrayList([]const u8).init(alloc),
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

            self.text_rendering_program = prog_text.createBasicTextProgram(alloc) catch |err| {
                app_logger.err("got error creating the text rendering program, error : {any}", .{err});
                return err;
            };

            self.text_rendering_program.uniforms.font_texture_atlas = self.texture_loader_service.load("textures/font_atlas.bmp") catch |err| {
                app_logger.err("couldnt load font atlas got error : {any}", .{err});
                return err;
            };

            self.text_rendering_program.uniforms.addAspectRatio(self.window.getAspectRatio());
            try self.text.append(fps_error_str);

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

            // always renders text at the end so its on top
            self.text_rendering_program.use();
            for (self.text.items, 0..) |string, line| {
                self.text_rendering_program.uniforms.render_text(string, line);
            }

            self.window.swapBuffer();

            // gl.flush();
        }

        /// gets the current and updates the camera, also handles screenshots, and program reloading
        /// this will be replaced in the future with some form of input struct, following the command pattern
        pub fn input(self: *Self) void {
            glfw.pollEvents();
            const sense = 50.0;
            const delta = self.window.getCursorDelta();
            var dir = vec.Vec3.zeros();
            self.camera.yaw -= delta.x() * self.delta_time * sense;
            self.camera.pitch -= (delta.y() * self.delta_time * sense);

            if (self.window.window.getKey(glfw.Key.w) == glfw.Action.press) {
                dir.set_x(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.s) == glfw.Action.press) {
                dir.set_x(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.a) == glfw.Action.press) {
                dir.set_z(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.d) == glfw.Action.press) {
                dir.set_z(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.space) == glfw.Action.press) {
                dir.set_y(speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.left_control) == glfw.Action.press) {
                dir.set_y(-speed * self.delta_time);
            }
            if (self.window.window.getKey(glfw.Key.minus) == glfw.Action.press)
                speed += 1;
            if (self.window.window.getKey(glfw.Key.equal) == glfw.Action.press)
                speed -= 1;

            self.camera.updateFps(dir);

            if ((self.window.window.getKey(glfw.Key.left_alt) == glfw.Action.press or
                self.window.window.getKey(glfw.Key.right_alt) == glfw.Action.press) and
                self.window.window.getKey(glfw.Key.F4) == glfw.Action.press)
            {
                app_logger.info("[INFO] closing window with alt-f4", .{});
                self.window.window.setShouldClose(true);
            }

            const buff: []const u8 = std.fmt.allocPrint(self.alloc, "fps:{d:.2}", .{self.fps()}) catch |err| blk: {
                app_logger.err("failed to alloc print fps got error : {any}", .{err});
                break :blk fps_error_str;
            };

            std.mem.copyForwards(u8, @constCast(self.text.items[0]), buff);

            self.alloc.free(buff);

            if (self.input_lap + 1 <= time.timestamp()) {
                if (self.window.window.getKey(glfw.Key.r) == glfw.Action.press) {
                    inline for (std.meta.fields(Programs)) |f| {
                        if (@field(self.programs, f.name).reload() == shader.ShaderErrors.failed_to_compile) {
                            app_logger.err("shader failed to complie", .{});
                        }
                    }
                }

                if (self.window.window.getKey(glfw.Key.p) == glfw.Action.press) {
                    const now = TimeStamp.current();

                    const filename = std.fmt.allocPrint(self.alloc, "screen_shot-{name}.bmp", .{now}) catch "";
                    defer self.alloc.free(filename);
                    if (std.fs.cwd().access(filename, .{}) == std.fs.Dir.AccessError.FileNotFound) {
                        self.window.saveImg(filename) catch |err| {
                            app_logger.err("screenshot error : {any}", .{err});
                        };
                    } else {
                        app_logger.warn("file {s} already exists", .{filename});
                    }
                }
                self.input_lap = time.timestamp();
            }
        }

        /// frees all the programs and unloads other services
        pub fn free(self: *Self) void {
            self.obj_loader_service.deinit();
            self.texture_loader_service.deinit();
            self.text_rendering_program.unload();
            app_logger.info("unloading app", .{});
            inline for (std.meta.fields(Programs)) |f| {
                @field(self.programs, f.name).unload();
            }
            app_logger.info("unloading app programs", .{});
            self.window.deinit();
            self.text.deinit();
            app_logger.info("unloaded app", .{});
        }
    };
}

/// struct for basic progams, this only only contains
/// the basicProgramTex type which supports phong lighting
/// and texture
pub const BasicPrograms = struct {
    basic_program_texture: basic.BasicProgramTex,
    basic_program_2d: prog_2d.BasicProgram2D,
};

/// the type of a basic app that uses the BasicProgramTex program
pub const BasicApp = App(BasicPrograms);
