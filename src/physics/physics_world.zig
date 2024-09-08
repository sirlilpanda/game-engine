const std = @import("std");
const vec = @import("../math/vec.zig");
const PhysicsObject = @import("physics_object.zig").PhysicsObject;

pub const PhysicsWorld = struct {
    const Self = @This();
    objects: std.ArrayList(PhysicsObject),
    gravity: vec.Vec3 = vec.init3(0, -9.81, 0),

    pub fn init(allocator: std.mem.Allocator) PhysicsWorld {
        return Self{
            .objects = std.ArrayList(PhysicsObject).init(allocator),
        };
    }

    pub fn step(self: *Self, time_step: f32) void {
        // std.debug.print("step : {}\n", .{time_step});
        for (self.objects.items, 0..) |_, index| {
            var obj = &self.objects.items[index];

            self.objects.items[index].force = obj.force.add(self.gravity.scale(obj.mass));
            // std.debug.print("force : {}\n", .{self.objects.items[index].force});

            self.objects.items[index].velocity = obj.velocity.add(obj.force.scale((1 / obj.mass) * time_step));
            // std.debug.print("velocity : {}\n", .{obj.force});

            self.objects.items[index].obj.updatePos(obj.obj.pos.add(obj.velocity.scale(time_step)));
            // std.debug.print("obj : {}\n", .{self.objects.items[index].obj.pos});

            self.objects.items[index].force = vec.Vec3.zeros();
            // std.debug.print("force : {}\n", .{self.objects.items[index].force});
        }
    }
};
