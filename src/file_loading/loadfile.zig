const std = @import("std");
const builtin = @import("builtin");
const Allocator = std.mem.Allocator;
const mem = std.mem;
pub usingnamespace @import("load_data_file.zig");

pub const eol: []const u8 = if (builtin.os.tag == .windows) "\r\n" else "\n";

pub const DatFileError = error{
    MalFormedLine,
};

pub const ObjectFile = struct {
    const Self = @This();

    verts: []f32,
    normals: []f32,
    elements: []u32,
    texture: []f32,
    allocator: Allocator,

    pub fn change_orign(self: Self, x: f32, y: f32, z: f32) void {
        var i: usize = 0;
        while (i < self.verts.len) : (i += 3) {
            self.verts[i] += x;
            self.verts[i + 1] += y;
            self.verts[i + 2] += z;
        }
        i = 0;
    }

    pub fn unload(file: Self) void {
        file.allocator.free(file.elements);
        file.allocator.free(file.verts);
        file.allocator.free(file.normals);
    }
};
