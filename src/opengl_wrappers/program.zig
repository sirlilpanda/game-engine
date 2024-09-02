const gl = @import("gl");
const shader = @import("shader.zig");
const std = @import("std");
const uniform = @import("uniform.zig");
const cam = @import("camera.zig");
const obj = @import("../objects/object.zig");

const Allocator = std.mem.Allocator;

const AMOUNT_OF_SHADERS = 8;
// you will fuck up your computer if you make this too big
// might do an array list in the future
pub fn Program(comptime unifrom_type: type, comptime amount_of_object: u32) type {
    return struct {
        const Self = @This();

        program_id: gl.GLuint,
        shaders: [AMOUNT_OF_SHADERS]?shader.Shader, //does this really need to be dynamic
        shader_index: u8,
        uniforms: unifrom_type,
        camera: *cam.Camera,
        objects: [amount_of_object]?obj.Object,

        pub fn init() Self {
            return Self{
                .program_id = gl.createProgram(),
                .shaders = [_]?shader.Shader{null} ** AMOUNT_OF_SHADERS,
                .shader_index = 0,
                .uniforms = undefined,
                .camera = undefined,
                .objects = [_]?obj.Object{null} ** amount_of_object,
            };
        }

        fn linkUniforms(self: *Self) void {
            var new_uni: unifrom_type = unifrom_type{};
            // this pretty much acts as a comptime hashmap
            inline for (std.meta.fields(unifrom_type)) |f| {
                if (f.type == uniform.Uniform)
                    self.addUniform(@constCast(&@field(new_uni, f.name)));
            }

            self.uniforms = new_uni;
        }

        pub fn add_vert_n_frag(self: *Self, allocator: Allocator, vert_path: []const u8, frag_path: []const u8) !void {
            const vert = try shader.Shader.init(
                allocator,
                vert_path,
                gl.VERTEX_SHADER,
            );
            const frag = try shader.Shader.init(
                allocator,
                frag_path,
                gl.FRAGMENT_SHADER,
            );

            self.load_shader(vert);
            self.load_shader(frag);
        }

        pub fn load_shader(self: *Self, s: shader.Shader) void {
            self.shaders[self.shader_index] = s;
            self.shader_index += 1;
            // std.debug.print("shaders : {}\n", .{s});
            // std.debug.print("index : {}\n", .{self.shader_index});
            gl.attachShader(self.program_id, s.id);
        }

        pub fn addUniform(self: Self, uni: *uniform.Uniform) void {
            const loc = gl.getUniformLocation(self.program_id, @ptrCast(uni.name));
            uni.addLocation(loc);
        }

        pub fn link(self: *Self) void {
            gl.linkProgram(self.program_id);
            self.linkUniforms();
        }

        pub fn reload(self: *Self) !void {
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
                    const shad = sha.reload();
                    if (shad == shader.ShaderErrors.failed_to_compile) {
                        std.debug.print("get unloaded egg\n", .{});
                        prog.unload();
                        return shader.ShaderErrors.failed_to_compile;
                    }
                    prog.load_shader(try shad);
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
        pub fn use(self: Self) void {
            gl.useProgram(self.program_id);
        }

        pub fn unload(self: Self) void {
            for (self.shaders) |s| {
                if (s) |sha| sha.unload();
            }
            gl.deleteProgram(self.program_id);
        }

        pub fn renderAll(self: Self) void {
            for (self.objects) |object| {
                if (object) |o| self.uniforms.draw(self.camera, o);
            }
        }

        pub fn renderAtIndex(self: Self, index: u32) void {
            if (self.objects[index]) |object| self.uniforms.draw(self.camera, object);
        }

        // supprising very useful for skyboxes
        pub fn renderAllButAtIndex(self: Self, index: u32) void {
            for (self.objects, 0..) |object, i| {
                if (object != null and i != index) {
                    self.uniforms.draw(self.camera, object.?);
                }
            }
        }
    };
}
