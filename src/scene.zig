const std = @import("std");
const meta = @import("meta_wrapper.zig");
const gl = @import("gl");
const Object = @import("objects/object.zig").Object;
const Camera = @import("opengl_wrappers/camera.zig").Camera;
// const Program = @import("opengl_wrappers/program.zig")

// if i make them pointers then they can act more as an "interface"
// rather then have differnt arrays for differnt object types
const ObjectArray = std.ArrayList(&Object);
// const LightArray = std.ArrayList(Object);

const Scene = struct {
    const Self = @This();
    objects: ObjectArray,
    // lights : objectArray,

    pub fn render(self: Self, camera: Camera, program: anytype) void {
        if (!meta.trait_check(@TypeOf(program.unifroms), "draw"))
            @compileError("program uniforms does not have draw method");

        if (!meta.trait_check(@TypeOf(program.unifroms), "draw"))
            @compileError("program uniforms does not have draw method");

        for (self.objects.items) |object| {
            program.unifroms.draw(camera, object);
        }
        gl.flush();
    }
};
