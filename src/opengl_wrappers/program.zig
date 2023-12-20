const gl = @import("gl");
const shader = @import("shader.zig");
const std = @import("std");
const uniform = @import("uniform.zig");
const Allocator = std.mem.Allocator;

const AMOUNT_OF_SHADERS = 8;

pub const Program = struct {
    const Self = @This();

    program_id: gl.GLuint,
    shaders: [AMOUNT_OF_SHADERS]shader.Shader, //does this really need to be dynamic
    shader_index: u8,

    pub fn init() Self {
        return Self{
            .program_id = gl.createProgram(),
            .shaders = undefined,
            .shader_index = 0,
        };
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
        std.debug.print("shaders : {}\n", .{s});
        std.debug.print("index : {}\n", .{self.shader_index});
        gl.attachShader(self.program_id, s.id);
    }

    pub fn addUniform(self: Self, name: []const u8) uniform.Uniform {
        return uniform.Uniform{
            .name = name,
            .location = gl.getUniformLocation(self.program_id, @ptrCast(name)),
        };
    }

    pub fn link(self: Self) void {
        gl.linkProgram(self.program_id);
    }

    // this was done so i can swap programs
    pub fn use(self: Self) void {
        gl.useProgram(self.program_id);
    }

    pub fn unload(self: Self) void {
        for (self.shaders) |s| {
            s.unload();
        }
        gl.deleteProgram(self.program_id);
    }
};
