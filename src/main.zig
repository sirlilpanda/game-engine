const BasicApp = @import("app/app.zig").BasicApp;
const basic = @import("app/basic_program.zig");
const std = @import("std");
const shader = @import("/opengl_wrappers/shader.zig");
const tex = @import("opengl_wrappers/texture.zig");
const gl = @import("gl");
const glfw = @import("mach-glfw");
const vec = @import("math/vec.zig");
const obj = @import("objects/object.zig");
const Random = @import("std").rand.Random;
const PhysicsObject = @import("physics/physics_object.zig").PhysicsObject;

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
    try init_objects(&app);

    std.debug.print("obj : {any}\n", .{app.programs.basic_program_texture.objects[0]});

    var angle: f32 = 0;
    var r_dir: f32 = 1;
    var r: f32 = 0;
    var b_dir: f32 = 1;
    var b: f32 = 0;
    var g_dir: f32 = 1;
    var g: f32 = 0;

    while (!app.shouldStop()) : ({
        angle += 0.001;
        r += 0.0003 * r_dir;
        b += 0.00013 * b_dir;
        g += 0.0007 * g_dir;
    }) {
        app.input();
        app.render();
        app.physics_thread.step(app.delta_time);

        // for (app.programs.basic_program_texture.objects, 0..) |_, dex| {
        //     if (dex != 0) {
        //         app.programs.basic_program_texture.objects[dex].?.updateRoation(vec.init3(angle + 90, angle + 180, angle + 23));
        //         app.programs.basic_program_texture.objects[dex].?.updateColour(vec.init4(r, b, g, 1));
        //     }
        // }
        std.debug.print("fps : {}]\r", .{app.fps()});
        // std.debug.print("cam {}\n", app.camera.eye);
        if (r > 1) r_dir = -1;
        if (r < 0) r_dir = 1;
        if (b > 1) b_dir = -1;
        if (b < 0) b_dir = 1;
        if (g > 1) g_dir = -1;
        if (g < 0) g_dir = 1;

        if (app.window.window.getKey(glfw.Key.f) == glfw.Action.press) reset_objects(&app);
    }

    app.free();
}

pub fn init_objects(app: *BasicApp) !void {
    app.programs.basic_program_texture.objects[0] = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    var plane = try app.obj_loader_service.load("objects/plane.obj", .obj);
    plane.texture = tex.Texture.init(app.alloc, "textures/rgb.tga") catch null;
    std.debug.print("plane\n", .{});
    plane.pos = vec.init3(10.0, 2.0, 4.0);

    var cube = try app.obj_loader_service.load("objects/cube.obj", .obj);
    cube.texture = try tex.Texture.init(app.alloc, "textures/white.tga");
    cube.scale = vec.init3(30000, 30000, 30000);

    var crab = try app.obj_loader_service.load("objects/Crab.obj", .obj);
    crab.texture = try tex.Texture.init(app.alloc, "textures/Crab_D.tga");

    var index: usize = 3;
    while (index < app.programs.basic_program_texture.objects.len) : (index += 1) {
        var ject: obj.Object = undefined;

        ject = crab;
        ject.pos = vec.init3(
            2 * @sin(@as(f32, @floatFromInt(index))),
            2 * @cos(@as(f32, @floatFromInt(index))),
            0,
        );
        app.programs.basic_program_texture.objects[index] = ject;

        var phys_crab = PhysicsObject.init(&app.programs.basic_program_texture.objects[index].?, 12);
        phys_crab.velocity = vec.init3(0, 2, 3);
        try app.physics_thread.objects.append(phys_crab);
    }

    // for (app.programs.basic_program_texture.objects, 3..) |_, dex| {}

    app.programs.basic_program_texture.objects[0] = cube;
    // if i want to overide back ground colours
    app.programs.basic_program_texture.objects[0].?.colour = vec.init4(2, 2, 2, 1);
    app.programs.basic_program_texture.objects[0].?.texture = try tex.Texture.init(app.alloc, "textures/sky_box_2.tga");

    // app.programs.basic_program_texture.objects[1] = cube;
    // app.programs.basic_program_texture.objects[1].?.scale = vec.init3(1, 1, 1);
    // app.programs.basic_program_texture.objects[1].?.colour = vec.init4(1, 0, 1, 1);
    // app.programs.basic_program_texture.objects[1] = try app.obj_loader_service.load("objects/4V5T.obj", .obj);
    // app.programs.basic_program_texture.objects[1].?.texture = tex.Texture.init(app.alloc, "textures/rgb.tga") catch null;
    // app.programs.basic_program_texture.objects[1].?.colour = vec.init4(0.7, 0.7, 0.7, 1);
    app.programs.basic_program_texture.objects[2] = plane;

    app.programs.basic_program_texture.objects[3] = plane;
    app.programs.basic_program_texture.objects[3].?.pos = vec.init3(14.0, 2.0, 4.0);
    app.programs.basic_program_texture.objects[3].?.texture = try tex.Texture.init(app.alloc, "textures/sky_box_2.tga");

    app.programs.basic_program_texture.objects[4] = plane;
    app.programs.basic_program_texture.objects[4].?.pos = vec.init3(14.0, 2.0, 6.0);
    app.programs.basic_program_texture.objects[4].?.texture = try tex.Texture.init(app.alloc, "textures/pink_smol.tga");
}

pub fn reset_objects(app: *BasicApp) void {
    var index: usize = 3;
    while (index < app.programs.basic_program_texture.objects.len) : (index += 1) {
        app.programs.basic_program_texture.objects[index].?.updatePos(vec.init3(
            2 * @sin(@as(f32, @floatFromInt(index))),
            2 * @cos(@as(f32, @floatFromInt(index))),
            0,
        ));
    }

    for (app.physics_thread.objects.items, 0..) |_, i| {
        app.physics_thread.objects.items[i].velocity = vec.init3(0, 9, 5);
    }

    app.programs.basic_program_texture.objects[2].?.pos = vec.init3(10.0, 2.0, 4.0);
    app.programs.basic_program_texture.objects[3].?.pos = vec.init3(14.0, 2.0, 4.0);
    app.programs.basic_program_texture.objects[4].?.pos = vec.init3(14.0, 2.0, 6.0);
}
