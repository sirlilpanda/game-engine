const App = @import("app.zig");
const basic = @import("basic.zig");
const std = @import("std");
const shader = @import("/opengl_wrappers/shader.zig");
const tex = @import("opengl_wrappers/texture.zig");
const gl = @import("gl");
const glfw = @import("mach-glfw");
const vec = @import("math/vec.zig");
const obj = @import("objects/object.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try App.BasicApp.init(
        1920,
        1080,
        allocator,
        undefined,
    );

    app.programs.basic_program_texture = try basic.createBasicProgramWTexture(allocator);
    app.programs.basic_program_texture.camera = &app.camera;
    std.debug.print("loading\n", .{});
    app.programs.basic_program_texture.objects[0] = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    var plane = try app.obj_loader_service.load("objects/plane.obj", .obj);
    plane.texture = try tex.Texture.init(allocator, "textures/sky_box_2.tga");
    plane.pos = vec.init3(10.0, 2.0, 4.0);
    var cube = try app.obj_loader_service.load("objects/cube.obj", .obj);
    cube.texture = try tex.Texture.init(allocator, "textures/sky_box_2.tga");

    var crab = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    crab.texture = try tex.Texture.init(allocator, "textures/Crab_D.tga");
    for (app.programs.basic_program_texture.objects, 0..) |_, dex| {
        var ject: obj.Object = undefined;

        ject = crab;
        ject.pos = vec.init3(
            5 * @sin(@as(f32, @floatFromInt(dex))),
            5 * @cos(@as(f32, @floatFromInt(dex))),
            0,
        );
        app.programs.basic_program_texture.objects[dex] = ject;
    }
    app.programs.basic_program_texture.objects[0] = cube;
    app.programs.basic_program_texture.objects[1] = plane;

    const light: vec.Vec4 = vec.init4(5, 10, 7, 1);
    const lighteye: vec.Vec4 = app.camera.view_matrix.MulVec(light);
    app.programs.basic_program_texture.uniforms.lgtUniform.sendVec4(lighteye);
    app.programs.basic_program_texture.uniforms.textureUniform.send1Uint(0);

    std.debug.print("obj : {any}\n", .{app.programs.basic_program_texture.objects[0]});

    while (!app.shouldStop()) {
        app.input();
        app.render();
    }

    app.free();
}
