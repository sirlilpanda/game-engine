const vec = @import("../math/vec.zig");
const mat = @import("../math/matrix.zig");
const uni = @import("../opengl_wrappers/uniform.zig");
const cam = @import("../opengl_wrappers/camera.zig");
const ren = @import("../opengl_wrappers/render.zig");
const tex = @import("../opengl_wrappers/texture.zig");
const std = @import("std");

pub const Object = struct {
    const Self = @This();
    pos: vec.Vec3,
    roation: vec.Vec3,
    scale: vec.Vec3,
    colour: vec.Vec4 = vec.Vec4.ones(),
    //this is the thing that holds the vertex and texture data
    render: ren.renderer,
    texture: ?tex.Texture,

    pub fn init(v: vec.Vec3) Self {
        return Self{
            .pos = v,
            .roation = vec.Vec3.zeros(),
            .scale = vec.Vec3.ones(),
            .render = undefined,
            .texture = null,
        };
    }

    pub fn updatePos(self: *Self, pos: vec.Vec3) void {
        self.pos = pos;
    }

    pub fn updateRoation(self: *Self, roation: vec.Vec3) void {
        self.roation = roation;
    }

    pub fn updateColour(self: *Self, colour: vec.Vec4) void {
        self.colour = colour;
    }

    pub fn updateScale(self: *Self, scale: vec.Vec3) void {
        self.scale = scale;
    }

    pub fn draw(self: Self) void {
        self.render.render();
    }
};
