const std = @import("std");
const vec = @import("../math/vec.zig");
const Colour = @import("../utils/colour.zig").Colour;
/// allows coloured printing to std.debug / std error
pub const colour_set_string_fg_fmt = "\x1B[38;2;{d};{d};{d}m";
pub const colour_set_string_bg_fmt = "\x1B[48;2;{d};{d};{d}m";
pub const colour_set_string_fmt = colour_set_string_fg_fmt ++ colour_set_string_bg_fmt;

pub const colour_end_string_fmt = "\x1B[0m";

/// a coloured string type
pub const String = struct {
    const Self = @This();
    /// this is the colour behind the text
    colour_bg: ?Colour = null,
    /// this is the colour of the text
    colour_fg: ?Colour = null,
    /// the string that gets printed
    /// allowing this to be optional to allow for using this to colour other objects
    string: ?[]const u8,

    /// creates a new string with the defualt windows terminal colours
    pub fn init(string: []const u8) Self {
        return Self{
            .string = string,
        };
    }

    /// useful if you want to colour some other formatter
    pub fn initNoString() Self {
        return Self{
            .string = null,
        };
    }

    /// creates a new string with a given forground colour
    pub fn initWfg(fg_colour: Colour, string: []const u8) Self {
        return Self{
            .colour_fg = fg_colour,
            .string = string,
        };
    }

    /// creates a new string with a given background colour
    pub fn initWbg(bg_colour: Colour, string: []const u8) Self {
        return Self{
            .colour_bg = bg_colour,
            .string = string,
        };
    }

    /// creates a new string with a given colours
    pub fn initWColour(fg_colour: Colour, bg_colour: Colour, string: []const u8) Self {
        return Self{
            .colour_fg = fg_colour,
            .colour_bg = bg_colour,
            .string = string,
        };
    }

    /// sets the forground/text colour
    pub fn setFgColour(self: *Self, colour: Colour) void {
        self.colour_fg = colour;
    }

    /// sets background colour
    pub fn setBgColour(self: *Self, colour: Colour) void {
        self.colour_bg = colour;
    }

    /// gets the string
    pub fn getString(self: Self) []const u8 {
        return self.string;
    }

    /// checks if two colour strings are equal
    pub fn eq(self: Self, other: Self) bool {
        return std.mem.eql(u8, self.string, other.string);
    }

    /// idea fmt = {f:red|b:blue} will set the forground and back ground colour
    /// i will implement this later, current fmt start will print the start string
    /// and fmt end will print the end string
    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;

        if (fmt.len == 0) {
            if (self.string) |string| {
                if (self.colour_fg) |colour| {
                    try writer.print(
                        colour_set_string_fg_fmt,
                        .{
                            colour.r,
                            colour.g,
                            colour.b,
                        },
                    );
                }
                if (self.colour_bg) |colour| {
                    try writer.print(
                        colour_set_string_bg_fmt,
                        .{
                            colour.r,
                            colour.g,
                            colour.b,
                        },
                    );
                }

                try writer.print("{s}" ++ colour_end_string_fmt, .{string});
            }
        } else if (std.mem.eql(u8, fmt, "start")) {
            if (self.colour_fg) |colour| {
                try writer.print(
                    colour_set_string_fg_fmt,
                    .{
                        colour.r,
                        colour.g,
                        colour.b,
                    },
                );
            }
            if (self.colour_bg) |colour| {
                try writer.print(
                    colour_set_string_bg_fmt,
                    .{
                        colour.r,
                        colour.g,
                        colour.b,
                    },
                );
            }
        } else if (std.mem.eql(u8, fmt, "end")) {
            try writer.print(colour_end_string_fmt, .{});
        } else {
            try writer.print("{?s}", .{self.string});
        }
    }
};
