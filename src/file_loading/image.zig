//! currently i only support uncompressed data formats
//! as compression algorithms are scary
const Bmp = @import("bmp.zig").Bmp;
const Tga = @import("tga.zig").Tga;
const std = @import("std");

const ImageErrors = error{
    image_type_not_supported,
};

/// abstraction on image data type
/// still need to implement a save function
pub const Image = struct {
    const Self = @This();
    height: i32, // i have no clue why opengl wants these as ints
    width: i32, // i have no clue why opengl wants these as ints
    data: []u8,
    bits_per_pixel: u8,

    pub fn init(alloc: std.mem.Allocator, filename: []const u8) !Self {
        if (std.mem.endsWith(u8, filename, ".tga")) {
            const tga = try Tga.load(alloc, filename);
            return Self{
                .height = tga.header.height,
                .width = tga.header.wdith,
                .data = tga.data,
                .bits_per_pixel = tga.header.bits_per_pixel,
            };
        }
        if (std.mem.endsWith(u8, filename, ".bmp")) {
            const bmp = try Bmp.load(alloc, filename);
            return Self{
                .height = bmp.infoheader.height,
                .width = bmp.infoheader.width,
                .data = bmp.data,
                .bits_per_pixel = @as(u8, @intCast(bmp.infoheader.bits_per_pixel)), // due to differnt type casting
            };
        }

        return ImageErrors.image_type_not_supported;
    }

    /// frees the image data
    pub fn unload(self: Self, alloc: std.mem.Allocator) void {
        alloc.free(self.data);
    }
};
