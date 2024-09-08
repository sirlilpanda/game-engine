const Object = @import("../objects/object.zig").Object;

const vec = @import("../math/vec.zig");
const Collider = @import("collision.zig").Collider;

pub const PhysicsObject = struct {
    const Self = @This();
    obj: *Object,
    velocity: vec.Vec3,
    force: vec.Vec3,
    mass: f32,
    collider: Collider,

    pub fn init(obj: *Object, mass: f32) Self {
        return PhysicsObject{
            .obj = obj,
            .velocity = vec.Vec3.zeros(),
            .force = vec.Vec3.zeros(),
            .mass = mass,
            .collider = undefined,
        };
    }
};
