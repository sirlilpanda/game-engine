const BasicApp = @import("app/app.zig").BasicApp;
const basic = @import("app/basic_program.zig");
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

    var app = try BasicApp.init(
        1920,
        1080,
        allocator,
        undefined,
    );

    app.programs.basic_program_texture = try basic.createBasicProgramWTexture(allocator);
    app.programs.basic_program_texture.camera = &app.camera;

    app.programs.basic_program_texture.objects[0] = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    var plane = try app.obj_loader_service.load("objects/plane.obj", .obj);
    plane.texture = tex.Texture.init(allocator, "textures/sky_box_.tga") catch null;
    std.debug.print("plane\n", .{});
    plane.pos = vec.init3(10.0, 2.0, 4.0);

    var cube = try app.obj_loader_service.load("objects/cube.obj", .obj);
    cube.texture = try tex.Texture.init(allocator, "textures/sky_box_.tga");
    cube.scale = vec.init3(10000, 10000, 10000);

    var crab = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    crab.texture = try tex.Texture.init(allocator, "textures/Crab_D.tga");

    for (app.programs.basic_program_texture.objects, 0..) |_, dex| {
        var ject: obj.Object = undefined;

        ject = crab;
        ject.pos = vec.init3(
            2 * @sin(@as(f32, @floatFromInt(dex))),
            2 * @cos(@as(f32, @floatFromInt(dex))),
            0,
        );
        app.programs.basic_program_texture.objects[dex] = ject;
    }

    app.programs.basic_program_texture.objects[0] = cube;
    app.programs.basic_program_texture.objects[1] = cube;
    app.programs.basic_program_texture.objects[1].?.scale = vec.init3(1, 1, 1);

    std.debug.print("obj : {any}\n", .{app.programs.basic_program_texture.objects[0]});

    while (!app.shouldStop()) {
        app.input();
        app.render();
        std.debug.print("fps : {}]\r", .{app.fps()});
    }

    app.free();
}
