const gl = @import("gl");
const std = @import("std");

const Allocator = std.mem.Allocator;

const shader_logger = std.log.scoped(.Shader);

/// loads the current file with the given allocator
pub fn loadfile(allocator: Allocator, filename: []const u8) ![]u8 {
    const file = std.fs.cwd().openFile(filename, .{});
    var buffer: [256]u8 = undefined;

    if (file == std.fs.File.OpenError.FileNotFound) {
        shader_logger.err("file : {s} not found", .{try std.fs.cwd().realpath(filename, &buffer)});
    }

    const shader_file: std.fs.File = try file;
    defer shader_file.close();
    const file_end = try shader_file.getEndPos();
    const data = try allocator.alloc(u8, @as(usize, file_end + 1));
    const data_read = try shader_file.readAll(data);
    shader_logger.debug("read {} bytes", .{data_read});
    // std.debug.print("read : {}", .{data_read});
    // std.debug.print("len : {}", .{data.len});
    data[file_end] = 0;
    return data;
}

/// just a defualt name for if the shader is static
pub const static_shader_name = "static";

/// shaders errors
pub const ShaderErrors = error{
    failed_to_compile,
    static_shader_cant_reload,
};

/// all the differnt shader type
pub const ShaderTypes = enum {
    vertex,
    frag,
    compute,
    geometry,
    tesslation_control_shader,
    tesslation_eval_shader,
};

/// the shader struct
pub const Shader = struct {
    const Self = @This();
    // the path to the shdaer
    shader_path: []const u8,
    // the allocator that the shader uses when reloading its self
    allocator: Allocator,
    // the type of the shader
    shader_type: ShaderTypes,
    // the shader id
    id: gl.GLuint,

    /// creates a new shader from the given shader path
    pub fn init(allocator: Allocator, shader_path: []const u8, shader_type: ShaderTypes) !Self {
        shader_logger.info("loading shader {s}, as {s}", .{ shader_path, @tagName(shader_type) });
        const shaderfile: []u8 = loadfile(allocator, shader_path) catch |err| {
            shader_logger.err("failed to load shader file {s}, got error {any}", .{ shader_path, err });
            return err;
        };

        defer allocator.free(shaderfile);

        const shader_id = gl.createShader(switch (shader_type) {
            ShaderTypes.vertex => gl.VERTEX_SHADER,
            ShaderTypes.frag => gl.FRAGMENT_SHADER,
            ShaderTypes.compute => gl.COMPUTE_SHADER,
            ShaderTypes.geometry => gl.GEOMETRY_SHADER,
            ShaderTypes.tesslation_control_shader => gl.TESS_CONTROL_SHADER,
            ShaderTypes.tesslation_eval_shader => gl.TESS_EVALUATION_SHADER,
        });

        gl.shaderSource(shader_id, 1, @ptrCast(&shaderfile), null);
        gl.compileShader(shader_id);

        const self = Self{
            .id = shader_id,
            .shader_path = shader_path,
            .allocator = allocator,
            .shader_type = shader_type,
        };
        try checkStatus(self, allocator);
        return self;
    }

    /// creates a new shader, but doesnt load in the file, instead accpets an loaded file
    pub fn initWithFile(allocator: Allocator, shader_file: []const u8, shader_type: ShaderTypes) !Self {
        shader_logger.info("loading shader static, as {s}", .{@tagName(shader_type)});

        const shader_id = gl.createShader(switch (shader_type) {
            ShaderTypes.vertex => gl.VERTEX_SHADER,
            ShaderTypes.frag => gl.FRAGMENT_SHADER,
            ShaderTypes.compute => gl.COMPUTE_SHADER,
            ShaderTypes.geometry => gl.GEOMETRY_SHADER,
            ShaderTypes.tesslation_control_shader => gl.TESS_CONTROL_SHADER,
            ShaderTypes.tesslation_eval_shader => gl.TESS_EVALUATION_SHADER,
        });

        gl.shaderSource(shader_id, 1, @ptrCast(&shader_file), null);
        gl.compileShader(shader_id);

        const self = Self{
            .id = shader_id,
            .shader_path = static_shader_name,
            .allocator = allocator,
            .shader_type = shader_type,
        };
        try checkStatus(self, allocator);
        return self;
    }

    /// checks to see if any complie error has occured
    fn checkStatus(self: Self, allocator: Allocator) !void {
        var status: gl.GLint = undefined;
        gl.getShaderiv(self.id, gl.COMPILE_STATUS, &status);
        shader_logger.info("checking shader {s} status ", .{self.shader_path});
        if (status == gl.FALSE) {
            var info_log_len: gl.GLsizei = undefined;
            gl.getShaderiv(self.id, gl.INFO_LOG_LENGTH, &info_log_len);
            const error_string: []u8 = try allocator.alloc(u8, @as(usize, @intCast(info_log_len)));
            defer allocator.free(error_string);
            gl.getShaderInfoLog(self.id, info_log_len, null, @ptrCast(&error_string[0]));
            shader_logger.err("shader {s} got error when compling : {s}", .{ self.shader_path, error_string });
            return ShaderErrors.failed_to_compile;
        }
        shader_logger.info("shader {s} complied successfully", .{self.shader_path});
    }

    /// calls when the shader file is reloaded
    pub fn reload(self: Self) !Self {
        if (std.mem.eql(u8, self.shader_path, static_shader_name)) {
            shader_logger.err("attempted to reload static shader", .{});
            return ShaderErrors.static_shader_cant_reload;
        } else {
            shader_logger.info("reloading shader {s}", .{self.shader_path});
            return try init(self.allocator, self.shader_path, self.shader_type);
        }
    }

    /// unloads the shader
    pub fn unload(self: Self) void {
        shader_logger.info("unloading shader {s}", .{self.shader_path});
        gl.deleteShader(self.id);
    }
};
