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

    colour_set_string: [38:0]u8 = colour_set_string_fmt.*,
    colour_end_string: [4:0]u8 = colour_end_string_fmt.*,

    const colour_set_string_fmt = "\x1B[38;2;{d};{d};{d}m\x1B[48;2;{d};{d};{d}m";
    const colour_end_string_fmt = "\x1B[0m";

    pub fn init() Self {
        var self = Self{
            .colour_fg = Colour.white(),
            .colour_bg = Colour.black(),
        };

        self.updateColourSetString();
        return self;
    }

    /// sets the forground/text colour
    pub fn setFgColour(self: *Self, colour: Colour) void {
        self.colour_fg = colour;
        self.updateColourSetString();
    }

    /// sets background colour
    pub fn setBgColour(self: *Self, colour: Colour) void {
        self.colour_bg = colour;
        self.updateColourSetString();
    }

    fn updateColourSetString(self: *Self) void {
        _ = std.fmt.bufPrint(
            &self.colour_set_string,
            colour_set_string_fmt,
            .{
                self.colour_fg.r,
                self.colour_fg.g,
                self.colour_fg.b,
                self.colour_bg.r,
                self.colour_bg.g,
                self.colour_bg.b,
            },
        ) catch |err| std.debug.print("couldnt update colour set string error {any}\n", .{err});

        // std.debug.print("buf = {s}\n", .{self.colour_set_string});
    }

    // /// prints a given string with the set colours
    // pub fn print(self: Self, comptime format: []const u8, args: anytype) void {
    //     std.debug.print(self.colour_set_string);
    //     std.debug.print(format, args);
    //     std.debug.print(self.colour_end_string, .{});
    // }

    pub fn getColourSetString(self: Self) [50:0]u8 {
        return self.colour_set_string;
    }

    pub fn getColourEndString(self: Self) [50:0]u8 {
        return self.colour_end_string;
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

    /// idea fmt = {f:red|b:blue} will set the forground and back ground colour
    /// i will implement this later, current fmt start will print the start string
    /// and fmt end will print the end string
    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        if (fmt.len > 0) {
            if (std.mem.eql(u8, fmt, "start")) {
                try writer.print(
                    colour_set_string_fmt,
                    .{
                        self.colour_fg.r,
                        self.colour_fg.g,
                        self.colour_fg.b,
                        self.colour_bg.r,
                        self.colour_bg.g,
                        self.colour_bg.b,
                    },
                );
            } else if (std.mem.eql(u8, fmt, "end")) {
                try writer.print(colour_end_string_fmt, .{});
            } else {
                try writer.print(
                    "{any}",
                    .{self},
                );
            }
        } else {
            try writer.print(
                "{any}",
                .{self},
            );
        }
    }
};
