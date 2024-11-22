const gl = @import("gl");
const file = @import("../file_loading/loadfile.zig");
const std = @import("std");
const VAO = @import("vao.zig").VAO;
const VBO = @import("vbo.zig").VBO;
const DrawType = @import("gl_types.zig").DrawType;

const logger_renderer = std.log.scoped(.Renderer);

const Allocator = std.mem.Allocator;

pub const Renderer = struct {
    const Self = @This();

    vertex_array_object: VAO,
    vertex_buffer_objects: []VBO,
    number_elements: usize,
    alloc: Allocator,

    pub fn init(allocator: Allocator, buffers: []VBO) Self {
        var self = Self{
            .vertex_array_object = VAO.init(@intCast(buffers.len)),
            .number_elements = 0,
            .vertex_buffer_objects = buffers,
            .alloc = allocator,
        };
        logger_renderer.info("creating new renderer with id {} and {} buffers", .{ self.vertex_array_object.id, buffers.len });
        self.vertex_array_object.bindVAO();
        for (buffers) |vbo| {
            self.vertex_array_object.bindVBO(@constCast(&vbo));
            if (vbo.target == gl.ELEMENT_ARRAY_BUFFER) {
                self.number_elements = vbo.buffer_size;
            }
        }

        return self;
    }

    pub fn destroy(self: Self) void {
        logger_renderer.info("deleting vao with id {}", .{
            self.vertex_array_object.id,
        });

        for (self.vertex_buffer_objects) |vbo| {
            vbo.delete();
        }
        self.alloc.free(self.vertex_buffer_objects);
        self.vertex_array_object.delete();
    }

    pub fn drawElementsTriangles(self: Self) void {
        self.vertex_array_object.bindVAO();
        gl.drawElements(
            gl.TRIANGLES,
            @as(gl.GLsizei, @intCast(self.number_elements)),
            gl.UNSIGNED_INT,
            null,
        );
    }

    pub fn drawElementsPatches(self: Self) void {
        self.vertex_array_object.bindVAO();
        gl.drawElements(
            gl.PATCHES,
            @as(gl.GLsizei, @intCast(self.number_elements)),
            gl.UNSIGNED_INT,
            null,
        );
    }

    pub fn drawInstanced(self: Self) void {
        self.vertex_array_object.bindVAO();
        gl.drawArraysInstanced(
            gl.TRIANGLE_STRIP,
            0,
            @as(gl.GLsizei, @intCast(self.number_elements)),
            1,
        );
    }
};

pub fn objectRenderer(allocator: Allocator, dat: file.ObjectFile) !Renderer {
    const buffers = allocator.alloc(VBO, 4) catch |err| {
        logger_renderer.err("could not allocate vbos in objectRenderer got error {any}", .{err});
        return err;
    };
    buffers[0] = VBO.init(
        "vertex_buffer_object",
        gl.ARRAY_BUFFER,
        .static,
        3,
        .float,
        @ptrCast(&dat.verts[0]),
        dat.verts.len,
    );
    buffers[1] = VBO.init(
        "vertex_normal_object",
        gl.ARRAY_BUFFER,
        .static,
        3,
        .float,
        @ptrCast(&dat.normals[0]),
        dat.normals.len,
    );
    buffers[2] = VBO.init(
        "vertex_texture_object",
        gl.ARRAY_BUFFER,
        .static,
        2,
        .float,
        @ptrCast(&dat.texture[0]),
        dat.texture.len,
    );
    buffers[3] = VBO.init(
        "vertex_index_object",
        gl.ELEMENT_ARRAY_BUFFER,
        .static,
        undefined,
        undefined,
        @ptrCast(&dat.elements[0]),
        dat.elements.len,
    );
    logger_renderer.info("created new render with {} verts", .{dat.verts.len / 3});
    return Renderer.init(allocator, buffers);
}

pub fn quad2dRenderer(allocator: Allocator) !Renderer {
    const buffer = allocator.alloc(VBO, 1) catch |err| {
        logger_renderer.err("could not allocate vbos in quad2dRenderer got error {any}", .{err});
        return err;
    };

    const quad_verts = [8]f32{
        0.0, 1.0,
        0.0, 0.0,
        1.0, 1.0,
        1.0, 0.0,
    };

    buffer[0] = VBO.init( // index 0
        "vertex_buffer_object",
        gl.ARRAY_BUFFER,
        .static,
        2,
        .float,
        @ptrCast(&quad_verts[0]),
        quad_verts.len,
    );

    var ren = Renderer.init(allocator, buffer);

    ren.number_elements = quad_verts.len;

    return ren;
}
