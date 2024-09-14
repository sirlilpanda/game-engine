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
        var image_type_supported: bool = false;
        var image: Image = undefined;

        if (std.mem.endsWith(u8, filename, ".tga")) {
            const tga = Tga.load(alloc, filename) catch |err| {
                std.debug.print("[ERROR] attempted to load {s} got error {any}\n", .{ filename, err });
                return err;
            };
            image_type_supported = true;
            image = Self{
                .height = tga.header.height,
                .width = tga.header.wdith,
                .data = tga.data,
                .bits_per_pixel = tga.header.bits_per_pixel,
            };
        }
        if (std.mem.endsWith(u8, filename, ".bmp")) {
            const bmp = Bmp.load(alloc, filename) catch |err| {
                std.debug.print("[ERROR] attempted to load {s} got error {any}\n", .{ filename, err });
                return err;
            };
            image_type_supported = true;
            image = Self{
                .height = bmp.infoheader.height,
                .width = bmp.infoheader.width,
                .data = bmp.data,
                .bits_per_pixel = @as(u8, @intCast(bmp.infoheader.bits_per_pixel)), // due to differnt type casting
            };
        }

        if (image_type_supported) {
            std.debug.print("[INFO] loaded {s}: width : {}, height : {}, bits per pixel {}\n", .{ filename, image.width, image.height, image.bits_per_pixel });
            return image;
        } else {
            std.debug.print("[ERROR] image type not supported {s}\n", .{filename});
            return ImageErrors.image_type_not_supported;
        }
    }

    /// frees the image data
    pub fn unload(self: Self, alloc: std.mem.Allocator) void {
        alloc.free(self.data);
    }
};
