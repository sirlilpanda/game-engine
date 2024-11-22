const gl = @import("gl");
const std = @import("std");
const GlType = @import("gl_types.zig").GlType;
const DrawType = @import("gl_types.zig").DrawType;

const logger_vbo = std.log.scoped(.VBO);

pub const VBO = struct {
    const Self = @This();
    name: []const u8,
    id: gl.GLuint,
    target: gl.GLenum,
    size: gl.GLint,
    buffer_type: GlType,
    buffer_data: *const anyopaque,
    buffer_size: usize,
    draw_type: DrawType,

    pub fn init(name: []const u8, target: gl.GLenum, draw_type: DrawType, size: gl.GLint, buffer_type: GlType, buffer_data: *const anyopaque, buffer_size: usize) Self {
        logger_vbo.info("creating vbo with name {s}", .{name});
        const self = Self{
            .name = name,
            .id = undefined,
            .target = target,
            .size = size,
            .buffer_type = buffer_type,
            .buffer_data = buffer_data,
            .buffer_size = buffer_size,
            .draw_type = draw_type,
        };

        // logger_vbo.debug("vbo : {any}", .{self});
        return self;
    }

    pub fn delete(self: Self) void {
        gl.deleteBuffers(1, &self.id);
    }
};
