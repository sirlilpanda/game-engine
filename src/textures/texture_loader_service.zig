//! this is a service for caching already loaded Textures
const std = @import("std");
const Texture = @import("texture.zig").Texture;
const Allocator = std.mem.Allocator;
const TextureCache = std.StringArrayHashMap(Texture);

const texture_loader_logger = std.log.scoped(.TextureService);

/// singletons are bad boo hoo
const maded: bool = false;

/// service for loading and cachine Textures
/// a method to remove Textures from the cache
/// will be implmented later
pub const TextureService = struct {
    const Self = @This();

    /// the cache
    cache: TextureCache,
    /// the allocator for loading the new Textures
    allocator: Allocator,

    pub fn init(allocator: Allocator) Self {
        return Self{
            .cache = TextureCache.init(allocator),
            .allocator = allocator,
        };
    }

    /// loads a new texture, and wont open a file unless its not already in the cache
    pub fn load(self: *Self, texture_path: []const u8) !Texture {
        // ill change this to check the file extention later
        texture_loader_logger.info("trying to load : {s}", .{texture_path});
        //this is a get or put but that func scares me
        if (self.cache.contains(texture_path)) {
            texture_loader_logger.info("texture found, using cached one", .{});

            return self.cache.get(texture_path) orelse undefined; // should always exists
        } else {
            texture_loader_logger.info("texture not found, creating new one", .{});

            const texture: Texture = Texture.init(self.allocator, texture_path) catch |err| {
                texture_loader_logger.err("tried to load {s} got error {any}", .{ texture_path, err });
                return err;
            };

            try self.cache.put(texture_path, texture);
            texture_loader_logger.info("texture {s} created and now in cache", .{texture_path});
            return texture;
        }
    }

    /// frees all the memory
    pub fn deinit(self: *Self) void {
        texture_loader_logger.info("unloading texture loader service", .{});
        for (self.cache.values()) |texture| {
            texture.destroy();
        }
        texture_loader_logger.info("unloading texture loader service cache", .{});
        self.cache.deinit();
    }
};
