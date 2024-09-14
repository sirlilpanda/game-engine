const BasicApp = @import("app/app.zig").BasicApp;
const basic = @import("app/basic_program.zig");
const std = @import("std");
const shader = @import("/opengl_wrappers/shader.zig");
const vec = @import("math/vec.zig");
const Quaternion = @import("math/quaternion.zig").Quaternion;
const obj = @import("objects/object.zig");
const Random = @import("std").rand.Random;

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

    // has to be done this way to ensure that opengl is init'ed
    app.programs.basic_program_texture = try basic.createBasicProgramWTexture(allocator);
    app.programs.basic_program_texture.camera = &app.camera;

    app.programs.basic_program_texture.objects[0] = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    var plane = try app.obj_loader_service.load("objects/plane.obj", .obj);
    plane.texture = try app.texture_loader_service.load("textures/sky_box_.tga");
    plane.pos = vec.init3(10.0, 2.0, 4.0);

    var cube = try app.obj_loader_service.load("objects/cube.obj", .obj);
    cube.texture = try app.texture_loader_service.load("textures/sky_box_.tga");
    cube.scale = vec.init3(30000, 30000, 30000);

    var crab = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    crab.texture = try app.texture_loader_service.load("textures/Crab_D.tga");

    var sphere = try app.obj_loader_service.load("objects/donut.obj", .obj);
    sphere.texture = try app.texture_loader_service.load("textures/Earth.bmp");
    for (app.programs.basic_program_texture.objects, 0..) |_, dex| {
        var ject: obj.Object = undefined;

        ject = crab;
        ject.pos = vec.init3(
            2 * @sin(@as(f32, @floatFromInt(dex))),
            0,
            2 * @cos(@as(f32, @floatFromInt(dex))),
        );
        ject.roation = vec.init3(
            2 * @sin(@as(f32, @floatFromInt(dex))),
            2 * @cos(@as(f32, @floatFromInt(dex))),
            0,
        );
        app.programs.basic_program_texture.objects[dex] = ject;
    }

    app.programs.basic_program_texture.objects[0] = cube;
    // if i want to overide back ground colours
    app.programs.basic_program_texture.objects[0].?.colour = vec.init4(2, 2, 2, 1);

    app.programs.basic_program_texture.objects[1] = sphere;
    app.programs.basic_program_texture.objects[1].?.pos = vec.init3(0, -0.2, 0);

    app.programs.basic_program_texture.objects[1].?.scale = vec.init3(1, 1, 1);
    app.programs.basic_program_texture.objects[1].?.colour = vec.init4(1, 0, 1, 1);
    // app.programs.basic_program_texture.objects[1] = try app.obj_loader_service.load("objects/4V5T.obj", .obj);
    // app.programs.basic_program_texture.objects[1].?=.texture = app.texture_loader_service.load("textures/rgb.tga") catch null;
    // app.programs.basic_program_texture.objects[1].?.colour = vec.init4(0.7, 0.7, 0.7, 1);

    var angle: f32 = 0;

    while (!app.shouldStop()) : ({
        angle += 0.001;
    }) {
        // gets the input
        app.input();
        // renders all the objects
        app.render();

        var dex: usize = 2;
        // rotate them fucken carbs
        while (dex < app.programs.basic_program_texture.objects.len) : (dex += 1) {
            app.programs.basic_program_texture.objects[dex].?.pos = vec.init3(
                2 * @sin(@as(f32, @floatFromInt(dex)) + angle),
                0,
                2 * @cos(@as(f32, @floatFromInt(dex)) + angle),
            );
            app.programs.basic_program_texture.objects[dex].?.roation = vec.init3(
                2 * @sin(@as(f32, @floatFromInt(dex)) + angle),
                2 * @cos(@as(f32, @floatFromInt(dex)) + angle),
                0,
            );
        }

        std.debug.print("fps : {d:.4}    \r", .{app.fps()});
        // std.debug.print("cam {}\n", app.camera.eye);
    }

    // frees the app
    app.free();
}
