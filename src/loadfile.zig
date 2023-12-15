const std = @import("std");
const b = std.builtin;
const Allocator = std.mem.Allocator;
const mem = std.mem;

//[TODO] need to make this detemerned by os
const eol: []const u8 = "\r\n";

pub const DatFileError = error{
    MalFormedLine,
};

pub const DatFile = struct {
    const Self = @This();

    verts: []f32,
    normals: []f32,
    elements: []u32,
    allocator: Allocator,

    pub fn loadDatFile(allocator: Allocator, filename: []const u8) !Self {
        const buffer = try allocator.alloc(u8, 200);
        defer allocator.free(buffer);
        var f_slice = mem.split(u8, try std.fs.cwd().readFile(filename, buffer), eol);
        var top = mem.split(u8, f_slice.first(), " ");
        const num_verts: usize = try std.fmt.parseInt(usize, top.first(), 10);
        const num_triangle = try std.fmt.parseInt(usize, top.next() orelse " ", 10);

        const data: DatFile = DatFile{
            .verts = try allocator.alloc(f32, num_verts * 3),
            .normals = try allocator.alloc(f32, num_verts * 3),
            .elements = try allocator.alloc(u32, num_triangle * 3),
            .allocator = allocator,
        };

        const total_buffer = try allocator.alloc(u8, 32 * num_verts * 2 * num_triangle);
        defer allocator.free(total_buffer);
        const file = try std.fs.cwd().readFile(filename, total_buffer);
        var lines = mem.split(u8, file, eol);
        _ = lines.next();

        var i: usize = 0;
        while (i < num_verts * 3) : (i += 3) {
            const l = lines.next() orelse return DatFileError.MalFormedLine;
            var dat = mem.split(u8, l, " ");
            data.verts[i] = try std.fmt.parseFloat(f32, dat.first());
            data.verts[i + 1] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
            data.verts[i + 2] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
        }
        i = 0;

        while (i < num_verts * 3) : (i += 3) {
            const l = lines.next() orelse return DatFileError.MalFormedLine;
            var dat = mem.split(u8, l, " ");

            data.normals[i] = try std.fmt.parseFloat(f32, dat.first());
            data.normals[i + 1] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
            data.normals[i + 2] = try std.fmt.parseFloat(f32, dat.next() orelse "0");
        }
        i = 0;

        while (i < num_triangle * 3) : (i += 3) {
            const l = lines.next() orelse return DatFileError.MalFormedLine;
            var dat = mem.split(u8, l, " ");
            data.elements[i] = try std.fmt.parseInt(u32, dat.first(), 10);
            data.elements[i + 1] = try std.fmt.parseInt(u32, dat.next() orelse "0", 10);
            data.elements[i + 2] = try std.fmt.parseInt(u32, dat.next() orelse "0", 10);
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
