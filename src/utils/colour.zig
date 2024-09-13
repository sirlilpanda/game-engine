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

    /// inits the struct with a pink colour
    pub fn pink() Self {
        return Self{ .r = 128, .g = 0, .b = 255 };
    }

    /// inits the struct with a magenta colour
    pub fn magenta() Self {
        return Self{ .r = 255, .g = 0, .b = 255 };
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
};
