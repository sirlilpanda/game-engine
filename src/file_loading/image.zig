//! currently i only support uncompressed data formats
//! as compression algorithms are scary
const Bmp = @import("bmp.zig").Bmp;
const Tga = @import("tga.zig").Tga;
const std = @import("std");
const gl = @import("gl");
const image_logger = std.log.scoped(.Image);

const ImageErrors = error{
    image_type_not_supported,
};

const ImageFormat = enum(c_uint) {
    R8 = gl.R8,
    RGB = gl.RGB,
    RGBA = gl.RGBA,
};

/// abstraction on image data type
/// still need to implement a save function
pub const Image = struct {
    const Self = @This();
    height: i32, // i have no clue why opengl wants these as ints
    width: i32, // i have no clue why opengl wants these as ints
    data: []u8,
    format: ImageFormat,
    filename: []const u8 = "you_gave_me_no_name",

    pub fn init(alloc: std.mem.Allocator, filename: []const u8) !Self {
        image_logger.info("loading new image with name {s}", .{filename});
        var image_type_supported: bool = false;
        var image: Image = undefined;

        if (std.mem.endsWith(u8, filename, ".tga")) {
            image_logger.debug("loading as .tga", .{});
            const tga = Tga.load(alloc, filename) catch |err| {
                image_logger.err("attempted to load {s} got error {any}", .{ filename, err });
                return err;
            };
            image_type_supported = true;
            image = Self{
                .height = tga.header.height,
                .width = tga.header.wdith,
                .data = tga.data,
                .format = bitsPerPixelToFormat(tga.header.bits_per_pixel),
                .filename = filename,
            };
        }
        if (std.mem.endsWith(u8, filename, ".bmp")) {
            image_logger.debug("loading as .bmp", .{});
            const bmp = Bmp.load(alloc, filename) catch |err| {
                image_logger.err("attempted to load {s} got error {any}", .{ filename, err });
                return err;
            };
            image_type_supported = true;
            image = Self{
                .height = bmp.infoheader.height,
                .width = bmp.infoheader.width,
                .data = bmp.data,
                .format = bitsPerPixelToFormat(@as(u8, @intCast(bmp.infoheader.bits_per_pixel))), // due to differnt type casting
                .filename = filename,
            };
        }

        if (image_type_supported) {
            image_logger.info("loaded {s}: width : {}, height : {}, format {s}", .{ filename, image.width, image.height, @tagName(image.format) });
            return image;
        } else {
            image_logger.err("image type not supported {s}", .{filename});
            return ImageErrors.image_type_not_supported;
        }
    }

    fn bitsPerPixelToFormat(bits: u8) ImageFormat {
        return switch (bits) {
            1 * 8 => ImageFormat.R8,
            3 * 8 => ImageFormat.RGB,
            4 * 8 => ImageFormat.RGBA,
            else => ImageFormat.R8,
        };
    }

    /// frees the image data
    pub fn unload(self: Self, alloc: std.mem.Allocator) void {
        image_logger.info("unloading image {s}", .{self.filename});
        alloc.free(self.data);
    }
};
