const cam = @import("../opengl_wrappers/camera.zig");
const obj = @import("../objects/object.zig");
const uniform = @import("uniform.zig");
const std = @import("std");

const example_unifrom = std.log.scoped(.ExampleUnifrom);

/// an example uniform sturcture
pub const ExampleUniform = struct {
    const Self = @This();

    /// an example of the uniform
    example_uniform_var: uniform.Uniform = uniform.Uniform.init("unifrom_name"),
    example_uniform_var_2: uniform.Uniform = uniform.Uniform.init("unifrom_name_2"),

    /// this function computes all the uniform values for the object
    pub fn draw(self: Self, camera: *cam.Camera, object: obj.Object) void {
        example_unifrom.err("do not use this it does nothing, please create your own\n", .{});
        _ = self;
        _ = camera;
        _ = object;
    }

    /// this function is called when a program is reloaded
    pub fn reload(self: Self) void {
        example_unifrom.err("do not use this it does nothing, please create your own\n", .{});
        _ = self;
    }

    /// for if you unifrom wants some dynamic memory
    pub fn unload(self: Self) void {
        example_unifrom.err("do not use this it does nothing, please create your own\n", .{});
        _ = self;
    }
};
