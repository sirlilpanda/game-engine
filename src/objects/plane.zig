const vec = @import("../math/vec.zig");
const mat = @import("../math/matrix.zig");
const uni = @import("../opengl_wrappers/uniform.zig");
const cam = @import("../opengl_wrappers/camera.zig");
const ren = @import("../opengl_wrappers/render.zig");
const file = @import("../file_loading/loadfile.zig");

const Object = @import("object.zig").Object;
const std = @import("std");

const plane = file.ObjectFile{ .verts = f32{
    0.0, 0.0, 0.0,
    1.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    1.0, 1.0, 0.0,
}, .normals = f32{
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
}, .elemnets = u32{
    0, 1, 2,
    1, 3, 2,
}, .texture = f32{
    0.0, 0.0,
    1.0, 0.0,
    0.0, 1.0,
    1.0, 1.0,
} };
