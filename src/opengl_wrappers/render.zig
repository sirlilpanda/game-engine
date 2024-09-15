const gl = @import("gl");
const file = @import("../file_loading/loadfile.zig");
const std = @import("std");

const Allocator = std.mem.Allocator;

const RenderType = enum {
    render_3d,
    render_2d,
};

pub const Renderer = union(RenderType) {
    const Self = @This();
    render_3d: Render3d,
    render_2d: Render2d,

    pub fn destroy(self: Self) void {
        switch (self) {
            .render_3d => self.destroy(),
            .render_2d => self.destroy(),
        }
    }
};

const logger_render2d = std.log.scoped(.Render_2d);

const logger_render3d = std.log.scoped(.Render_3d);

pub const Render2d = struct {
    const Self = @This();

    const quad_verts = [8]f32{
        0.0, 1.0,
        0.0, 0.0,
        1.0, 1.0,
        1.0, 0.0,
    };

    vertex_array_object: gl.GLuint,

    vertex_buffer_object: gl.GLuint,

    /// creates a new render with buffer loactions on the gpu
    pub fn init() Self {
        var self = Self{
            .vertex_array_object = undefined,
            .vertex_buffer_object = undefined,
        };

        gl.genVertexArrays(1, &self.vertex_array_object);
        gl.genBuffers(1, &self.vertex_buffer_object);

        logger_render2d.info("creating 2d renderer with id {}", .{self.vertex_array_object});
        gl.bindVertexArray(self.vertex_array_object);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_buffer_object);
        gl.namedBufferData(
            self.vertex_buffer_object,
            @as(isize, @intCast(quad_verts.len * @sizeOf(gl.GLfloat))),
            @ptrCast(&quad_verts[0]),
            gl.STATIC_DRAW,
        );
        gl.enableVertexArrayAttrib(self.vertex_array_object, 0);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, null);

        return self;
    }

    pub fn render(self: Self) void {
        gl.bindVertexArray(self.vertex_array_object);
        gl.drawArraysInstanced(
            gl.TRIANGLE_STRIP,
            0,
            @as(gl.GLsizei, @intCast(quad_verts.len)),
            1,
        );
    }
};

/// this store all the buffer data locations for
/// 3d objects, i will be changing this to a union
/// in the future to allow for differnt buffers
/// arrangements to be used
pub const Render3d = struct {
    const Self = @This();
    /// the id of the array object
    vertex_array_object: gl.GLuint,
    /// the vertex data
    vertex_buffer_object: gl.GLuint,
    /// the vertex normal data
    vertex_normal_object: gl.GLuint, //might remove later
    /// this vertex texture data
    vertex_texture_object: gl.GLuint,
    /// the face index data
    vertex_index_object: gl.GLuint,
    /// the number of elements, i.e. the length of the arrays
    number_elements: usize,

    /// creates a new render with buffer loactions on the gpu
    pub fn init() Self {
        var self = Self{
            .vertex_array_object = undefined,
            .vertex_buffer_object = undefined,
            .vertex_normal_object = undefined, //might remove later
            .vertex_texture_object = undefined,
            .vertex_index_object = undefined,
            .number_elements = undefined,
        };
        logger_render3d.info("creating new 3d renderer", .{});

        gl.genVertexArrays(1, &self.vertex_array_object);
        // could make this faster if i gen
        gl.genBuffers(1, &self.vertex_buffer_object);
        gl.genBuffers(1, &self.vertex_normal_object);
        gl.genBuffers(1, &self.vertex_index_object);
        gl.genBuffers(1, &self.vertex_texture_object);

        logger_render3d.info("created 3d renderer with id {}", .{self.vertex_array_object});
        // gl.bindVertexArray(self.vertex_array_object);
        // gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_buffer_object);
        // gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_normal_object);
        // gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_index_object);
        // gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_texture_object);

        return self;
    }

    /// loads a new objectFile in to the gpu
    pub fn loadFile(self: *Self, dat: file.ObjectFile) !void {
        logger_render3d.info("loading object file in to the gpu", .{});
        gl.bindVertexArray(self.vertex_array_object);
        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_buffer_object);
        gl.namedBufferData(
            self.vertex_buffer_object,
            @as(isize, @intCast(dat.verts.len * @sizeOf(gl.GLfloat))),
            @ptrCast(&dat.verts[0]),
            gl.STATIC_DRAW,
        );
        gl.enableVertexArrayAttrib(self.vertex_array_object, 0);
        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, null);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_normal_object);
        gl.namedBufferData(
            self.vertex_normal_object,
            @as(isize, @intCast(dat.normals.len * @sizeOf(f32))),
            @ptrCast(&dat.normals[0]),
            gl.STATIC_DRAW,
        );
        gl.enableVertexArrayAttrib(self.vertex_array_object, 1);
        gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 0, null);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_texture_object);
        gl.namedBufferData(
            self.vertex_texture_object,
            @as(isize, @intCast(dat.texture.len * @sizeOf(f32))),
            @ptrCast(&dat.texture[0]),
            gl.STATIC_DRAW,
        );

        gl.enableVertexArrayAttrib(self.vertex_array_object, 2);
        gl.vertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 0, null);

        // std.debug.print("text : {any}", .{dat.texture.len / 2});
        // std.debug.print("vert : {any}", .{dat.verts.len / 3});
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.vertex_index_object);
        gl.namedBufferData(
            self.vertex_index_object,
            @as(isize, @intCast(dat.elements.len * @sizeOf(u32))),
            @ptrCast(&dat.elements[0]),
            gl.STATIC_DRAW,
        );

        logger_render3d.info("sent data to the gpu", .{});
        self.number_elements = dat.elements.len;

        logger_render3d.info("unloading object data", .{});
        logger_render3d.debug("this unload may not occur in the future", .{});
        dat.unload();

        gl.bindVertexArray(self.vertex_array_object);
    }

    /// destroies all the buffers on the gpu
    pub fn destroy(self: Self) void {
        logger_render3d.info("deleting 3d renderer with id {}", .{self.vertex_array_object});
        gl.bindVertexArray(self.vertex_array_object);

        gl.deleteVertexArrays(1, &self.vertex_array_object);
        gl.deleteBuffers(1, &self.vertex_buffer_object);
        gl.deleteBuffers(1, &self.vertex_normal_object);
        gl.deleteBuffers(1, &self.vertex_index_object);
        gl.deleteBuffers(1, &self.vertex_texture_object);
    }

    /// renders the object
    pub fn render(self: Self) void {
        gl.bindVertexArray(self.vertex_array_object);
        gl.drawElements(
            gl.TRIANGLES,
            @as(gl.GLsizei, @intCast(self.number_elements)),
            gl.UNSIGNED_INT,
            null,
        );
    }
};

// fn loadSeaShell() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();

//     const dat = try file_reader.DatFile.loadDatFile(allocator, "objects/Seashell.dat");

//     gl.genVertexArrays(1, &VAO);
//     gl.bindVertexArray(VAO);

//     var VBOids: [3]gl.GLuint = undefined;

//     gl.genBuffers(3, &VBOids);
//     // std.debug.print("VBO {} {} {}", .{ VBOids[0], VBOids[1], VBOids[2] });

//     gl.bindBuffer(gl.ARRAY_BUFFER, VBOids[0]);
//     gl.bufferData(
//         gl.ARRAY_BUFFER,
//         @as(isize, @intCast(dat.verts.len * @sizeOf(gl.GLfloat))),
//         @ptrCast(&dat.verts[0]),
//         gl.STATIC_DRAW,
//     );
//     gl.enableVertexAttribArray(0);
//     gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 0, null);

//     gl.bindBuffer(gl.ARRAY_BUFFER, VBOids[1]);
//     gl.bufferData(
//         gl.ARRAY_BUFFER,
//         @as(isize, @intCast(dat.normals.len * @sizeOf(f32))),
//         @ptrCast(&dat.normals[0]),
//         gl.STATIC_DRAW,
//     );
//     gl.enableVertexAttribArray(1);
//     gl.vertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 0, null);

//     gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, VBOids[2]);
//     gl.bufferData(
//         gl.ELEMENT_ARRAY_BUFFER,
//         @as(isize, @intCast(dat.elements.len * @sizeOf(u32))),
//         @ptrCast(&dat.elements[0]),
//         gl.STATIC_DRAW,
//     );

//     num_triangles = dat.elements.len;

//     dat.unload();

//     gl.bindVertexArray(0);
// }
