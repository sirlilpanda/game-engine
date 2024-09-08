const vec = @import("../math/vec.zig");
const Quaternion = @import("../math/quaternion.zig").Quaternion;
const PhysicsObject = @import("physics_object.zig").PhysicsObject;
const std = @import("std");
/// Describes the Collision interaction between 2 objects
pub const CollisionPoints = struct {
    A: vec.Vec3, // Furthest point of A into B
    B: vec.Vec3, // Furthest point of B into A
    normal: vec.Vec3, // B – A normalized
    depth: f32, // Length of B – A
    has_collision: bool,
};

/// Describes an objects location
pub const Transform = struct {
    position: vec.Vec3,
    scale: vec.Vec3,
    rotation: Quaternion,
};

pub const ColliderType = enum {
    sphere_collider,
    plane_collider,
};

pub const Collision = struct {
    object_A: PhysicsObject,
    object_B: PhysicsObject,
    points: ?CollisionPoints,
};

pub const Collider = union(ColliderType) {
    sphere_collider: SphereCollider,
    plane_collider: PlaneCollider,
};

pub const SphereCollider = struct {
    center: vec.Vec3,
    radius: f32,
};

pub const PlaneCollider = struct {
    normal: vec.Vec3,
    distance: f32,
};

const testCollisionFunc = fn (PhysicsObject, PhysicsObject) CollisionPoints;

pub fn testCollision(object_a: PhysicsObject, object_b: PhysicsObject) CollisionPoints {
    const test_functions = [2][2]?testCollisionFunc{
        [_]?testCollisionFunc{ testSphereSphere, testSpherePlane },
        [_]?testCollisionFunc{ null, null },
    };
    const swap: bool = @intFromEnum(object_b) > @intFromEnum(object_a);
    const points: CollisionPoints = if (swap) {
        {
            var p = test_functions[@intFromEnum(object_a)][@intFromEnum(object_b)].?(object_b, object_a);
            std.mem.swap(vec.Vec3, p.A, p.B);
            p.normal = p.normal.scale(-1);
            return p;
        }
    } else {
        test_functions[@intFromEnum(object_a)][@intFromEnum(object_b)].?(object_a, object_b);
    };

    return points;
}

pub fn testSphereSphere(object_a: PhysicsObject, object_b: PhysicsObject) CollisionPoints {
    _ = object_a;
    _ = object_b;
}

pub fn testSpherePlane(object_a: PhysicsObject, object_b: PhysicsObject) CollisionPoints {
    _ = object_a;
    _ = object_b;
}
