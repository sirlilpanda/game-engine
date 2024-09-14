//! this is a service for caching already loaded objects
const std = @import("std");
const render = @import("../opengl_wrappers/render.zig");
const vec = @import("../math/vec.zig");
const obj = @import("object.zig");
const file = @import("../file_loading/loadfile.zig");

const Allocator = std.mem.Allocator;
const renderCache = std.StringArrayHashMap(render.Renderer);

/// currnet support object types
pub const ObjectType = enum {
    dat,
    obj,
};

/// service for loading and cachine objects
/// a method to remove objects from the cache
/// will be implmented later
pub const ObjectService = struct {
    const Self = @This();

    /// the cache
    cache: renderCache,
    /// the allocator for loading the new objects
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .cache = renderCache.init(allocator),
            .allocator = allocator,
        };
    }

    /// loads a new object, and wont open a file unless its not already in the cache
    pub fn load(self: *Self, object_path: []const u8, obj_type: ObjectType) !obj.Object {
        // ill change this to check the file extention later
        std.debug.print("[INFO] trying to load : {s}\n", .{object_path});
        //this is a get or put but that func scares me
        if (self.cache.contains(object_path)) {
            std.debug.print("[INFO] renderer found, using cached one\n", .{});

            return obj.Object{
                .pos = vec.Vec3.zeros(),
                .roation = vec.Vec3.zeros(),
                .scale = vec.Vec3.ones(),
                .render = self.cache.get(object_path) orelse undefined, //[TODO] make a defaul obj for this to load
                .texture = null,
            };
        } else {
            std.debug.print("[INFO] renderer not found, creating new one\n", .{});
            var renderer = render.Renderer{
                .render_3d = render.Render3d.init(),
            };
            const obj_file: file.ObjectFile = switch (obj_type) {
                ObjectType.dat => file.loadDatFile(self.allocator, object_path),
                ObjectType.obj => file.loadObjFile(self.allocator, object_path),
            } catch |err| {
                std.debug.print("[ERROR] tried to load {s} got error {any}\n", .{ object_path, err });
                return err;
            };

            try renderer.render_3d.loadFile(obj_file);

            try self.cache.put(object_path, renderer);

            return obj.Object{
                .pos = vec.Vec3.zeros(),
                .roation = vec.Vec3.zeros(),
                .scale = vec.Vec3.ones(),
                .render = renderer,
                .texture = undefined,
            };
        }
    }

    /// frees all the memory
    pub fn deinit(self: *Self) void {
        std.debug.print("[INFO] unloading object loader service\n", .{});
        for (self.cache.values()) |renderer| {
            renderer.render_3d.destroy();
        }

        self.cache.deinit();
    }
};
