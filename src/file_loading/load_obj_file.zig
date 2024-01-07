// const std = @import("std");
// const Arraylist = std.ArrayList;
// const builtin = @import("builtin");
// const Allocator = std.mem.Allocator;
// const mem = std.mem;
// const file = @import("loadfile.zig");

// const token = enum {
//     comment,
//     vertex,
//     vertex_normal,
//     texture,
//     // space_vertex,
//     face_elements,
//     // line_elements,
// };

// const Object_file = struct {
//     vertex : Arraylist(f32),
//     vertex_normal : Arraylist(f32)
//     texture : Arraylist(f32)
//     // space_vertex : Arraylist(f32)
//     face_elements : Arraylist(u32)
//     // line_elements : Arraylist(f32)
// };

// pub fn loadObjFile(allocator: Allocator, filename: []const u8) !file.ObjectFile {
//     const obj_file: std.fs.File = try std.fs.cwd().openFile(filename, .{});
//     const file_end = try obj_file.getEndPos();
//     std.debug.print("end : {}\n", .{file_end});
//     const data = try allocator.alloc(u8, @as(usize, file_end));
//     defer allocator.free(data);
//     const data_read = try obj_file.readAll(data);
//     _ = data_read;
//     var lines = mem.split(u8, data, file.eol);

//     while (lines.next()) |line| {
//         var token_type : ?token = null;
//         if (mem.startsWith(u8, "#", lines)) token_type = .comment;
//         if (mem.startsWith(u8, "v ", lines)) token_type = .vertex;
//         if (mem.startsWith(u8, "vt", lines)) token_type = .texture;
//         if (mem.startsWith(u8, "vn", lines)) token_type = .vertex_normal;
//         // if (mem.startsWith(u8, "vp", lines)) token_type = .space_vertex;
//         if (mem.startsWith(u8, "f ", lines)) token_type = .face_elements;
//         // if (mem.startsWith(u8, "l ", lines)) token_type = .line_elements;
//         if (token_type) |token|{

//         }

//         std.debug.print("{s}\n", .{line});
//     }

//     return file.ObjectFile{
//         .verts = undefined,
//         .normals = undefined,
//         .elements = undefined,
//         .texture = undefined,
//         .allocator = allocator,
//     };
// }

// test "load_obj_file" {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//     defer _ = gpa.deinit();
//     const allocator = gpa.allocator();

//     const d = try loadObjFile(allocator, "objects/cube.obj");
//     _ = d;

//     // std.debug.print("\nverts {}: \n", .{d.elements.len});
//     // for (d.elements) |v| {
//     //     std.debug.print("{}\n", .{v});
//     // }

//     // d.unload();
// }
