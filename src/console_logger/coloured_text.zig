const std = @import("std");
const vec = @import("../math/vec.zig");
const Colour = @import("../utils/colour.zig").Colour;
/// allows coloured printing to std.debug / std error
pub const ColourPrinter = struct {
    const Self = @This();
    /// this is the colour behind the text
    colour_bg: Colour,
    /// this is the colour of the text
    colour_fg: Colour,

    pub fn init() Self {
        return Self{
            .colour_fg = Colour.white(),
            .colour_bg = Colour.black(),
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

    /// prints a given string with the set colours
    pub fn print(self: Self, comptime format: []const u8, args: anytype) void {
        std.debug.print(
            "\x1B[38;2;{d};{d};{d}m\x1B[48;2;{d};{d};{d}m",
            .{
                self.colour_fg.r,
                self.colour_fg.g,
                self.colour_fg.b,
                self.colour_bg.r,
                self.colour_bg.g,
                self.colour_bg.b,
            },
        );
        std.debug.print(format, args);
        std.debug.print("\x1B[0m", .{});
    }

    /// returns the cursor back to the home / 0, 0 pos on the terminal
    pub fn home(self: Self) void {
        _ = self;
        std.debug.print("\x1B[H", .{});
    }

    /// hides the cussor on the termianl
    pub fn hideCursor(self: Self) void {
        _ = self;
        std.debug.print("\x1B[?25l", .{});
    }

    /// clears the terminal
    pub fn clear(self: Self) void {
        _ = self;
        std.debug.print("\x1B[0J", .{});
    }

    /// prints a vector 3 with differnt colours, make its easier to read
    /// this will probaly be moved to vec3 though
    pub fn vec3(self: *Self, v: vec.Vec3) void {
        const old_fg = self.colour_fg;

        std.debug.print("{{", .{});
        self.setFgColour(Colour.red());
        self.print("x : {d:.3},", .{v.x()});
        self.setFgColour(Colour.yellow());
        self.print("y : {d:.3},", .{v.y()});
        self.setFgColour(Colour.green());
        self.print("z : {d:.3},", .{v.z()});
        std.debug.print("}}", .{});

        self.setFgColour(old_fg);
    }
};
