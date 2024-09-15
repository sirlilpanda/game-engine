//! this is a service for caching already loaded objects
const std = @import("std");
const render = @import("../opengl_wrappers/render.zig");
const vec = @import("../math/vec.zig");
const obj = @import("object.zig");
const file = @import("../file_loading/loadfile.zig");

const Allocator = std.mem.Allocator;

const RenderCacheType = struct {
    renderer: render.Renderer,
    bounding_box_max_point: vec.Vec3,
    bounding_box_min_point: vec.Vec3,
};

const renderCache = std.StringArrayHashMap(RenderCacheType);

const object_loader_logger = std.log.scoped(.ObjectService);

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
        object_loader_logger.info("trying to load : {s}", .{object_path});
        //this is a get or put but that func scares me
        if (self.cache.contains(object_path)) {
            object_loader_logger.info("renderer found, using cached one", .{});

            const cached = self.cache.get(object_path) orelse undefined;

            return obj.Object{
                .pos = vec.Vec3.zeros(),
                .roation = vec.Vec3.zeros(),
                .scale = vec.Vec3.ones(),
                .render = cached.renderer,
                .texture = null,
                .bounding_box_max_point = cached.bounding_box_max_point,
                .bounding_box_min_point = cached.bounding_box_min_point,
            };
        } else {
            object_loader_logger.info("renderer not found, creating new one", .{});
            var renderer = render.Renderer{
                .render_3d = render.Render3d.init(),
            };
            const obj_file: file.ObjectFile = switch (obj_type) {
                ObjectType.dat => file.loadDatFile(self.allocator, object_path),
                ObjectType.obj => file.loadObjFile(self.allocator, object_path),
            } catch |err| {
                object_loader_logger.err("tried to load {s} got error {any}", .{ object_path, err });
                return err;
            };

            try renderer.render_3d.loadFile(obj_file);

            try self.cache.put(object_path, RenderCacheType{
                .renderer = renderer,
                .bounding_box_max_point = obj_file.bounding_box_max_point,
                .bounding_box_min_point = obj_file.bounding_box_min_point,
            });

            object_loader_logger.info("renderer created from {s} and now in cache", .{object_path});

            return obj.Object{
                .pos = vec.Vec3.zeros(),
                .roation = vec.Vec3.zeros(),
                .scale = vec.Vec3.ones(),
                .render = renderer,
                .texture = undefined,
                .bounding_box_max_point = obj_file.bounding_box_max_point,
                .bounding_box_min_point = obj_file.bounding_box_min_point,
            };
        }
    }

    /// frees all the memory
    pub fn deinit(self: *Self) void {
        object_loader_logger.info("unloading object loader service", .{});
        for (self.cache.values()) |renderer_cache_type| {
            renderer_cache_type.renderer.render_3d.destroy();
        }

        object_loader_logger.info("unloading object loader service cache", .{});
        self.cache.deinit();
    }
};
