const std = @import("std");

pub fn structCheck(comptime type_to_check: type, comptime example_interface_type: type) bool {
    inline for (@typeInfo(type_to_check).Struct.decls) |declaration| {
        if (comptime !trait_check(example_interface_type, declaration.name)) return false;
    }

    inline for (@typeInfo(type_to_check).Struct.fields) |field| {
        if (comptime !trait_check(example_interface_type, field.name)) return false;
    }

    return true;
}

pub fn interfaceCheck(comptime type_to_check: type, comptime example_interface_type: type) bool {
    inline for (@typeInfo(example_interface_type).Struct.decls) |declaration| {
        if (comptime !trait_check(type_to_check, declaration.name)) {
            @compileLog(@typeName(type_to_check) ++ " doesnt have " ++ declaration.name);
            return false;
        }
    }
    return true;
}

// to check if something has a declaration
pub fn trait_check(comptime type_to_check: type, comptime trait_name: []const u8) bool {
    inline for (@typeInfo(type_to_check).Struct.decls) |declaration| {
        if (comptime std.mem.eql(u8, declaration.name, trait_name)) return true;
    }
    return false;
}

pub fn field_check(comptime type_to_check: type, comptime field_name: []const u8) bool {
    inline for (@typeInfo(type_to_check).Struct.fields) |field| {
        if (comptime std.mem.eql(u8, field.name, field_name)) return true;
    }
    return false;
}
