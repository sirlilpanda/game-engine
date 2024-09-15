const std = @import("std");
const vec = @import("../math/vec.zig");
const Colour = @import("../utils/colour.zig").Colour;
/// allows coloured printing to std.debug / std error
pub const colour_set_string_fmt = "\x1B[38;2;{d};{d};{d}m\x1B[48;2;{d};{d};{d}m";
pub const colour_end_string_fmt = "\x1B[0m";

/// a coloured string type
pub const String = struct {
    const Self = @This();
    /// this is the colour behind the text
    colour_bg: Colour,
    /// this is the colour of the text
    colour_fg: Colour,
    /// the string that gets printed
    string: []const u8,

    /// creates a new string with the defualt windows terminal colours
    pub fn init(string: []const u8) Self {
        return Self{
            .colour_fg = Colour.windowsTerminalFont(),
            .colour_bg = Colour.windowsTerminalBackground(),
            .string = string,
        };
    }

    /// creates a new string with a given forground colour
    pub fn initWfg(fg_colour: Colour, string: []const u8) Self {
        return Self{
            .colour_fg = fg_colour,
            .colour_bg = Colour.windowsTerminalBackground(),
            .string = string,
        };
    }

    /// creates a new string with a given background colour
    pub fn initWbg(bg_colour: Colour, string: []const u8) Self {
        return Self{
            .colour_fg = Colour.windowsTerminalFont(),
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
            try writer.print(
                colour_set_string_fmt ++ "{s}" ++ colour_end_string_fmt,
                .{
                    self.colour_fg.r,
                    self.colour_fg.g,
                    self.colour_fg.b,
                    self.colour_bg.r,
                    self.colour_bg.g,
                    self.colour_bg.b,
                    self.string,
                },
            );
        } else {
            try writer.print("{s}", .{self.string});
        }
    }
};
