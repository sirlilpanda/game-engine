//! this is some really bad code, i will come up and clean it later
//! you know removing the magic numbers and making it more portable

const program = @import("../opengl_wrappers/program.zig");
const uni = @import("../opengl_wrappers/uniform.zig");
const obj = @import("../objects/object.zig");
const cam = @import("../opengl_wrappers/camera.zig");
const mat = @import("../math/matrix.zig");
const vec = @import("../math/vec.zig");
const shader = @import("../opengl_wrappers/shader.zig");
const render = @import("../opengl_wrappers/render.zig");
const tex = @import("../textures/texture.zig");
const Colour = @import("../utils/colour.zig").Colour;
const std = @import("std");
const gl = @import("gl");

/// make sure this lines up with the ascii table ie A = 65
/// ill make this more dynamic in the future
pub const LookUpTable = struct {
    pub const height: u32 = 1024;
    pub const width: u32 = 1024;
    pub const cells_per_col: u32 = 16;
    pub const cells_per_row: u32 = 16;
    pub const cell_width: u32 = 64;
    pub const cell_height: u32 = 64;

    pub fn u8ToTextureUV(char: u8) vec.Vec2 {
        const char_num = @as(u32, @intCast(char));

        const offset = char_num * cell_width;

        const pixel_offset_y = (offset / width + 1) * cell_height;
        const pixel_offset_x = offset % width;

        return vec.init2(
            @as(f32, @floatFromInt(pixel_offset_x)) /
                @as(f32, @floatFromInt(width)),
            @as(f32, @floatFromInt(pixel_offset_y)) /
                @as(f32, @floatFromInt(height)),
        );
    }
};

pub const BasicUniformsTextRendering = struct {
    const Self = @This();

    colour: uni.Uniform = uni.Uniform.init("colour"),
    uv_pos: uni.Uniform = uni.Uniform.init("uv_pos"),
    uv_cell_size: uni.Uniform = uni.Uniform.init("uv_cell_size"),
    pos: uni.Uniform = uni.Uniform.init("pos"),
    scale: uni.Uniform = uni.Uniform.init("scale"),

    aspect_ratio: f32 = 16.0 / 9.0,
    aspect_ratio_correction_scale: vec.Vec2 = vec.Vec2.ones(),
    text_size: f32 = 0.4,
    //https://lucide.github.io/Font-Atlas-Generator/
    font_texture_atlas: tex.Texture = undefined,
    wrapping_length: usize = 12,

    char_quad: obj.Object = undefined,

    pub fn render_text(self: Self, text: []const u8, line: usize) void {
        self.font_texture_atlas.useTexture(); // make sure you use the font texture

        const normed_colour = Colour.red().norm();
        self.colour.sendVec4(vec.init4(normed_colour.x(), normed_colour.y(), normed_colour.z(), 1));

        const relitive_scale = self.aspect_ratio_correction_scale.mul(
            vec.init2(self.text_size, self.text_size),
        );

        self.scale.sendVec2(vec.init2(0.1, 0.1));

        var relitive_pos = vec.init2(0, -relitive_scale.y() * 4 * @as(f32, @floatFromInt(line + 1)));

        for (text, 0..) |char, dex| {
            if (char != ' ' or char != '\n') {
                const uv_pos = LookUpTable.u8ToTextureUV(char);
                self.uv_pos.sendVec2(uv_pos);
                self.pos.sendVec2(relitive_pos);
                gl.disable(gl.DEPTH_TEST);
                self.char_quad.render.render_2d.render();
                gl.enable(gl.DEPTH_TEST);
            }

            if ((dex + 1) % self.wrapping_length == 0) {
                relitive_pos = relitive_pos.add(vec.init2(0, -relitive_scale.y() * 4));
                relitive_pos.set_x(0);
            } else {
                relitive_pos = relitive_pos.add(vec.init2(relitive_scale.x() * 2, 0));
            }
        }
    }

    /// i will change what text is
    pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {
        _ = camera;
        _ = self;
        _ = object;
        @compileError("text rendering does not support the draw function, use the renderText function instead");
    }

    /// reloads the some of the defualt values
    pub fn reload(self: *Self) void {
        self.font_texture_atlas.useTexture();
        self.uv_cell_size.sendVec2(vec.init2(
            @as(f32, @floatFromInt(LookUpTable.cell_width)) /
                @as(f32, @floatFromInt(LookUpTable.width)),
            @as(f32, @floatFromInt(LookUpTable.cell_height)) /
                @as(f32, @floatFromInt(LookUpTable.height)),
        ));
        self.colour.sendVec4(vec.Vec4.ones());
    }

    pub fn addAspectRatio(self: *Self, aspect_ratio: f32) void {
        self.aspect_ratio = aspect_ratio;
        if (self.aspect_ratio > 1) {
            self.aspect_ratio_correction_scale = vec.init2(self.aspect_ratio, 1);
        } else {
            self.aspect_ratio_correction_scale = vec.init2(1, self.aspect_ratio);
        }
    }
};

/// this will benifit from batch rendering but i will do that later
pub const BasicProgramText = program.Program(BasicUniformsTextRendering, 0);

/// init function for the BasicProgramText program, i keep it here to show how to nicely init new programs
pub fn createBasicTextProgram(allocator: std.mem.Allocator) !BasicProgramText {
    var prog = BasicProgramText.init();

    const vert = try shader.Shader.init(allocator, "shaders/basic_2d.vert", .vertex);
    const frag = try shader.Shader.init(allocator, "shaders/basic_2d.frag", .frag);

    prog.loadShader(vert);
    prog.loadShader(frag);
    prog.link();
    prog.use();

    prog.uniforms.uv_cell_size.sendVec2(vec.init2(
        @as(f32, @floatFromInt(LookUpTable.cell_width)) /
            @as(f32, @floatFromInt(LookUpTable.width)),
        @as(f32, @floatFromInt(LookUpTable.cell_height)) /
            @as(f32, @floatFromInt(LookUpTable.height)),
    ));
    prog.uniforms.colour.sendVec4(vec.Vec4.ones());

    prog.uniforms.char_quad = obj.Object{
        .pos = vec.Vec3.zeros(),
        .roation = vec.Vec3.zeros(),
        .scale = vec.Vec3.ones(),
        .render = render.Renderer{
            .render_2d = render.Render2d.init(),
        },
        .texture = null,
    };

    return prog;
}
