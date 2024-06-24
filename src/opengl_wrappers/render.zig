const gl = @import("gl");
const file = @import("../file_loading/loadfile.zig");
const std = @import("std");

const Allocator = std.mem.Allocator;

pub const renderer = struct {
    const Self = @This();
    vertex_array_object: gl.GLuint,
    vertex_buffer_object: gl.GLuint,
    vertex_normal_object: gl.GLuint, //might remove later
    vertex_texture_object: gl.GLuint,
    vertex_index_object: gl.GLuint,
    number_elements: usize,

    pub fn init() Self {
        var self = Self{
            .vertex_array_object = undefined,
            .vertex_buffer_object = undefined,
            .vertex_normal_object = undefined, //might remove later
            .vertex_texture_object = undefined,
            .vertex_index_object = undefined,
            .number_elements = undefined,
        };

        gl.genVertexArrays(1, &self.vertex_array_object);
        gl.genBuffers(1, &self.vertex_buffer_object);
        gl.genBuffers(1, &self.vertex_normal_object);
        gl.genBuffers(1, &self.vertex_index_object);
        gl.genBuffers(1, &self.vertex_texture_object);

        gl.bindVertexArray(self.vertex_array_object);
        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_buffer_object);
        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_normal_object);
        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_index_object);
        gl.bindBuffer(gl.ARRAY_BUFFER, self.vertex_texture_object);

        return self;
    }

    pub fn loadFile(self: *Self, dat: file.ObjectFile) !void {
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

        // std.debug.print("text : {any}\n", .{dat.texture.len / 2});
        // std.debug.print("vert : {any}\n", .{dat.verts.len / 3});
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.vertex_index_object);
        gl.namedBufferData(
            self.vertex_index_object,
            @as(isize, @intCast(dat.elements.len * @sizeOf(u32))),
            @ptrCast(&dat.elements[0]),
            gl.STATIC_DRAW,
        );

        self.number_elements = dat.elements.len;

        dat.unload();

        gl.bindVertexArray(self.vertex_array_object);
    }

    pub fn destroy(self: Self) void {
        gl.deleteVertexArrays(1, &self.vertex_array_object);
        gl.deleteBuffers(1, &self.vertex_buffer_object);
        gl.deleteBuffers(1, &self.vertex_normal_object);
        gl.deleteBuffers(1, &self.vertex_index_object);
    }

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
