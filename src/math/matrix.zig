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
// this was secretly a warm up for the 4x4 matrix
pub const Mat3x3 = struct {
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
        return Self{ .vec = @shuffle(f32, mat.vec, undefined, mask) };
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
pub const Mat4x4 = struct {
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
        return Self{ .vec = @shuffle(f32, mat.vec, undefined, mask) };
    }

    //this shit is magic
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

    pub fn MulVec(mat: Self, vec: vect.Vec4) vect.Vec4 {
        const mask1 = @Vector(16, i32){
            0, 1, 2, 3,
            0, 1, 2, 3,
            0, 1, 2, 3,
            0, 1, 2, 3,
        };

        const mask3 = @Vector(4, i32){ 0, 1, 2, 3 };
        const mask4 = @Vector(4, i32){ 4, 5, 6, 7 };
        const mask5 = @Vector(4, i32){ 8, 9, 10, 11 };
        const mask6 = @Vector(4, i32){ 12, 13, 14, 15 };

        const v1 = @shuffle(f32, vec.vec, undefined, mask1);
        const v2 = v1 * mat.vec;
        const temp1 = @reduce(.Add, @shuffle(f32, v2, undefined, mask3));
        const temp2 = @reduce(.Add, @shuffle(f32, v2, undefined, mask4));
        const temp3 = @reduce(.Add, @shuffle(f32, v2, undefined, mask5));
        const temp4 = @reduce(.Add, @shuffle(f32, v2, undefined, mask6));

        return vect.init4(temp1, temp2, temp3, temp4);
    }

    pub fn lookAt(eye: vect.Vec3, center: vect.Vec3, up: vect.Vec3) Self {
        const f: vect.Vec3 = (vect.Vec3{ .vec = center.vec - eye.vec }).norm();
        const s: vect.Vec3 = vect.cross(f, up).norm();
        const u: vect.Vec3 = vect.cross(s, f).norm();

        // std.debug.print("\nf : {}\n", .{f});
        // std.debug.print("s : {}\n", .{s});
        // std.debug.print("u : {}\n", .{u});

        const v = @Vector(16, f32){
            s.vec[0],    u.vec[0],    -f.vec[0],  0,
            s.vec[1],    u.vec[1],    -f.vec[1],  0,
            s.vec[2],    u.vec[2],    -f.vec[2],  0,
            -s.dot(eye), -u.dot(eye), f.dot(eye), 1.0,
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

    //needs optimised for simd
    pub fn rotate(angle: f32, v: vect.Vec3) Self {
        // https://github.com/g-truc/glm/blob/0.9.5/glm/gtc/matrix_transform.inl#L48
        const c = @cos(angle);
        const s = @sin(angle);
        const axis: @Vector(3, f32) = v.norm().vec;
        const temp: @Vector(3, f32) = vect.Vec3.number(1 - c).vec * axis;
        // std.debug.print("angle : {}\n", .{angle});
        //might be able to simd this
        const rotation_matrix = @Vector(16, f32){
            c + temp[0] * axis[0],               0 + temp[0] * axis[1] + s * axis[2], 0 + temp[0] * axis[2] - s * axis[1], 0,
            0 + temp[1] * axis[0] - s * axis[2], c + temp[1] * axis[1],               0 + temp[1] * axis[2] + s * axis[0], 0,
            0 + temp[2] * axis[0] + s * axis[1], 0 + temp[2] * axis[1] - s * axis[0], c + temp[2] * axis[2],               0,
            0,                                   0,                                   0,                                   1,
        };
        //could speed this up but its hard
        return Mat4x4{ .vec = rotation_matrix };
    }

    pub fn rotate_x(angle: f32) Self {
        const c = @cos(angle);
        const s = @sin(angle);
        const rotation_matrix = @Vector(16, f32){
            c, -s, 0, 0,
            s, c,  0, 0,
            0, 0,  1, 0,
            0, 0,  0, 1,
        };
        return Mat4x4{ .vec = rotation_matrix };
    }

    pub fn rotate_y(angle: f32) Self {
        const c = @cos(angle);
        const s = @sin(angle);
        const rotation_matrix = @Vector(16, f32){
            1, 0, 0,  0,
            0, c, -s, 0,
            0, s, c,  0,
            0, 0, 0,  1,
        };
        return Mat4x4{ .vec = rotation_matrix };
    }

    pub fn rotate_z(angle: f32) Self {
        const c = @cos(angle);
        const s = @sin(angle);
        const rotation_matrix = @Vector(16, f32){
            c,  0, s, 0,
            0,  1, 0, 0,
            -s, 0, c, 0,
            0,  0, 0, 1,
        };
        return Mat4x4{ .vec = rotation_matrix };
    }

    pub fn translate(location: vect.Vec3) Self {
        const translation_matrix = @Vector(16, f32){
            1, 0, 0, location.vec[0],
            0, 1, 0, location.vec[1],
            0, 0, 1, location.vec[2],
            0, 0, 0, 1,
        };
        return Mat4x4{ .vec = translation_matrix };
    }

    pub fn scale(s: vect.Vec3) Self {
        const scale_matrix = @Vector(16, f32){
            s.vec[0], 0,        0,        0,
            0,        s.vec[1], 0,        0,
            0,        0,        s.vec[2], 0,
            0,        0,        0,        1,
        };
        return Mat4x4{ .vec = scale_matrix };
    }

    //god i love simd vectors
    pub fn inverseTranspose(mat: Self) Self {
        //https://github.com/g-truc/glm/blob/586a402397dd35d66d7a079049856d1e2cbab300/glm/gtc/matrix_inverse.inl#L66
        // im scared
        const ones = @Vector(2, f32){ -1, 1 };

        const sub_factor_mul_step_mask1 = @Vector(36, i32){
            10, 9, 9, 8, 8, 8, 6, 5, 5, 4, 4, 4, 6, 5, 5, 4, 4, 4, 14, 13, 13, 12, 12, 12, 14, 13, 13, 12, 12, 12, 10, 9, 9, 8, 8, 8,
        }; // mul mask
        const sub_factor_mul_step_mask2 = @Vector(36, i32){
            15, 15, 14, 15, 14, 13, 15, 15, 14, 15, 14, 13, 11, 11, 10, 11, 10, 9, 11, 11, 10, 11, 10, 9, 7, 7, 6, 7, 6, 5, 7, 7, 6, 7, 6, 5,
        }; // mul mask

        const sub_factor_sub_step_mask1 = @Vector(18, i32){
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
        }; // sub mask
        const sub_factor_sub_step_mask2 = @Vector(18, i32){
            18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35,
        }; // sub mask

        const sub_mul_vec1 = @shuffle(f32, mat.vec, undefined, sub_factor_mul_step_mask1);
        const sub_mul_vec2 = @shuffle(f32, mat.vec, undefined, sub_factor_mul_step_mask2);

        const sub_mul_step = sub_mul_vec1 * sub_mul_vec2;

        const sub_factor_vec1 = @shuffle(f32, sub_mul_step, undefined, sub_factor_sub_step_mask1);
        const sub_factor_vec2 = @shuffle(f32, sub_mul_step, undefined, sub_factor_sub_step_mask2);

        const sub_factor = sub_factor_vec1 - sub_factor_vec2;
        // std.debug.print("\nvec : {}\n", .{sub_factor});

        const inverse_mul_mat_mask = @Vector(48, i32){
            5, 4, 4, 4, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 6, 6, 5, 5, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1, 1, 7, 7, 7, 6, 3, 3, 3, 2, 3, 3, 3, 2, 3, 3, 3, 2,
        };
        const inverse_mul_subfactor_mask = @Vector(48, i32){
            0, 0, 1, 2, 0, 0, 1, 2, 6, 6, 7, 8, 12, 12, 13, 14, 1, 3, 3, 4, 1, 3, 3, 4, 7, 9, 9, 10, 13, 15, 15, 16, 2, 4, 5, 5, 2, 4, 5, 5, 8, 10, 11, 11, 14, 16, 17, 17,
        };

        const inverse_mul_mat = @shuffle(f32, mat.vec, undefined, inverse_mul_mat_mask);
        const inverse_mul_subfactor = @shuffle(f32, sub_factor, undefined, inverse_mul_subfactor_mask);

        const inverse_mul_step = inverse_mul_mat * inverse_mul_subfactor;

        const inverse_add_mask1 = @Vector(16, i32){ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
        const inverse_add_mask2 = @Vector(16, i32){ 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31 };
        const inverse_add_mask3 = @Vector(16, i32){ 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47 };

        const inverse_add1 = @shuffle(f32, inverse_mul_step, undefined, inverse_add_mask1);
        const inverse_add2 = @shuffle(f32, inverse_mul_step, undefined, inverse_add_mask2);
        const inverse_add3 = @shuffle(f32, inverse_mul_step, undefined, inverse_add_mask3);

        const sign_change_mask = @Vector(16, i32){
            1, 0, 1, 0,
            0, 1, 0, 1,
            1, 0, 1, 0,
            0, 1, 0, 1,
        };
        const sign_change_mul = @shuffle(f32, ones, undefined, sign_change_mask);

        const inverse_step = (inverse_add1 - inverse_add2 + inverse_add3) * sign_change_mul;

        const det_mat_mask = @Vector(4, i32){ 0, 1, 2, 3 };
        const det_inv_mask = @Vector(4, i32){ 0, 1, 2, 3 };

        const det_mat_vec = @shuffle(f32, mat.vec, undefined, det_mat_mask);
        const det_inv_vec = @shuffle(f32, inverse_step, undefined, det_inv_mask);
        const det: @Vector(16, f32) = @splat(@reduce(.Add, det_mat_vec * det_inv_vec));

        const inverse = inverse_step / det;

        return Self{ .vec = inverse };
    }

    pub fn debug_print_matrix(mat: Self) void {
        var i: usize = 0;
        var j: usize = 0;
        std.debug.print("mat :\n", .{});
        while (j < 4) : (j += 1) {
            std.debug.print("|", .{});
            while (i < 4) : (i += 1) {
                std.debug.print("{d:.6}, ", .{mat.vec[i + j * 4]});
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

    const matGenr: matrix4x4 = matrix4x4.fromArray(test_data);
    const matOpti: Mat4x4 = Mat4x4.makeFromArray(test_data);

    std.debug.print("\n", .{});

    var timer = try time.Timer.start();
    var i: u32 = 0;
    while (i < 2000) : (i += 1) {
        _ = matOpti.mul(matOpti);
    }
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});
    i = 0;

    _ = timer.lap();
    while (i < 2000) : (i += 1) {
        _ = matGenr.mul(matrix4x4, matGenr);
    }
    std.debug.print("matGenr took {}ns\n", .{timer.lap()});

    const matOptiOut = matOpti.mul(matOpti);
    _ = matOptiOut;
    const matGenrOut = matGenr.mul(matrix4x4, matGenr);
    _ = matGenrOut;

    // matOptiOut.debug_print_matrix();
    // matGenrOut.debug_print_matrix();
}

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

test "mat4x4 vec mul" {
    const time = std.time;

    var timer = try time.Timer.start();
    const test_data: [16]f32 = [16]f32{
        0,  1,  2,  3,
        4,  5,  6,  7,
        8,  9,  10, 11,
        12, 13, 14, 15,
    };

    const vec: vect.Vec4 = vect.init4(0, 1, 2, 3);
    const matOpti: Mat4x4 = Mat4x4.makeFromArray(test_data);
    _ = matOpti.MulVec(vec);
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});

    // std.debug.print("out : {}\n", .{matOpti.MulVec(vec)});
}

test "rotaion mat" {
    const math = @import("std").math;
    const test_data: [16]f32 = [16]f32{
        0,  1,  2,  3,
        4,  5,  6,  7,
        8,  9,  10, 11,
        12, 13, 14, 15,
    };
    const id: Mat4x4 = Mat4x4.idenity();
    _ = id;
    const matOpti: Mat4x4 = Mat4x4.makeFromArray(test_data);
    _ = matOpti.rotate(46.0 * math.pi / 180.0, vect.init3(1, 1, 1));
}

test "inverse" {
    const time = std.time;

    var timer = try time.Timer.start();
    const test_data: [16]f32 = [16]f32{
        0,  1,  2,  3,
        4,  0,  6,  7,
        8,  9,  0,  11,
        12, 13, 14, 0,
    };
    const matOpti: Mat4x4 = Mat4x4.makeFromArray(test_data);

    _ = matOpti.inverseTranspose();
    std.debug.print("matOpti took {}ns\n", .{timer.lap()});
}

test "look at" {
    const viewMatrix: Mat4x4 = Mat4x4.lookAt(
        vect.init3(0, 0, 2),
        vect.init3(0, 0, 0),
        vect.init3(0, 1, 0),
    );

    viewMatrix.debug_print_matrix();
}
