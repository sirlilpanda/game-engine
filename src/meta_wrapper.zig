const std = @import("std");

pub fn trait_check(comptime type_to_check: type, comptime trait_name: []const u8) bool {
    inline for (@typeInfo(type_to_check).Struct.decls) |declaration| {
        if (comptime std.mem.eql(u8, declaration.name, trait_name)) return true;
    }
    return false;
}
