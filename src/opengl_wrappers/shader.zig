const gl = @import("gl");
const std = @import("std");

const Allocator = std.mem.Allocator;

const std_file_size = 2000;

pub fn loadfile(allocator: Allocator, filename: []const u8) ![]u8 {
    const shader_file: std.fs.File = try std.fs.cwd().openFile(filename, .{});
    const file_end = try shader_file.getEndPos();
    const data = try allocator.alloc(u8, @as(usize, file_end + 1));
    const data_read = try shader_file.readAll(data);
    _ = data_read;
    // std.debug.print("read : {}\n", .{data_read});
    // std.debug.print("len : {}\n", .{data.len});
    data[file_end] = 0;
    return data;
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

const quiet: bool = true;

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
    shader_path: []const u8,
    allocator: Allocator,
    shader_type: ShaderTypes,
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
            .shader_path = shader_path,
            .allocator = allocator,
            .shader_type = shader_type,
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

    pub fn reload(self: Self) !Self {
        return try init(self.allocator, self.shader_path, self.shader_type);
    }

    pub fn unload(self: Self) void {
        gl.deleteShader(self.id);
    }
};
