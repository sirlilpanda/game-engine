const gl = @import("gl");
const std = @import("std");
const Allocator = std.mem.Allocator;
const Image = @import("../file_loading/image.zig").Image;

const texture_logger = std.log.scoped(.Texture);

/// texture struct, where the texture is store in the gpu
/// only supports 2d textures, still needs a free
pub const Texture = struct {
    const Self = @This();
    /// the id of the texture
    texture_id: gl.GLuint,
    /// the spot of where this texture is in the id
    texture_spot: gl.GLenum,

    /// creates a new texture form the file
    pub fn init(allocator: Allocator, filename: []const u8) !Self {
        texture_logger.debug("creating texture form file {s}", .{filename});
        var self = Self{
            .texture_id = undefined,
            .texture_spot = undefined,
        };

        const image = try Image.init(allocator, filename);
        defer image.unload(allocator);
        gl.genTextures(1, &self.texture_id);
        gl.activeTexture(gl.TEXTURE0);
        self.texture_spot = gl.TEXTURE0;
        gl.bindTexture(gl.TEXTURE_2D, self.texture_id);
        texture_logger.debug("generated texture {s} with id {}", .{ filename, self.texture_id });

        texture_logger.debug("texture {s} has format {s}", .{ filename, @tagName(image.format) });

        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            image.width,
            image.height,
            0,
            @intFromEnum(image.format),
            gl.UNSIGNED_BYTE,
            @ptrCast(&image.data[0]),
        );

        texture_logger.debug("texture {s} sent to gpu", .{filename});

        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        return self;
    }

    /// allows opengl to use the current texture
    pub fn useTexture(self: Self) void {
        gl.bindTexture(gl.TEXTURE_2D, self.texture_id);
        gl.activeTexture(self.texture_spot);
    }

    /// frees the texture from the GPU
    pub fn destroy(self: Self) void {
        texture_logger.info("[INFO] deleting texture with id {}", .{self.texture_id});
        gl.deleteTextures(1, self.texture_id);
    }
};
