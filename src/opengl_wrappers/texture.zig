const gl = @import("gl");
const std = @import("std");
const Allocator = std.mem.Allocator;
const file = @import("../file_loading/tga.zig");

var count: c_uint = 0;

pub const Texture = struct {
    const Self = @This();
    texture_id: gl.GLuint,
    texture_spot: gl.GLenum,

    pub fn init(allocator: Allocator, filename: []const u8) !Self {
        var self = Self{
            .texture_id = undefined,
            .texture_spot = undefined,
        };

        const data = try file.Tga.load(allocator, filename);
        defer allocator.free(data.data);
        gl.genTextures(1, &self.texture_id);
        gl.activeTexture(gl.TEXTURE0 + count);
        count += 1;
        self.texture_spot = count;
        gl.bindTexture(gl.TEXTURE_2D, self.texture_id);
        const fomat: gl.GLenum = switch (data.header.bits_per_pixel) {
            1 * 8 => gl.R8,
            3 * 8 => gl.RGB,
            4 * 8 => gl.RGBA,
            else => gl.R8,
        };

        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGB,
            data.header.wdith,
            data.header.height,
            0,
            fomat,
            gl.UNSIGNED_BYTE,
            @ptrCast(&data.data[0]),
        );

        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        return self;
    }

    pub fn useTexture(self: Self) void {
        gl.activeTexture(gl.TEXTURE0 + self.texture_spot);
    }
};
