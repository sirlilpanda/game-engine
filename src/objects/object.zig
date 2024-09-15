const vec = @import("../math/vec.zig");
const mat = @import("../math/matrix.zig");
const uni = @import("../opengl_wrappers/uniform.zig");
const cam = @import("../opengl_wrappers/camera.zig");
const ren = @import("../opengl_wrappers/render.zig");
const tex = @import("../textures/texture.zig");
const std = @import("std");

const object_logger = std.log.scoped(.Object);

/// current this object type only supports 3d objects
pub const Object = struct {
    const Self = @This();
    /// the position of the object in world space
    pos: vec.Vec3,
    /// the rotaion of the object in world space
    /// this will be changed to a Quaternion
    roation: vec.Vec3,
    /// the scale of the object
    scale: vec.Vec3,
    /// the colour of the object
    colour: vec.Vec4 = vec.Vec4.ones(),
    /// this is the thing that holds the vertex and texture data
    /// but its stored on the gpu
    render: ren.Renderer,
    /// the texture of the object
    texture: ?tex.Texture,

    /// bounding box max point
    bounding_box_max_point: ?vec.Vec3 = null,
    /// bounding box min point
    bounding_box_min_point: ?vec.Vec3 = null,

    /// creates a new object
    pub fn init(v: vec.Vec3) Self {
        return Self{
            .pos = v,
            .roation = vec.Vec3.zeros(),
            .scale = vec.Vec3.ones(),
            .render = undefined,
            .texture = null,
            .bounding_box_max_point = vec.Vec3.ones(),
            .bounding_box_min_point = vec.Vec3.number(-1),
        };
    }

    /// moves the object by the given about relitive to
    /// its self
    pub fn move(self: *Self, amount: vec.Vec3) void {
        self.pos = self.pos.add(amount);
    }

    /// updates the current position
    pub fn updatePos(self: *Self, pos: vec.Vec3) void {
        object_logger.debug("updated obj pos to {}", .{pos});
        self.pos = pos;
    }

    /// updates the current roation
    pub fn updateRoation(self: *Self, roation: vec.Vec3) void {
        self.roation = roation;
    }

    /// updates the current colour
    pub fn updateColour(self: *Self, colour: vec.Vec4) void {
        self.colour = colour;
    }

    /// updates the current scale
    pub fn updateScale(self: *Self, scale: vec.Vec3) void {
        self.scale = scale;
    }

    /// calls to the renderer to draw the object
    pub fn draw(self: Self) void {
        self.render.render_3d.render();
    }
};
