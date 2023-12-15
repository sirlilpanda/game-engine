const gl = @import("gl");
const std = @import("std");
const Allocator = std.mem.Allocator;

const std_file_size = 2000;

pub fn loadfile(allocator: Allocator, filename: []const u8) ![]u8 {
    const buffer = try allocator.alloc(u8, std_file_size);
    defer allocator.free(buffer);
    const f_slice = try std.fs.cwd().readFile(filename, buffer);
    const file_len = f_slice.len;
    const file = try allocator.alloc(u8, file_len + 1);
    std.mem.copy(u8, file, buffer[0..file_len]);
    file[file_len] = 0;
    return file;
}

pub fn createShaderProgram(vertex_shader_path: []const u8, fragment_shader_path: []const u8) !gl.GLuint {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const vertex: Shader = try Shader.init(allocator, vertex_shader_path, gl.VERTEX_SHADER);
    const frag: Shader = try Shader.init(allocator, fragment_shader_path, gl.FRAGMENT_SHADER);

    var program = gl.createProgram();
    gl.attachShader(program, vertex.id);
    gl.attachShader(program, frag.id);
    gl.linkProgram(program);
    gl.useProgram(program);

    return program;
}

const quiet: bool = false;

pub const ShaderErrors = error{
    failed_to_compile,
};

pub const Shader = struct {
    const Self = @This();

    id: gl.GLuint,

    pub fn init(allocator: Allocator, shader_path: []const u8, shader_type: gl.GLuint) !Self {
        const shaderfile: []u8 = try loadfile(allocator, shader_path);
        defer allocator.free(shaderfile);

        if (!quiet) std.debug.print("\nfile : {s}\n", .{shaderfile});

        var shader_id = gl.createShader(shader_type);
        gl.shaderSource(shader_id, 1, @ptrCast(&shaderfile), null);
        gl.compileShader(shader_id);
        try chech_status(shader_id);
        std.debug.print("check : {any}\n", .{chech_status(shader_id)});

        return Self{ .id = shader_id };
    }

    fn chech_status(shader_id: gl.GLuint) ShaderErrors!void {
        var status: gl.GLint = undefined;
        gl.getShaderiv(shader_id, gl.COMPILE_STATUS, &status);
        if (status == gl.FALSE) return ShaderErrors.failed_to_compile;
    }

    pub fn unload(self: Self) void {
        gl.deleteShader(self.id);
    }
};
