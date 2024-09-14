//! this is a service for caching already loaded Textures
const std = @import("std");
const Texture = @import("texture.zig").Texture;

const Allocator = std.mem.Allocator;
const TextureCache = std.StringArrayHashMap(Texture);

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
        std.debug.print("[INFO] trying to load : {s}\n", .{texture_path});
        //this is a get or put but that func scares me
        if (self.cache.contains(texture_path)) {
            std.debug.print("[INFO] texture found, using cached one\n", .{});

            return self.cache.get(texture_path) orelse undefined; // should always exists
        } else {
            std.debug.print("[INFO] texture not found, creating new one\n", .{});

            const texture: Texture = Texture.init(self.allocator, texture_path) catch |err| {
                std.debug.print("[ERROR] tried to load {s} got error {any}\n", .{ texture_path, err });
                return err;
            };

            try self.cache.put(texture_path, texture);
            return texture;
        }
    }

    /// frees all the memory
    pub fn deinit(self: *Self) void {
        std.debug.print("[INFO] unloading texture loader service\n", .{});
        for (self.cache.values()) |texture| {
            texture.destroy();
        }

        self.cache.deinit();
    }
};
