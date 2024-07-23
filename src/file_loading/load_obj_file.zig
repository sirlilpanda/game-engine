const std = @import("std");
const Arraylist = std.ArrayList;
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const file = @import("loadfile.zig");
const vec = @import("../math/vec.zig");

const parsing_error = error{
    unknown_number_of_slashes,
    only_support_3_vert_faces,
    malformed_line,
};

const token = enum {
    comment,
    vertex,
    vertex_normal,
    texture,
    face_elements,
    // space_vertex,
    // line_elements,
};

const FaceElements = struct {
    vertex_indexes: [3]u32,
    texture_indexes: ?[3]u32,
    normal_indexes: ?[3]u32,
};

inline fn getTokenType(line: []const u8) ?token {
    if (mem.startsWith(u8, line, "# ")) return .comment;
    if (mem.startsWith(u8, line, "v ")) return .vertex;
    if (mem.startsWith(u8, line, "vt")) return .texture;
    if (mem.startsWith(u8, line, "vn")) return .vertex_normal;
    if (mem.startsWith(u8, line, "f ")) return .face_elements;
    // if (mem.startsWith(u8, "vp", line)) token_type = .space_vertex;
    // if (mem.startsWith(u8, "l ", line)) token_type = .line_elements;
    return null;
}

// only works for 3d models as 2d models arent real and cant hurt me
inline fn parseFaceData(line: []const u8) !FaceElements {
    const number_of_slashes = mem.count(u8, line, "/");
    const number_of_elements = mem.count(u8, line, " ");
    if (number_of_elements != 3) return parsing_error.only_support_3_vert_faces;
    const vertex_normal_check = if (mem.indexOf(u8, line, "//") != null) true else false;
    // std.debug.print("number_of_slashes {}\n", .{number_of_slashes});
    const faceelement = switch (number_of_slashes) {
        0 =>
        // just vertex
        // f v1 v2 v3
        blk: {
            var dat = mem.split(u8, line[1..], " ");
            var f: FaceElements = FaceElements{
                .vertex_indexes = undefined,
                .texture_indexes = null,
                .normal_indexes = null,
            };
            f.vertex_indexes[0] = try std.fmt.parseInt(u32, dat.first(), 10);
            f.vertex_indexes[1] = try std.fmt.parseInt(u32, dat.next() orelse "0", 10);
            f.vertex_indexes[2] = try std.fmt.parseInt(u32, dat.next() orelse "0", 10);
            break :blk f;
        },

        3 => blk: {
            // vertex + texture
            // f v1/vt1 v2/vt2 v3/vt3
            var dat = mem.split(u8, line[2..], " ");

            var vertex_indexes: [3]u32 = undefined;
            var texture_indexes: [3]u32 = undefined;

            const face_indexs = [3][]const u8{
                dat.first(),
                dat.next() orelse "0",
                dat.next() orelse "0",
            };

            for (face_indexs, 0..) |face, i| {
                var indexes = mem.split(u8, face, "/");
                vertex_indexes[i] = try std.fmt.parseInt(u32, indexes.first(), 10);
                texture_indexes[i] = try std.fmt.parseInt(u32, indexes.next() orelse "0", 10);
            }

            break :blk FaceElements{
                .vertex_indexes = vertex_indexes,
                .texture_indexes = texture_indexes,
                .normal_indexes = null,
            };
        },
        6 => blk: {
            if (vertex_normal_check) {
                // vertex normal
                // f v1//vn1 v2//vn2 v3//vn3
                var dat = mem.split(u8, line[2..], " ");

                var vertex_indexes: [3]u32 = undefined;
                var normal_indexes: [3]u32 = undefined;

                const face_indexs = [3][]const u8{
                    dat.first(),
                    dat.next() orelse "0",
                    dat.next() orelse "0",
                };

                for (face_indexs, 0..) |face, i| {
                    var indexes = mem.split(u8, face, "//");
                    vertex_indexes[i] = try std.fmt.parseInt(u32, indexes.first(), 10);
                    normal_indexes[i] = try std.fmt.parseInt(u32, indexes.next() orelse "0", 10);
                }

                break :blk FaceElements{
                    .vertex_indexes = vertex_indexes,
                    .texture_indexes = null,
                    .normal_indexes = normal_indexes,
                };
            } else {
                var dat = mem.split(u8, line[2..], " ");

                var vertex_indexes: [3]u32 = undefined;
                var texture_indexes: [3]u32 = undefined;
                var normal_indexes: [3]u32 = undefined;
                const face_indexs = [3][]const u8{
                    dat.first(),
                    dat.next() orelse "0",
                    dat.next() orelse "0",
                };

                for (face_indexs, 0..) |face, i| {
                    var indexes = mem.split(u8, face, "/");
                    vertex_indexes[i] = try std.fmt.parseInt(u32, indexes.first(), 10);
                    texture_indexes[i] = try std.fmt.parseInt(u32, indexes.next() orelse "0", 10);
                    normal_indexes[i] = try std.fmt.parseInt(u32, indexes.next() orelse "0", 10);
                }

                break :blk FaceElements{
                    .vertex_indexes = vertex_indexes,
                    .texture_indexes = texture_indexes,
                    .normal_indexes = normal_indexes,
                };
            }
            break :blk parsing_error.malformed_line;
        },
        else => parsing_error.unknown_number_of_slashes,
    };
    // std.debug.print("{any}\n", .{faceelement});

    return faceelement;
}

pub fn loadObjFile(allocator: Allocator, filename: []const u8) !file.ObjectFile {
    const obj_file: std.fs.File = try std.fs.cwd().openFile(filename, .{});
    const file_end = try obj_file.getEndPos();
    // std.debug.print("end : {}\n", .{file_end});
    const data = try allocator.alloc(u8, @as(usize, file_end));
    defer allocator.free(data);
    _ = try obj_file.readAll(data);
    // std.debug.print("amount read : {d}\n", .{read});
    var verts = Arraylist(f32).init(allocator);
    defer verts.deinit();
    var normals = Arraylist(f32).init(allocator);
    defer normals.deinit();
    var texture = Arraylist(f32).init(allocator);
    defer texture.deinit();
    var elements = Arraylist(FaceElements).init(allocator);
    defer elements.deinit();

    var lines = mem.split(u8, data, if (mem.containsAtLeast(u8, data, 1, "\r")) "\r\n" else "\n");
    while (lines.next()) |line| {
        // std.debug.print("{s}\n", .{line});
        const token_type: ?token = getTokenType(line);
        // std.debug.print("token = {any}\n", .{token_type});

        if (token_type) |t| {
            switch (t) {
                token.comment => {
                    std.debug.print("token type : {s} \n", .{"comment"});
                },
                token.vertex => {
                    // std.debug.print("token type : {s} ", .{"vertex"});
                    var dat = mem.split(u8, line[2..], " ");
                    try verts.append(try std.fmt.parseFloat(f32, dat.first()));
                    try verts.append(try std.fmt.parseFloat(f32, dat.next() orelse "0"));
                    try verts.append(try std.fmt.parseFloat(f32, dat.next() orelse "0"));
                },
                token.vertex_normal => {
                    // std.debug.print("token type : {s} ", .{"vertex_normal"});
                    var dat = mem.split(u8, line[3..], " ");
                    try normals.append(try std.fmt.parseFloat(f32, dat.first()));
                    try normals.append(try std.fmt.parseFloat(f32, dat.next() orelse "0"));
                    try normals.append(try std.fmt.parseFloat(f32, dat.next() orelse "0"));
                },
                token.texture => {
                    // std.debug.print("token type : {s} ", .{"texture"});
                    var dat = mem.split(u8, line[3..], " ");
                    try texture.append(try std.fmt.parseFloat(f32, dat.first()));
                    try texture.append(try std.fmt.parseFloat(f32, dat.next() orelse "0"));
                },
                token.face_elements => {
                    try elements.append(try parseFaceData(line));
                },
            }
        } else {
            std.debug.print("token type : {s} \n", .{"no token"});
        }
        // std.debug.print("{s}\n", .{line});
    }

    // this works but not really
    // i really be copying a ton of faces
    // 3 points and 3 vectors make a face
    const num_elements = elements.items.len * 3 * 3;
    // std.debug.print("elements_arr : {}\n", .{num_elements});

    var verts_arr = try allocator.alloc(f32, num_elements);
    var normals_arr = try allocator.alloc(f32, num_elements); // will be aligned with the verts array
    var texture_arr = try allocator.alloc(f32, elements.items.len * 2 * 3); // will be aligned with the verts array
    var elements_arr = try allocator.alloc(u32, num_elements);

    for (elements.items, 0..) |element, i| {
        var j: u32 = 0;
        while (j < 9) : (j += 1)
            elements_arr[i * 9 + j] = @as(u32, @intCast(i)) * 9 + j;

        mem.copy(f32, verts_arr[i * 9 + 0 .. i * 9 + 3], verts.items[(element.vertex_indexes[0] - 1) * 3 .. (element.vertex_indexes[0] - 1) * 3 + 3]);
        mem.copy(f32, verts_arr[i * 9 + 3 .. i * 9 + 6], verts.items[(element.vertex_indexes[1] - 1) * 3 .. (element.vertex_indexes[1] - 1) * 3 + 3]);
        mem.copy(f32, verts_arr[i * 9 + 6 .. i * 9 + 9], verts.items[(element.vertex_indexes[2] - 1) * 3 .. (element.vertex_indexes[2] - 1) * 3 + 3]);

        if (element.texture_indexes) |tex_index| {
            mem.copy(f32, texture_arr[i * 6 + 0 .. i * 6 + 2], texture.items[(tex_index[0] - 1) * 2 .. (tex_index[0] - 1) * 2 + 2]);
            mem.copy(f32, texture_arr[i * 6 + 2 .. i * 6 + 4], texture.items[(tex_index[1] - 1) * 2 .. (tex_index[1] - 1) * 2 + 2]);
            mem.copy(f32, texture_arr[i * 6 + 4 .. i * 6 + 6], texture.items[(tex_index[2] - 1) * 2 .. (tex_index[2] - 1) * 2 + 2]);
        }

        if (element.normal_indexes) |norm_index| {
            mem.copy(f32, normals_arr[i * 9 + 0 .. i * 9 + 3], normals.items[(norm_index[0] - 1) * 3 .. (norm_index[0] - 1) * 3 + 3]);
            mem.copy(f32, normals_arr[i * 9 + 3 .. i * 9 + 6], normals.items[(norm_index[1] - 1) * 3 .. (norm_index[1] - 1) * 3 + 3]);
            mem.copy(f32, normals_arr[i * 9 + 6 .. i * 9 + 9], normals.items[(norm_index[2] - 1) * 3 .. (norm_index[2] - 1) * 3 + 3]);
        }
        // std.debug.print("{any}\n", .{verts_arr});
    }

    const ob = file.ObjectFile{
        .verts = verts_arr,
        .normals = normals_arr,
        .elements = elements_arr,
        .texture = texture_arr,
        .allocator = allocator,
    };
    return ob;
}

test "load_obj_file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const d = try loadObjFile(allocator, "objects/cube.obj");

    std.debug.print("{}", .{d});
    std.debug.print("texture : len {}\n", .{d.texture.len});

    // std.debug.print("\nverts {}: \n", .{d.elements.len});
    // for (d.elements) |v| {
    //     std.debug.print("{}\n", .{v});
    // }

    d.unload();
}
