//! very generic matrix type, if you want a faster matrix please use the
//! Mat4x4, and Mat3x3 for a faster version
//! honestly this whole thing needs a rewrite i will be commenting it after
//   0 0 2 3 .. n
// 0 a b c d
// 1 e f g h
// 2 i j k l
// 3 m n o p
// :
// m
//

const vect = @import("vec.zig");
const std = @import("std");

const ColourPrinter = @import("../console_logger/coloured_text.zig").ColourPrinter;
const Colour = @import("../utils/colour.zig").Colour;

pub const Mat4x4 = @import("matrix4x4.zig").Mat4x4;
pub const Mat3x3 = @import("matrix3x3.zig").Mat3x3;

// slow and just to get my bearing but might be useful for something
pub fn Matrix(comptime hight: comptime_int, comptime length: comptime_int) type {
    return struct {
        const Self = @This();
        const m = hight;
        const n = length;
        vec: @Vector(m * n, f32),

        pub fn fill(num: f32) Self {
            return Self{ .vec = @splat(num) };
        }

        pub fn init() Self {
            return Self{ .vec = @splat(0) };
        }

        pub fn from_vec(v: @Vector(m * n, f32)) Self {
            return Self{ .vec = v };
        }

        pub fn fromArray(arr: [m * n]f32) Self {
            return Self{ .vec = arr };
        }

        pub fn idenity() Self {
            var temp = init();
            var i: usize = 0;
            while (i < n) : (i += 1) {
                temp.vec[i * (n + 1)] = 1;
            }
            return temp;
        }

        pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = options;
            var i: usize = 0;
            var j: usize = 0;
            var colour_text = ColourPrinter.init();
            try writer.print("mat :\n", .{});
            while (j < m) : (j += 1) {
                colour_text.setFgColour(Colour.usizeToColour(i + j * n));
                try writer.print("|", .{});
                while (i < n) : (i += 1) {
                    try writer.print("{start}{}{end}, ", .{ colour_text, self.vec[i + j * n], colour_text });
                }
                try writer.print("|\n", .{});
                i = 0;
            }
        }

        pub fn t(mat: Self) Matrix(n, m) {
            var temp: Matrix(n, m) = Matrix(n, m).init();
            var i: usize = 0;
            var j: usize = 0;
            while (j < m) : (j += 1) {
                while (i < n) : (i += 1) {
                    temp.vec[i * n + j] = mat.vec[i + j * n];
                }
                i = 0;
            }
            return temp;
        }

        pub fn mul(mat: Self, comptime matType: type, mat2: matType) Matrix(m, matType.n) {
            // comptime if (n != matType.m) unreachable;
            var temp: Matrix(m, matType.n) = Matrix(m, matType.n).init();

            var i: usize = 0;
            var j: usize = 0;
            var k: usize = 0;
            while (j < m) : (j += 1) {
                while (i < n) : (i += 1) {
                    var r: f32 = 0;
                    while (k < n) : (k += 1) { //dot
                        r += mat.vec[i * n + k] * mat2.vec[k * n + j];
                    }
                    k = 0;
                    temp.vec[i * n + j] = r;
                }
                i = 0;
            }
            return temp;
        }
    };
}

test "init" {
    const matrix3x3 = Matrix(4, 3);
    const mat: matrix3x3 = matrix3x3.idenity();
    _ = mat;
    const mat2: matrix3x3 = matrix3x3.idenity();
    _ = mat2;

    // mat.debug_print_matrix();
    // mat.t().debug_print_matrix();/
    // mat.mul(matrix3x3, mat2).debug_print_matrix();
}

test "mat3x3 mul" {
    const time = std.time;

    var timer = try time.Timer.start();

    const matrix3x3 = Matrix(3, 3);

    const test_data: [9]f32 = [9]f32{
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
    };

    const matGenr: matrix3x3 = matrix3x3.fromArray(test_data);
    const matOpti: Mat3x3 = Mat3x3.makeFromArray(test_data);

    std.debug.print("\n", .{});

    _ = timer.lap();
    const matOptiOut = matOpti.mul(matOpti);
    _ = matOptiOut;
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});

    _ = timer.lap();
    const matGenrOut = matGenr.mul(matrix3x3, matGenr);
    _ = matGenrOut;
    std.debug.print("matGenr took {}ns\n", .{timer.lap()});

    // matOptiOut.debug_print_matrix();
    // matGenrOut.debug_print_matrix();
}

test "mat4x4 mul" {
    const time = std.time;

    const matrix4x4 = Matrix(4, 4);

    const test_data: [16]f32 = [16]f32{
        0,  1,  2,  3,
        4,  5,  6,  7,
        8,  9,  10, 11,
        12, 13, 14, 15,
    };

    const test_data2: [16]f32 = [16]f32{
        12, 13, 14, 15,
        8,  9,  10, 11,
        4,  5,  6,  7,
        0,  1,  2,  3,
    };

    const matGenr: matrix4x4 = matrix4x4.fromArray(test_data);
    const matGenr2: matrix4x4 = matrix4x4.fromArray(test_data2);
    const matOpti: Mat4x4 = Mat4x4.makeFromArray(test_data);
    const matOpti2: Mat4x4 = Mat4x4.makeFromArray(test_data2);

    std.debug.print("\n", .{});

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = matOpti.mul(matOpti2);
    }
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});
    i = 0;

    _ = timer.lap();
    while (i < 2000) : (i += 1) {
        _ = matGenr.mul(matrix4x4, matGenr2);
    }
    std.debug.print("matGenr took {}ns\n", .{timer.lap()});

    const matOptiOut = matOpti.mul(matOpti2);
    const matGenrOut = matGenr.mul(matrix4x4, matGenr2);

    matOptiOut.debug_print_matrix();
    matGenrOut.debug_print_matrix();
}
