const gl = @import("gl");
const shader = @import("shader.zig");
const std = @import("std");
const uniform = @import("uniform.zig");
const cam = @import("camera.zig");
const obj = @import("../objects/object.zig");
const meta = @import("../utils/meta_wrapper.zig");
const ExampleUniform = @import("program_uniform.zig").ExampleUniform;
const Allocator = std.mem.Allocator;

const AMOUNT_OF_SHADERS = 8;

/// an abstraction on an opengl program
/// and example of the uniform type can be found in program_unifrom.zig
/// the amount of objects is just how many objects that the program will render
/// i will more then likely change that to an array list
pub fn Program(comptime unifrom_type: type, comptime amount_of_object: u32) type {
    // checks that the given uniform has the same functions as the ExampleUniform
    const prog_logger = std.log.scoped(.Program);
    if (comptime !meta.interfaceCheck(
        unifrom_type,
        ExampleUniform,
    )) @compileError("uniform type doesnt have correct traits");
    return struct {
        const Self = @This();
        /// the id of the program
        program_id: gl.GLuint,
        /// the shaders of the program
        shaders: [AMOUNT_OF_SHADERS]?shader.Shader, //does this really need to be dynamic
        shader_index: u8,
        /// the uniforms of the program
        uniforms: unifrom_type,
        /// the camera that the program uses for rendering
        camera: *cam.Camera,
        /// the objects that the program renders
        objects: [amount_of_object]?obj.Object,

        /// creates a new opengl program
        pub fn init() Self {
            prog_logger.info("creating new opengl program", .{});
            const self = Self{
                .program_id = gl.createProgram(),
                .shaders = [_]?shader.Shader{null} ** AMOUNT_OF_SHADERS,
                .shader_index = 0,
                .uniforms = undefined,
                .camera = undefined,
                .objects = [_]?obj.Object{null} ** amount_of_object,
            };

            prog_logger.info("created new opengl program with id {}", .{self.program_id});

            return self;
        }

        /// links the unifroms for program, this happens during the link function
        fn linkUniforms(self: *Self) void {
            prog_logger.info("linking uniforms to opengl program with id {}", .{self.program_id});
            var new_uni: unifrom_type = unifrom_type{};
            // this pretty much acts as a comptime hashmap
            inline for (std.meta.fields(unifrom_type)) |f| {
                if (f.type == uniform.Uniform)
                    self.addUniform(@constCast(&@field(new_uni, f.name)));
            }

            self.uniforms = new_uni;
        }

        /// add a vert and fragment shader
        pub fn addVertNFrag(self: *Self, allocator: Allocator, vert_path: []const u8, frag_path: []const u8) !void {
            const vert = shader.Shader.init(
                allocator,
                vert_path,
                gl.VERTEX_SHADER,
            ) catch |err| {
                prog_logger.err("attempting to load shader {s} got error {any}", .{ vert_path, err });
                return err;
            };
            const frag = shader.Shader.init(
                allocator,
                frag_path,
                gl.FRAGMENT_SHADER,
            ) catch |err| {
                prog_logger.err("attempting to load shader {s} got error {any}", .{ frag_path, err });
                return err;
            };

            self.loadShader(vert);
            self.loadShader(frag);
        }

        /// attaches the given shader to the program
        pub fn loadShader(self: *Self, s: shader.Shader) void {
            self.shaders[self.shader_index] = s;
            self.shader_index += 1;
            // std.debug.print("shaders : {}", .{s});
            // std.debug.print("index : {}", .{self.shader_index});
            gl.attachShader(self.program_id, s.id);
        }

        /// add a given uniform to the program
        pub fn addUniform(self: Self, uni: *uniform.Uniform) void {
            prog_logger.info("adding unifrom location with name {s} to opengl program with id {}", .{ uni.name, self.program_id });
            const loc = gl.getUniformLocation(self.program_id, @ptrCast(uni.name));
            uni.addLocation(loc);
        }

        /// links the program and the uniforms
        pub fn link(self: *Self) void {
            prog_logger.info("linking opengl program with id {}", .{self.program_id});
            gl.linkProgram(self.program_id);
            self.linkUniforms();
        }

        /// reloads the program shaders
        pub fn reload(self: *Self) !void {
            prog_logger.info("reloading opengl program with id {}", .{self.program_id});
            var prog = Self{
                .program_id = gl.createProgram(),
                .shaders = [_]?shader.Shader{null} ** AMOUNT_OF_SHADERS,
                .shader_index = 0,
                .uniforms = undefined,
                .camera = undefined,
                .objects = [_]?obj.Object{null} ** amount_of_object,
            };

            for (self.shaders) |s| {
                if (s) |sha| {
                    const shad = sha.reload() catch |err| {
                        if (err == shader.ShaderErrors.failed_to_compile) {
                            prog_logger.err("shader failed to complie {s}", .{sha.shader_path});
                            prog.unload();
                            return shader.ShaderErrors.failed_to_compile;
                        } else {
                            prog_logger.err("shader failed to complie {s} with error {any}", .{ sha.shader_path, err });
                            return err;
                        }
                    };
                    prog.loadShader(shad);
                }
            }
            self.unload();
            prog.link();
            prog.use();
            // // i think i could just mem copy this
            self.program_id = prog.program_id;
            self.shaders = prog.shaders;
            self.shader_index = prog.shader_index;
            self.uniforms = prog.uniforms;
            self.uniforms.reload();
        }

        // this was done so i can swap programs
        /// sets this program as the one to be used by opengl
        pub fn use(self: Self) void {
            // prog_logger.info("using opengl program with id {}", .{self.program_id});
            gl.useProgram(self.program_id);
        }

        /// unloads the program and all its shaders
        pub fn unload(self: Self) void {
            prog_logger.info("unloading opengl program with id {}", .{self.program_id});
            for (self.shaders) |s| {
                if (s) |sha| sha.unload();
            }
            gl.deleteProgram(self.program_id);
            self.uniforms.unload();
        }

        /// renders all objects
        pub fn renderAll(self: Self) void {
            for (self.objects) |object| {
                if (object) |o| self.uniforms.draw(self.camera, o);
            }
            // gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            // gl.flush();
        }

        /// only renders the object at the given index
        pub fn renderAtIndex(self: Self, index: u32) void {
            if (self.objects[index]) |object| self.uniforms.draw(self.camera, object);
        }

        // supprising very useful for skyboxes
        /// renders all objects but one at the given index
        pub fn renderAllButAtIndex(self: Self, index: u32) void {
            for (self.objects, 0..) |object, i| {
                if (object != null and i != index) {
                    self.uniforms.draw(self.camera, object.?);
                }
            }
        }
    };
}
