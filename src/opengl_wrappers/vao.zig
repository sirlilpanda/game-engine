const gl = @import("gl");
const std = @import("std");
const VBO = @import("vbo.zig").VBO;
const GlType = @import("gl_types.zig").GlType;
const sizeofGLType = @import("gl_types.zig").sizeofGLType;
const asGLType = @import("gl_types.zig").asGLType;

const logger_vao = std.log.scoped(.VAO);

pub const VAO = struct {
    const Self = @This();

    id: gl.GLuint,
    index: u32,
    max_buffers: u32,
    // buffers: [vbo_amount]VBO,

    pub fn init(number_of_buffers: u32) Self {
        var vao = Self{
            .id = undefined,
            .index = 0,
            .max_buffers = number_of_buffers,
        };

        gl.genVertexArrays(1, @ptrCast(&vao.id));
        logger_vao.info("creating new vao with id {} and max buffers {}", .{ vao.id, vao.max_buffers });
        return vao;
    }

    pub fn bindVBO(self: *Self, vbo: *VBO) void {
        logger_vao.info("binding new vbo for vao with id {}", .{self.id});
        gl.genBuffers(1, @ptrCast(&vbo.id));
        logger_vao.info("created new vbo with id {}", .{vbo.id});
        // logger_vao.debug("vbo : \n{any}", .{vbo});

        gl.bindBuffer(vbo.target, vbo.id);
        logger_vao.debug("vbo with id {} bound to vao with id {}", .{ vbo.id, self.id });
        gl.namedBufferData(
            vbo.id,
            @as(
                isize,
                @intCast(
                    vbo.buffer_size * sizeofGLType(vbo.buffer_type),
                ),
            ),
            vbo.buffer_data,
            @intFromEnum(vbo.draw_type),
        );

        logger_vao.info(
            "binded new vbo {s} with draw type {} and id {} for vao with id {}",
            .{ vbo.name, vbo.draw_type, vbo.id, self.id },
        );
        if (vbo.target == gl.ARRAY_BUFFER) {
            logger_vao.info(
                "binded vbo {s} as array buffer to vao with id {} at index {}",
                .{ vbo.name, self.id, self.index },
            );
            gl.enableVertexArrayAttrib(self.id, self.index);
            gl.vertexAttribPointer(
                self.index,
                vbo.size,
                @intFromEnum(vbo.buffer_type),
                gl.FALSE,
                0,
                null,
            );
            self.index += 1;
        }
    }

    pub fn bindVAO(self: Self) void {
        gl.bindVertexArray(self.id);
    }

    pub fn delete(self: Self) void {
        gl.bindVertexArray(self.id);
        gl.deleteVertexArrays(1, @ptrCast(&self.id));
    }
};
