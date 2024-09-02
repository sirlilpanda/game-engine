const std = @import("std");
const render = @import("../opengl_wrappers/render.zig");
const vec = @import("../math/vec.zig");
const obj = @import("object.zig");
const file = @import("../file_loading/loadfile.zig");

const Allocator = std.mem.Allocator;
const renderCache = std.StringArrayHashMap(render.renderer);

//singletons are bad boo hoo
const maded: bool = false;

const ObjectServiceError = error{
    singleton_already_created,
};

pub const ObjectType = enum {
    dat,
    obj,
};

pub const ObjectService = struct {
    const Self = @This();

    cache: renderCache,
    allocator: Allocator,

    pub fn init(allocator: Allocator) ObjectServiceError!Self {
        if (maded) return ObjectServiceError.singleton_already_created;
        return Self{
            .cache = renderCache.init(allocator),
            .allocator = allocator,
        };
    }

    // ill change this to check the file extention later
    pub fn load(self: *Self, object_path: []const u8, obj_type: ObjectType) !obj.Object {
        //this is a get or put but that func scares me
        if (self.cache.contains(object_path)) {
            return obj.Object{
                .pos = vec.Vec3.zeros(),
                .roation = vec.Vec3.zeros(),
                .scale = vec.Vec3.ones(),
                .render = self.cache.get(object_path) orelse undefined, //[TODO] make a defaul obj for this to load
                .texture = null,
            };
        } else {
            var renderer = render.renderer.init();
            const obj_file: file.ObjectFile = switch (obj_type) {
                ObjectType.dat => try file.loadDatFile(self.allocator, object_path),
                ObjectType.obj => try file.loadObjFile(self.allocator, object_path),
            };

            try renderer.loadFile(obj_file);

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

    pub fn deinit(self: *Self) void {
        for (self.cache.values()) |renderer| {
            renderer.destroy();
        }

        self.cache.deinit();
    }
};
