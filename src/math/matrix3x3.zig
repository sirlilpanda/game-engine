//! optimised 3x3 matrix using SIMD instructions
//! however this dont work with the more generic matrixes
const vect = @import("vec.zig");
const std = @import("std");
const ColourPrinter = @import("../utils/string.zig").String;
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

    pub fn eq(self: Self, other: Self) bool {
        return @reduce(.And, self.vec == other.vec);
    }

    pub fn req(self: Self, other: Self, epsilon: f32) bool {
        return @reduce(.And, @abs(self.vec - other.vec) <= vect.Vec(9).number(epsilon).vec);
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        var i: usize = 0;
        var j: usize = 0;
        var colour_text = ColourPrinter.initNoString();
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

const expect = std.testing.expect;

test "init" {
    const temp = Mat3x3.init();
    const v: @Vector(9, f32) = @splat(0);
    try expect(@reduce(.And, temp.vec == v));
}

test "makeFromArray" {
    const temp_dat: [9]f32 = [9]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const temp_matrix: Mat3x3 = Mat3x3.makeFromArray(temp_dat);

    const dat: @Vector(9, f32) = temp_dat;

    try expect(@reduce(.And, temp_matrix.vec == dat));
}

test "idenity" {
    const ident = Mat3x3.idenity();

    const real_dat: [9]f32 = [9]f32{ 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0 };
    const real_matrix: Mat3x3 = Mat3x3.makeFromArray(real_dat);

    try expect(@reduce(.And, ident.vec == real_matrix.vec));
}

test "t" {
    const test_dat: [9]f32 = [9]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const test_matrix: Mat3x3 = Mat3x3.makeFromArray(test_dat);

    const test_transpose_dat: [9]f32 = [9]f32{ 1, 4, 7, 2, 5, 8, 3, 6, 9 };
    const test_transpose_matrix: Mat3x3 = Mat3x3.makeFromArray(test_transpose_dat);

    const tposed = test_matrix.t();

    try expect(@reduce(.And, tposed.vec == test_transpose_matrix.vec));
}

test "mul" {
    const one_dat: [9]f32 = [9]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const one_matrix: Mat3x3 = Mat3x3.makeFromArray(one_dat);

    const two_dat: [9]f32 = [9]f32{ 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    const two_matrix: Mat3x3 = Mat3x3.makeFromArray(two_dat);

    const out_dat: [9]f32 = [9]f32{ 30, 24, 18, 84, 69, 54, 138, 114, 90 };
    const out_matrix: Mat3x3 = Mat3x3.makeFromArray(out_dat);

    const mul = one_matrix.mul(two_matrix);

    try expect(@reduce(.And, out_matrix.vec == mul.vec));
}

test "MulVec" {
    const one_dat: [9]f32 = [9]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    const one_matrix: Mat3x3 = Mat3x3.makeFromArray(one_dat);

    const vec: vect.Vec3 = vect.init3(1, 2, 3);
    const res: vect.Vec3 = vect.init3(14, 32, 50);

    const vec_out = one_matrix.MulVec(vec);

    try expect(@reduce(.And, vec_out.vec == res.vec));
}
