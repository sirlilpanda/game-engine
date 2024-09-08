const gl = @import("gl");
const std = @import("std");
const Allocator = std.mem.Allocator;
const file = @import("../file_loading/tga.zig");

// texture struct
pub const Texture = struct {
    const Self = @This();
    // the id of the texture
    texture_id: gl.GLuint,
    // the spot of where this texture is in the id
    texture_spot: gl.GLenum,

    // inits a given texture, currently only uses .tga files, i will be adding in
    // .bmp soon too
    pub fn init(allocator: Allocator, filename: []const u8) !Self {
        var self = Self{
            .texture_id = undefined,
            .texture_spot = undefined,
        };

        const data = try file.Tga.load(allocator, filename);
        defer allocator.free(data.data);
        gl.genTextures(1, &self.texture_id);
        gl.activeTexture(gl.TEXTURE0);
        self.texture_spot = gl.TEXTURE0;
        gl.bindTexture(gl.TEXTURE_2D, self.texture_id);

        // DONT FOR GET TO CHANGES THESE BACK TO RGB WHEN USING OTHER DATATYPES
        const format: gl.GLenum = switch (data.header.bits_per_pixel) {
            1 * 8 => gl.R8,
            3 * 8 => gl.RGB,
            4 * 8 => gl.RGBA,
            else => gl.R8,
        };

        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            data.header.wdith,
            data.header.height,
            0,
            format,
            gl.UNSIGNED_BYTE,
            @ptrCast(&data.data[0]),
        );

        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        return self;
    }

    // allows opengl to use the current texture
    pub fn useTexture(self: Self) void {
        gl.bindTexture(gl.TEXTURE_2D, self.texture_id);
        gl.activeTexture(self.texture_spot);
    }
};
