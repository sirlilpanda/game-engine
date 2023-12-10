const std = @import("std");
const Vec = @import("math/Vec.zig");
const Allocator = std.mem.Allocator;
const mem = std.mem;

//[TODO] need to make this detemerned by os
const eol: []const u8 = "\r\n";

const std_file_size = 2000;

pub fn loadfile(allocator: Allocator, filename: []const u8) ![]u8 {
    const buffer = try allocator.alloc(u8, std_file_size);
    defer allocator.free(buffer);
    const f_slice = try std.fs.cwd().readFile(filename, buffer);
    const file_len = f_slice.len;
    const file = try allocator.alloc(u8, file_len + 1);
    std.mem.copy(u8, file, buffer[0..file_len]);
    file[file_len] = 0;
    return file;
}

pub const DatFileError = error{
    MalFormedLine,
};

pub const DatFile = struct {
    const Self = @This();

    verts: []Vec.Vec3,
    normals: []Vec.Vec3,
    elements: []@Vector(3, u32),
    allocator: Allocator,

    pub fn loadDatFile(allocator: Allocator, filename: []const u8) !Self {
        const buffer = try allocator.alloc(u8, 200);
        defer allocator.free(buffer);
        var f_slice = mem.split(u8, try std.fs.cwd().readFile(filename, buffer), eol);
        var top = mem.split(u8, f_slice.first(), " ");
        const num_verts: usize = try std.fmt.parseInt(usize, top.first(), 10);
        const num_triangle = try std.fmt.parseInt(usize, top.next() orelse " ", 10);

        const data: DatFile = DatFile{
            .verts = try allocator.alloc(Vec.Vec3, num_verts),
            .normals = try allocator.alloc(Vec.Vec3, num_verts),
            .elements = try allocator.alloc(@Vector(3, u32), num_triangle),
            .allocator = allocator,
        };

        const total_buffer = try allocator.alloc(u8, 32 * num_verts * 2 * num_triangle);
        defer allocator.free(total_buffer);
        const file = try std.fs.cwd().readFile(filename, total_buffer);
        var lines = mem.split(u8, file, eol);
        _ = lines.next();

        var i: usize = 0;
        while (i < num_verts) : (i += 1) {
            const l = lines.next() orelse return DatFileError.MalFormedLine;
            var dat = mem.split(u8, l, " ");
            data.verts[i] = Vec.init3(
                try std.fmt.parseFloat(f32, dat.first()),
                try std.fmt.parseFloat(f32, dat.next() orelse "0"),
                try std.fmt.parseFloat(f32, dat.next() orelse "0"),
            );
        }
        i = 0;

        while (i < num_verts) : (i += 1) {
            const l = lines.next() orelse return DatFileError.MalFormedLine;
            var dat = mem.split(u8, l, " ");
            data.normals[i] = Vec.init3(
                try std.fmt.parseFloat(f32, dat.first()),
                try std.fmt.parseFloat(f32, dat.next() orelse "0"),
                try std.fmt.parseFloat(f32, dat.next() orelse "0"),
            );
        }
        i = 0;

        while (i < num_triangle) : (i += 1) {
            const l = lines.next() orelse return DatFileError.MalFormedLine;
            var dat = mem.split(u8, l, " ");

            data.elements[i] = @Vector(3, u32){
                try std.fmt.parseInt(u32, dat.first(), 10),
                try std.fmt.parseInt(u32, dat.next() orelse "0", 10),
                try std.fmt.parseInt(u32, dat.next() orelse "0", 10),
            };
        }

        return data;
    }

    pub fn unload(file: Self) void {
        file.allocator.free(file.elements);
        file.allocator.free(file.verts);
        file.allocator.free(file.normals);
    }
};

test "load_data" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const d = try DatFile.loadDatFile(allocator, "objects/Seashell.dat");

    std.debug.print("\nverts {}: \n", .{d.elements.len});
    for (d.elements) |v| {
        std.debug.print("{}\n", .{v});
    }

    d.unload();
}
