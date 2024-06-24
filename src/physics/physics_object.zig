const Object = @import("../objects/object.zig").Object;
const HitBox = @import("hit_box.zig");

pub const PhysicsObject = struct {
    const Self = @This();
    obj: *Object,
    hitbox: HitBox,

    pub fn init(obj: *Object) Self {
        return PhysicsObject{
            .obj = obj,
        };
    }
};
