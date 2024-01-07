const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const file = @import("loadfile.zig");

pub fn loadDatFile(allocator: Allocator, filename: []const u8) !file.ObjectFile {
    const buffer = try allocator.alloc(u8, 200);
    defer allocator.free(buffer);
    var f_slice = mem.split(u8, try std.fs.cwd().readFile(filename, buffer), file.eol);
    var top = mem.split(u8, f_slice.first(), " ");
    const num_verts: usize = try std.fmt.parseInt(usize, top.first(), 10);
    const num_triangle = try std.fmt.parseInt(usize, top.next() orelse " ", 10);

    const data: file.ObjectFile = file.ObjectFile{
        .verts = try allocator.alloc(f32, num_verts * 3),
        .normals = try allocator.alloc(f32, num_verts * 3),
        .elements = try allocator.alloc(u32, num_triangle * 3),
        .texture = undefined,
        .allocator = allocator,
    };

    const total_buffer = try allocator.alloc(u8, 32 * num_verts * 2 * num_triangle);
    defer allocator.free(total_buffer);
    const dat_file = try std.fs.cwd().readFile(filename, total_buffer);
    var lines = mem.split(u8, dat_file, file.eol);
    _ = lines.next();

    var i: usize = 0;
    while (i < num_verts * 3) : (i += 3) {
        const l = lines.next() orelse return file.DatFileError.MalFormedLine;
        var dat = mem.split(u8, l, " ");
        data.verts[i] = try std.fmt.parseFloat(f32, dat.first());
        data.verts[i + 1] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
        data.verts[i + 2] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
    }
    i = 0;

    while (i < num_verts * 3) : (i += 3) {
        const l = lines.next() orelse return file.DatFileError.MalFormedLine;
        var dat = mem.split(u8, l, " ");

        data.normals[i] = try std.fmt.parseFloat(f32, dat.first());
        data.normals[i + 1] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
        data.normals[i + 2] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
    }
    i = 0;

    while (i < num_triangle * 3) : (i += 3) {
        const l = lines.next() orelse return file.DatFileError.MalFormedLine;
        var dat = mem.split(u8, l, " ");
        data.elements[i] = try std.fmt.parseInt(u32, dat.first(), 10);
        data.elements[i + 1] = try std.fmt.parseInt(u32, dat.next() orelse "0", 10);
        data.elements[i + 2] = try std.fmt.parseInt(u32, dat.next() orelse "0", 10);
    }

    return data;
}

test "load_dat_file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const d = try loadDatFile(allocator, "objects/Seashell.dat");

    // std.debug.print("\nverts {}: \n", .{d.elements.len});
    // for (d.elements) |v| {
    //     std.debug.print("{}\n", .{v});
    // }

    d.unload();
}
