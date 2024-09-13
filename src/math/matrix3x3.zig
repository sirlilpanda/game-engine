//! optimised 3x3 matrix using SIMD instructions
//! however this dont work with the more generic matrixes
const vect = @import("vec.zig");
const std = @import("std");
const ColourPrinter = @import("../console_logger/coloured_text.zig").ColourPrinter;
const Colour = @import("../utils/colour.zig").Colour;

pub const Mat3x3 = struct {
    const Self = @This();
    /// the data
    vec: @Vector(9, f32),

    /// inits a new matrix filled with zeros
    pub fn init() Self {
        return Self{ .vec = @splat(0) };
    }

    /// create a new idenity matrix
    pub fn idenity() Self {
        var temp = init();
        temp.vec[0] = 1;
        temp.vec[4] = 1;
        temp.vec[8] = 1;
        return temp;
    }

    /// creates an matrix form an array
    pub fn makeFromArray(arr: [9]f32) Self {
        return Self{ .vec = arr };
    }

    /// transpose of the given matrix
    pub fn t(mat: Self) Self {
        const mask = @Vector(9, i32){ 0, 3, 6, 1, 4, 7, 2, 5, 8 };
        return Self{ .vec = @shuffle(f32, mat.vec, undefined, mask) };
    }

    /// multiplies 2 3x3 matrixes together
    pub fn mul(mat: Self, mat2: Self) Self {
        const mask1 = @Vector(27, i32){
            0, 0, 0,
            1, 1, 1,
            2, 2, 2,
            3, 3, 3,
            4, 4, 4,
            5, 5, 5,
            6, 6, 6,
            7, 7, 7,
            8, 8, 8,
        };
        const mask2 = @Vector(27, i32){
            0, 1, 2,
            3, 4, 5,
            6, 7, 8,
            0, 1, 2,
            3, 4, 5,
            6, 7, 8,
            0, 1, 2,
            3, 4, 5,
            6, 7, 8,
        };
        const mask3 = @Vector(9, i32){ 0, 1, 2, 9, 10, 11, 18, 19, 20 };
        const mask4 = @Vector(9, i32){ 3, 4, 5, 12, 13, 14, 21, 22, 23 };
        const mask5 = @Vector(9, i32){ 6, 7, 8, 15, 16, 17, 24, 25, 26 };
        const v1 = @shuffle(f32, mat.vec, undefined, mask1);
        const v2 = @shuffle(f32, mat2.vec, undefined, mask2);
        const v3 = v1 * v2; // all the dot product muls step
        const temp1 = @shuffle(f32, v3, undefined, mask3);
        const temp2 = @shuffle(f32, v3, undefined, mask4);
        const temp3 = @shuffle(f32, v3, undefined, mask5);
        return Self{ .vec = temp1 + temp2 + temp3 };
    }

    /// multiplies the matrix with the given vector
    pub fn MulVec(mat: Self, vec: vect.Vec3) vect.Vec3 {
        const mask1 = @Vector(9, i32){
            0, 1, 2,
            0, 1, 2,
            0, 1, 2,
        };

        const mask3 = @Vector(3, i32){ 0, 1, 2 };
        const mask4 = @Vector(3, i32){ 3, 4, 5 };
        const mask5 = @Vector(3, i32){ 6, 7, 8 };

        const v1 = @shuffle(f32, vec.vec, undefined, mask1);
        const v2 = v1 * mat.vec;
        const temp1 = @reduce(.Add, @shuffle(f32, v2, undefined, mask3));
        const temp2 = @reduce(.Add, @shuffle(f32, v2, undefined, mask4));
        const temp3 = @reduce(.Add, @shuffle(f32, v2, undefined, mask5));

        return vect.init3(temp1, temp2, temp3);
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        var i: usize = 0;
        var j: usize = 0;
        var colour_text = ColourPrinter.init();
        try writer.print("mat :\n", .{});
        while (j < 3) : (j += 1) {
            try writer.print("|", .{});
            while (i < 3) : (i += 1) {
                colour_text.setFgColour(Colour.usizeToColour(i + j * 3));
                try writer.print("{start}{d:.6}{end}, ", .{ colour_text, self.vec[i + j * 3], colour_text });
            }
            try writer.print("|\n", .{});
            i = 0;
        }
    }
};

test "mat3x3 vec mul" {
    const time = std.time;

    var timer = try time.Timer.start();
    const test_data: [9]f32 = [9]f32{
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
    };

    const vec: vect.Vec3 = vect.init3(0, 1, 2);
    const matOpti: Mat3x3 = Mat3x3.makeFromArray(test_data);
    _ = timer.lap();
    _ = matOpti.MulVec(vec);
    // std.debug.print("out : {}\n", .{matOpti.MulVec(vec)});
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});
}
