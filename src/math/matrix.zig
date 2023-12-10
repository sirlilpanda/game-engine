// https://stackoverflow.com/questions/21830340/understanding-glmlookat
//
//   0 1 2 3 .. n
// 0 a b c d
// 1 e f g h
// 2 i j k l
// 3 m n o p
// :
// m
//

const vect = @import("vec.zig");
const std = @import("std");

// this is more optimised but dosent work with the slower more general purpose matrix
const Mat3x3 = struct {
    const Self = @This();
    vec: @Vector(9, f32),

    pub fn init() Self {
        return Self{ .vec = @splat(0) };
    }

    pub fn idenity() Self {
        var temp = init();
        temp.vec[0] = 1;
        temp.vec[4] = 1;
        temp.vec[8] = 1;
        return temp;
    }

    pub fn makeFromArray(arr: [9]f32) Self {
        return Self{ .vec = arr };
    }

    pub fn t(mat: Self) Self {
        const mask = @Vector(9, i32){ 0, 3, 6, 1, 4, 7, 2, 5, 8 };
        return @shuffle(f32, mat.vec, undefined, mask);
    }

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
        const v3 = v1 * v2;
        const temp1 = @shuffle(f32, v3, undefined, mask3);
        const temp2 = @shuffle(f32, v3, undefined, mask4);
        const temp3 = @shuffle(f32, v3, undefined, mask5);
        return Self{ .vec = temp1 + temp2 + temp3 };
    }

    pub fn debug_print_matrix(mat: Self) void {
        var i: usize = 0;
        var j: usize = 0;
        std.debug.print("mat :\n", .{});
        while (j < 3) : (j += 1) {
            std.debug.print("|", .{});
            while (i < 3) : (i += 1) {
                std.debug.print("{}, ", .{mat.vec[i + j * 3]});
            }
            std.debug.print("|\n", .{});
            i = 0;
        }
    }
};

// this is more optimised but dosent work with the slower more general purpose matrix
const Mat4x4 = struct {
    const Self = @This();
    vec: @Vector(16, f32),

    pub fn init() Self {
        return Self{ .vec = @splat(0) };
    }

    pub fn idenity() Self {
        var temp = init();
        temp.vec[0] = 1;
        temp.vec[5] = 1;
        temp.vec[10] = 1;
        temp.vec[15] = 1;
        return temp;
    }

    pub fn makeFromArray(arr: [16]f32) Self {
        return Self{ .vec = arr };
    }

    pub fn t(mat: Self) Self {
        const mask = @Vector(16, i32){
            0, 4, 8,  12,
            1, 5, 9,  13,
            2, 6, 10, 14,
            3, 7, 11, 15,
        };
        return @shuffle(f32, mat.vec, undefined, mask);
    }

    pub fn mul(mat: Self, mat2: Self) Self {
        const mask1 = @Vector(64, i32){
            0,  0,  0,  0,
            1,  1,  1,  1,
            2,  2,  2,  2,
            3,  3,  3,  3,
            4,  4,  4,  4,
            5,  5,  5,  5,
            6,  6,  6,  6,
            7,  7,  7,  7,
            8,  8,  8,  8,
            9,  9,  9,  9,
            10, 10, 10, 10,
            11, 11, 11, 11,
            12, 12, 12, 12,
            13, 13, 13, 13,
            14, 14, 14, 14,
            15, 15, 15, 15,
        };
        const mask2 = @Vector(64, i32){
            0,  1,  2,  3,
            4,  5,  6,  7,
            8,  9,  10, 11,
            12, 13, 14, 15,
            0,  1,  2,  3,
            4,  5,  6,  7,
            8,  9,  10, 11,
            12, 13, 14, 15,
            0,  1,  2,  3,
            4,  5,  6,  7,
            8,  9,  10, 11,
            12, 13, 14, 15,
            0,  1,  2,  3,
            4,  5,  6,  7,
            8,  9,  10, 11,
            12, 13, 14, 15,
        };
        const v1 = @shuffle(f32, mat.vec, undefined, mask1);
        const v2 = @shuffle(f32, mat2.vec, undefined, mask2);
        const v3 = v1 * v2; // all the dot products multiplaction steps

        const mask3 = @Vector(16, i32){ 0, 1, 2, 3, 16, 17, 18, 19, 32, 33, 34, 35, 48, 49, 50, 51 };
        const mask4 = @Vector(16, i32){ 4, 5, 6, 7, 20, 21, 22, 23, 36, 37, 38, 39, 52, 53, 54, 55 };
        const mask5 = @Vector(16, i32){ 8, 9, 10, 11, 24, 25, 26, 27, 40, 41, 42, 43, 56, 57, 58, 59 };
        const mask6 = @Vector(16, i32){ 12, 13, 14, 15, 28, 29, 30, 31, 44, 45, 46, 47, 60, 61, 62, 63 };
        const temp1 = @shuffle(f32, v3, undefined, mask3);
        const temp2 = @shuffle(f32, v3, undefined, mask4);
        const temp3 = @shuffle(f32, v3, undefined, mask5);
        const temp4 = @shuffle(f32, v3, undefined, mask6);

        return Self{ .vec = temp1 + temp2 + temp3 + temp4 };
    }

    pub fn lookAt(eye: vect.Vec3, center: vect.Vec3, up: vect.Vec3) Self {
        const z: vect.Vec3 = (vect.Vec3{
            .vec = eye.vec - center.vec,
        }).norm();
        const x: vect.Vec3 = vect.cross(up, z).norm();
        const y: vect.Vec3 = vect.cross(z, x).norm();
        const v = @Vector(16, f32){
            x.x, x.y, x.z, -x.dot(eye),
            y.x, y.y, y.z, -y.dot(eye),
            z.x, z.y, z.z, -z.dot(eye),
            0,   0,   0,   1.0,
        };
        return Mat4x4{ .vec = v };
    }

    pub fn perspective(fovy: f32, aspect: f32, zNear: f32, zFar: f32) Self {
        //https://www.youtube.com/watch?v=U0_ONQQ5ZNM&t=177s
        //https://github.com/g-truc/glm/blob/0.9.5/glm/gtc/matrix_transform.inl#L208
        const half_tan_fovy = @tan(fovy / 2);
        const v = @Vector(16, f32){
            1 / (aspect * half_tan_fovy), 0,                 0,                                0,
            0,                            1 / half_tan_fovy, 0,                                0,
            0,                            0,                 -(zFar + zNear) / (zFar - zNear), -(2 * zFar * zNear) / (zFar - zNear),
            0,                            0,                 1,                                0,
        };
        return Mat4x4{ .vec = v };
    }

    pub fn debug_print_matrix(mat: Self) void {
        var i: usize = 0;
        var j: usize = 0;
        std.debug.print("mat :\n", .{});
        while (j < 4) : (j += 1) {
            std.debug.print("|", .{});
            while (i < 4) : (i += 1) {
                std.debug.print("{}, ", .{mat.vec[i + j * 4]});
            }
            std.debug.print("|\n", .{});
            i = 0;
        }
    }
};

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

        pub fn debug_print_matrix(mat: Self) void {
            var i: usize = 0;
            var j: usize = 0;
            std.debug.print("mat :\n", .{});
            while (j < m) : (j += 1) {
                std.debug.print("|", .{});
                while (i < n) : (i += 1) {
                    std.debug.print("{}, ", .{mat.vec[i + j * n]});
                }
                std.debug.print("|\n", .{});
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
                    // temp.vec[i + j * n] = mat.vec[i + j * n];
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
    const mat2: matrix3x3 = matrix3x3.idenity();

    mat.debug_print_matrix();
    mat.t().debug_print_matrix();
    mat.mul(matrix3x3, mat2).debug_print_matrix();
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
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});

    _ = timer.lap();
    const matGenrOut = matGenr.mul(matrix3x3, matGenr);
    std.debug.print("matGenr took {}ns\n", .{timer.lap()});

    matOptiOut.debug_print_matrix();
    matGenrOut.debug_print_matrix();
}

test "mat4x4 mul" {
    const time = std.time;

    var timer = try time.Timer.start();

    const matrix4x4 = Matrix(4, 4);

    const test_data: [16]f32 = [16]f32{
        0,  1,  2,  3,
        4,  5,  6,  7,
        8,  9,  10, 11,
        12, 13, 14, 15,
    };

    const matGenr: matrix4x4 = matrix4x4.fromArray(test_data);
    const matOpti: Mat4x4 = Mat4x4.makeFromArray(test_data);

    std.debug.print("\n", .{});

    _ = timer.lap();
    const matOptiOut = matOpti.mul(matOpti);
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});

    _ = timer.lap();
    const matGenrOut = matGenr.mul(matrix4x4, matGenr);
    std.debug.print("matGenr took {}ns\n", .{timer.lap()});

    matOptiOut.debug_print_matrix();
    matGenrOut.debug_print_matrix();
}
