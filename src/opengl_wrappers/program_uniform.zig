const cam = @import("../opengl_wrappers/camera.zig");
const obj = @import("../objects/object.zig");

pub const example_uniform = struct {
    const Self = @This();
    pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {
        _ = self;
        _ = camera;
        _ = object;
    }

    pub fn reload(self: Self) void {
        _ = self;
    }
};
