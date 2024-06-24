const Vec = @import("../math/vec.zig");

pub const BoxShape = enum {
    cube,
    sphere,
    plane, //i cant image this would be hard to make
    capsule,
    soup, // will need to steal vertex data from gpu for this
};

pub const Box = struct {
    const Self = @This();
    shape: BoxShape,
    // will probaly replace with a quaternion when i work out what the fuck they are
    offset: Vec.Vec3,
    rotation: Vec.Vec3,
};

pub const HitBox = struct {
    const Self = @This();
    boxes: []Box,

    pub fn init(boxes: []Box) Self {
        return HitBox{
            .boxes = boxes,
        };
    }
    pub fn intersect(self: Self, box: Self) bool {
        _ = self;
        _ = box;
        return true;
    }
};
