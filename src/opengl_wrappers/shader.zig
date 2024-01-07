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

pub const ShaderTypes = enum {
    vertex,
    frag,
    compute,
    geometry,
    tesslation_control_shader,
    tesslation_eval_shader,
};

// TODO add unifroms to the struct
// idea: dynamiclly add the uniforms as you parse the file
pub const Shader = struct {
    const Self = @This();

    id: gl.GLuint,

    pub fn init(allocator: Allocator, shader_path: []const u8, shader_type: ShaderTypes) !Self {
        const shaderfile: []u8 = try loadfile(allocator, shader_path);
        defer allocator.free(shaderfile);

        if (!quiet) std.debug.print("\nfile : {s}\n", .{shaderfile});

        var shader_id = gl.createShader(switch (shader_type) {
            ShaderTypes.vertex => gl.VERTEX_SHADER,
            ShaderTypes.frag => gl.FRAGMENT_SHADER,
            ShaderTypes.compute => gl.COMPUTE_SHADER,
            ShaderTypes.geometry => gl.GEOMETRY_SHADER,
            ShaderTypes.tesslation_control_shader => gl.TESS_CONTROL_SHADER,
            ShaderTypes.tesslation_eval_shader => gl.TESS_EVALUATION_SHADER,
        });

        gl.shaderSource(shader_id, 1, @ptrCast(&shaderfile), null);
        gl.compileShader(shader_id);
        try chech_status(shader_id, allocator);

        return Self{
            .id = shader_id,
        };
    }

    fn chech_status(shader_id: gl.GLuint, allocator: Allocator) !void {
        var status: gl.GLint = undefined;
        gl.getShaderiv(shader_id, gl.COMPILE_STATUS, &status);
        if (status == gl.FALSE) {
            var info_log_len: gl.GLsizei = undefined;
            gl.getShaderiv(shader_id, gl.INFO_LOG_LENGTH, &info_log_len);
            const error_string: []u8 = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
            defer allocator.free(error_string);
            gl.getShaderInfoLog(shader_id, info_log_len, null, @ptrCast(&error_string[0]));
            std.debug.print("[ERROR] : {s}\n", .{error_string});
            return ShaderErrors.failed_to_compile;
        }
    }

    pub fn unload(self: Self) void {
        gl.deleteShader(self.id);
    }
};
