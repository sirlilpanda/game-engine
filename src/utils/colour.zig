const std = @import("std");
const vec = @import("../math/vec.zig");
/// colour type
pub const Colour = struct {
    const Self = @This();

    r: u8,
    g: u8,
    b: u8,

    /// inits the struct with a custom colour
    pub fn custom(r: u8, g: u8, b: u8) Self {
        return Self{ .r = r, .g = g, .b = b };
    }

    /// inits the struct with a red colour
    pub fn red() Self {
        return Self{ .r = 255, .g = 0, .b = 0 };
    }

    /// inits the struct with a orange colour
    pub fn orange() Self {
        return Self{ .r = 255, .g = 128, .b = 0 };
    }

    /// inits the struct with a yellow colour
    pub fn yellow() Self {
        return Self{ .r = 255, .g = 255, .b = 0 };
    }

    /// inits the struct with a gold colour
    pub fn gold() Self {
        return Self{ .r = 255, .g = 200, .b = 0 };
    }

    /// inits the struct with a lightGreen colour
    pub fn lightGreen() Self {
        return Self{ .r = 128, .g = 255, .b = 0 };
    }

    /// inits the struct with a green colour
    pub fn green() Self {
        return Self{ .r = 0, .g = 255, .b = 0 };
    }

    /// inits the struct with a cyan colour
    pub fn cyan() Self {
        return Self{ .r = 0, .g = 255, .b = 128 };
    }

    /// inits the struct with a turquoise colour
    pub fn turquoise() Self {
        return Self{ .r = 0, .g = 255, .b = 190 };
    }

    /// inits the struct with a lightBlue colour
    pub fn lightBlue() Self {
        return Self{ .r = 0, .g = 128, .b = 255 };
    }

    /// inits the struct with a blue colour
    pub fn blue() Self {
        return Self{ .r = 0, .g = 0, .b = 255 };
    }

    /// inits the struct with a darkPurple colour
    pub fn darkPurple() Self {
        return Self{ .r = 128, .g = 0, .b = 255 };
    }

    /// inits the struct with a purple colour
    pub fn purple() Self {
        return Self{ .r = 170, .g = 0, .b = 255 };
    }

    /// inits the struct with a lightPurple colour
    pub fn lightPurple() Self {
        return Self{ .r = 196, .g = 78, .b = 255 };
    }

    /// inits the struct with a magenta colour
    pub fn magenta() Self {
        return Self{ .r = 255, .g = 0, .b = 255 };
    }

    /// inits the struct with a pink colour
    pub fn pink() Self {
        return Self{ .r = 255, .g = 0, .b = 128 };
    }

    /// inits the struct with a peach colour
    pub fn peach() Self {
        return Self{ .r = 255, .g = 158, .b = 158 };
    }

    /// inits the struct with a black colour
    pub fn black() Self {
        return Self{ .r = 0, .g = 0, .b = 0 };
    }

    /// inits the struct with a white colour
    pub fn white() Self {
        return Self{ .r = 255, .g = 255, .b = 255 };
    }

    /// inits the struct with a grey colour
    pub fn grey() Self {
        return Self{ .r = 128, .g = 128, .b = 128 };
    }

    /// inits the struct with a greyScale colour
    pub fn greyScale(scale: u8) Self {
        // 255 max
        return Self{ .r = scale, .g = scale, .b = scale };
    }

    pub fn norm(self: Self) vec.Vec3 {
        return vec.init3(
            @as(f32, @floatFromInt(self.r)) / 255.0,
            @as(f32, @floatFromInt(self.g)) / 255.0,
            @as(f32, @floatFromInt(self.b)) / 255.0,
        );
    }

    /// this will return a set colour based on the usize number
    /// how ever at at point it will start to be random
    pub fn usizeToColour(number: usize) Self {
        return switch (number) {
            0 => red(),
            1 => orange(),
            2 => yellow(),
            3 => gold(),
            4 => lightGreen(),
            5 => green(),
            6 => cyan(),
            7 => turquoise(),
            8 => lightBlue(),
            9 => blue(),
            10 => darkPurple(),
            11 => purple(),
            12 => lightPurple(),
            13 => magenta(),
            14 => pink(),
            15 => peach(),
            else => random(), // just make a random colour
        };
    }

    pub fn random() Self {
        const static = struct {
            var prng = std.rand.DefaultPrng.init(69420);
        };
        const rand = static.prng.random();
        return custom(
            rand.int(u8),
            rand.int(u8),
            rand.int(u8),
        );
    }
};
