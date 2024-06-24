const std = @import("std");
const vec = @import("../math/vec.zig");

pub const Colour = struct {
    const Self = @This();

    r: u8,
    g: u8,
    b: u8,

    pub fn custom(r: u8, g: u8, b: u8) Self {
        return Self{ .r = r, .g = g, .b = b };
    }
    pub fn red() Self {
        return Self{ .r = 255, .g = 0, .b = 0 };
    }
    pub fn orange() Self {
        return Self{ .r = 255, .g = 128, .b = 0 };
    }
    pub fn yellow() Self {
        return Self{ .r = 255, .g = 255, .b = 0 };
    }
    pub fn lightGreen() Self {
        return Self{ .r = 128, .g = 255, .b = 0 };
    }
    pub fn green() Self {
        return Self{ .r = 0, .g = 255, .b = 0 };
    }
    pub fn cyan() Self {
        return Self{ .r = 0, .g = 255, .b = 128 };
    }
    pub fn lightBlue() Self {
        return Self{ .r = 0, .g = 128, .b = 255 };
    }
    pub fn blue() Self {
        return Self{ .r = 0, .g = 0, .b = 255 };
    }
    pub fn darkPurple() Self {
        return Self{ .r = 128, .g = 0, .b = 255 };
    }
    pub fn purple() Self {
        return Self{ .r = 170, .g = 0, .b = 255 };
    }
    pub fn pink() Self {
        return Self{ .r = 128, .g = 0, .b = 255 };
    }
    pub fn magenta() Self {
        return Self{ .r = 255, .g = 0, .b = 255 };
    }
    pub fn black() Self {
        return Self{ .r = 0, .g = 0, .b = 0 };
    }
    pub fn white() Self {
        return Self{ .r = 255, .g = 255, .b = 255 };
    }
    pub fn grey() Self {
        return Self{ .r = 128, .g = 128, .b = 128 };
    }
    pub fn greyScale(scale: u8) Self {
        // 255 max
        return Self{ .r = scale, .g = scale, .b = scale };
    }
};

pub const ColourPrinter = struct {
    const Self = @This();
    colour_bg: Colour,
    colour_fg: Colour,

    pub fn init() Self {
        return Self{
            .colour_fg = Colour.white(),
            .colour_bg = Colour.black(),
        };
    }

    pub fn setFgColour(self: *Self, colour: Colour) void {
        self.colour_fg = colour;
    }

    pub fn setBgColour(self: *Self, colour: Colour) void {
        self.colour_bg = colour;
    }

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

    pub fn home(self: Self) void {
        _ = self;
        std.debug.print("\x1B[H", .{});
    }

    pub fn hideCursor(self: Self) void {
        _ = self;
        std.debug.print("\x1B[?25l", .{});
    }

    pub fn clear(self: Self) void {
        _ = self;
        std.debug.print("\x1B[0J", .{});
    }

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