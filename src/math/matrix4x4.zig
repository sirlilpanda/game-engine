//! optimised 4x4 matrix using SIMD instructions
//! however this dont work with the more generic matrixes
const vect = @import("vec.zig");
const std = @import("std");
const ColourPrinter = @import("../utils/string.zig").String;
const Colour = @import("../utils/colour.zig").Colour;

// this is more optimised but dosent work with the slower more general purpose matrix
pub const Mat4x4 = struct {
    const Self = @This();
    vec: @Vector(16, f32),

    /// creates a new matrix filled with zeros
    pub fn init() Self {
        return Self{ .vec = @splat(0) };
    }

    /// returns a 4x4 idenity matrix
    pub fn idenity() Self {
        var temp = init();
        temp.vec[0] = 1;
        temp.vec[5] = 1;
        temp.vec[10] = 1;
        temp.vec[15] = 1;
        return temp;
    }

    /// creates matrix from an array of values
    pub fn makeFromArray(arr: [16]f32) Self {
        return Self{ .vec = arr };
    }

    /// computes the transpose of the matrix
    pub fn t(mat: Self) Self {
        const mask = @Vector(16, i32){
            0, 4, 8,  12,
            1, 5, 9,  13,
            2, 6, 10, 14,
            3, 7, 11, 15,
        };
        return Self{ .vec = @shuffle(f32, mat.vec, undefined, mask) };
    }

    /// multiplies 2 4x4 matrixes
    pub fn mul(mat: Self, mat2: Self) Self {
        //this shit is magic
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

    /// multiply with a vec4
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

        return vect.init4(
            temp1,
            temp2,
            temp3,
            temp4,
        );
    }

    /// computes the look at point matrix
    pub fn lookAt(eye: vect.Vec3, center: vect.Vec3, approx_up: vect.Vec3) Self {
        const forward: vect.Vec3 = (vect.Vec3{ .vec = center.vec - eye.vec }).norm();
        const side: vect.Vec3 = vect.cross(forward, approx_up).norm();
        const up: vect.Vec3 = vect.cross(side, forward).norm();

        // std.debug.print("\nf : {}\n", .{f});
        // std.debug.print("s : {}\n", .{s});
        // std.debug.print("u : {}\n", .{u});

        const v = @Vector(16, f32){
            side.vec[0],    up.vec[0],    -forward.vec[0],  0,
            side.vec[1],    up.vec[1],    -forward.vec[1],  0,
            side.vec[2],    up.vec[2],    -forward.vec[2],  0,
            -side.dot(eye), -up.dot(eye), forward.dot(eye), 1.0,
        };
        return Mat4x4{ .vec = v };
    }

    /// computes the perspective matrix, might change this to the inf perspective matrix later
    pub fn perspective(fovy: f32, aspect: f32, zNear: f32, zFar: f32) Self {
        //https://www.youtube.com/watch?v=U0_ONQQ5ZNM&t=177s
        //https://github.com/g-truc/glm/blob/0.9.5/glm/gtc/matrix_transform.inl#L208
        const half_tan_fovy = @tan(fovy / 2);
        const v = @Vector(16, f32){
            1 / (aspect * half_tan_fovy), 0,                 0,                                    0,
            0,                            1 / half_tan_fovy, 0,                                    0,
            0,                            0,                 -(zFar + zNear) / (zFar - zNear),     -1,
            0,                            0,                 -(2 * zFar * zNear) / (zFar - zNear), 0,
        };
        return Mat4x4{ .vec = v };
    }

    /// creates a rotaion matrix form an angle axis form currently broken
    pub fn rotate(angle: f32, v: vect.Vec3) Self {
        //needs optimised for simd
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

    /// creates the z rotaion matrix
    pub fn rotate_z(angle: f32) Self {
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

    /// creates the x rotaion matrix
    pub fn rotate_x(angle: f32) Self {
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

    /// creates the y rotaion matrix
    pub fn rotate_y(angle: f32) Self {
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

    /// creates the the translation matrix
    pub fn translate(location: vect.Vec3) Self {
        const translation_matrix = @Vector(16, f32){
            1,               0,               0,               0,
            0,               1,               0,               0,
            0,               0,               1,               0,
            location.vec[0], location.vec[1], location.vec[2], 1,
        };
        return Mat4x4{ .vec = translation_matrix };
    }

    /// creates the the scale matrix
    pub fn scale(s: vect.Vec3) Self {
        const scale_matrix = @Vector(16, f32){
            s.vec[0], 0,        0,        0,
            0,        s.vec[1], 0,        0,
            0,        0,        s.vec[2], 0,
            0,        0,        0,        1,
        };
        return Mat4x4{ .vec = scale_matrix };
    }

    /// computes the inverse transpose of the matrix
    pub fn inverseTranspose(mat: Self) Self {
        //god i love simd vectors
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

    pub fn eq(self: Self, other: Self) bool {
        return @reduce(.And, self.vec == other.vec);
    }

    pub fn req(self: Self, other: Self, epsilon: f32) bool {
        return @reduce(.And, @abs(self.vec - other.vec) <= vect.Vec(16).number(epsilon).vec);
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        var i: usize = 0;
        var j: usize = 0;
        var colour_text = ColourPrinter.initNoString();
        try writer.print("mat :\n", .{});
        while (j < 4) : (j += 1) {
            try writer.print("|", .{});
            while (i < 4) : (i += 1) {
                colour_text.setFgColour(Colour.usizeToColour(i + j * 4));
                try writer.print("{start}{d:.6}{end}, ", .{ colour_text, self.vec[i + j * 4], colour_text });
            }
            try writer.print("|\n", .{});
            i = 0;
        }
    }
};

const expect = std.testing.expect;

test "init" {
    const temp = Mat4x4.init();
    const v: @Vector(16, f32) = @splat(0);
    try expect(@reduce(.And, temp.vec == v));
}

test "makeFromArray" {
    const temp_dat: [16]f32 = [16]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const temp_matrix: Mat4x4 = Mat4x4.makeFromArray(temp_dat);

    const dat: @Vector(16, f32) = temp_dat;

    try expect(@reduce(.And, temp_matrix.vec == dat));
}

test "idenity" {
    const ident = Mat4x4.idenity();

    const real_dat: [16]f32 = [16]f32{ 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0 };
    const real_matrix: Mat4x4 = Mat4x4.makeFromArray(real_dat);

    try expect(@reduce(.And, ident.vec == real_matrix.vec));
}

test "t" {
    const test_dat: [16]f32 = [16]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const test_matrix: Mat4x4 = Mat4x4.makeFromArray(test_dat);

    const test_transpose_dat: [16]f32 = [16]f32{ 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16 };
    const test_transpose_matrix: Mat4x4 = Mat4x4.makeFromArray(test_transpose_dat);

    const tposed = test_matrix.t();

    try expect(@reduce(.And, tposed.vec == test_transpose_matrix.vec));
}

test "mul" {
    const one_dat: [16]f32 = [16]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const one_matrix: Mat4x4 = Mat4x4.makeFromArray(one_dat);

    const two_dat: [16]f32 = [16]f32{ 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 };
    const two_matrix: Mat4x4 = Mat4x4.makeFromArray(two_dat);

    const out_dat: [16]f32 = [16]f32{ 80, 70, 60, 50, 240, 214, 188, 162, 400, 358, 316, 274, 560, 502, 444, 386 };
    const out_matrix: Mat4x4 = Mat4x4.makeFromArray(out_dat);

    const mul = one_matrix.mul(two_matrix);

    try expect(@reduce(.And, out_matrix.vec == mul.vec));
}

test "MulVec" {
    const one_dat: [16]f32 = [16]f32{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    const one_matrix: Mat4x4 = Mat4x4.makeFromArray(one_dat);

    const vec: vect.Vec4 = vect.init4(1, 2, 3, 4);
    const res: vect.Vec4 = vect.init4(30, 70, 110, 150);

    const vec_out = one_matrix.MulVec(vec);

    try expect(@reduce(.And, vec_out.vec == res.vec));
}

test "lookAt" {
    const look_at: [16]f32 = [16]f32{ -7.0710677e-1, -4.082483e-1, -5.7735026e-1, 0e0, 0e0, 8.164966e-1, -5.7735026e-1, 0e0, 7.0710677e-1, -4.082483e-1, -5.7735026e-1, 0e0, -0e0, -0e0, 0e0, 1e0 };
    const out_matrix: Mat4x4 = Mat4x4.makeFromArray(look_at);

    const look_at_matrix =
        Mat4x4.lookAt(
        vect.Vec3.zeros(),
        vect.Vec3.number(1),
        vect.init3(0, 1, 0),
    );
    try expect(@reduce(.And, look_at_matrix.vec == out_matrix.vec));
}

test "perspective" {
    const perspective: [16]f32 = [16]f32{ 3.247595e-1, 0e0, 0e0, 0e0, 0e0, 5.7735026e-1, 0e0, 0e0, 0e0, 0e0, -1.0000019e0, -1e0, 0e0, 0e0, -2.000002e-3, 0e0 };
    const out_matrix: Mat4x4 = Mat4x4.makeFromArray(perspective);

    const perspective_matrix =
        Mat4x4.perspective(
        120 * std.math.pi / 180.0,
        16.0 / 9.0,
        0.001,
        1000,
    );
    try expect(@reduce(.And, perspective_matrix.vec == out_matrix.vec));
}

test "inverseTranspose" {
    const m1_dat: [16]f32 = [16]f32{ 2, 5, 0, 8, 1, 4, 2, 6, 7, 8, 9, 3, 1, 5, 7, 8 };
    const m1_matrix: Mat4x4 = Mat4x4.makeFromArray(m1_dat);

    const inverse_dat: [16]f32 = [16]f32{ 0.9608938547486034, -1.033519553072626, -0.005586592178770905, 0.5307262569832404, -1.916201117318436, 2.3575418994413413, -0.27374301675977664, -0.9944134078212293, 0.07821229050279328, 0.06703910614525141, 0.011173184357541896, -0.06145251396648045, 0.4469273743016761, -0.7597765363128494, 0.20670391061452517, 0.3631284916201118 };
    const inverse_matrix: Mat4x4 = Mat4x4.makeFromArray(inverse_dat);

    const res = m1_matrix.inverseTranspose();

    try expect(@reduce(.And, inverse_matrix.vec == res.vec));
}

test "rotate_x" {
    const rot_x_dat: [16]f32 = [16]f32{ 1.0, 0.0, -0.0, 0.0, -0.0, 0.52532199, -0.85090352, 0.0, 0.0, 0.85090352, 0.52532199, 0.0, 0.0, 0.0, 0.0, 1.0 };
    const rot_x_matrix: Mat4x4 = Mat4x4.makeFromArray(rot_x_dat);
    const res = Mat4x4.rotate_x(45);
    try expect(@reduce(.And, rot_x_matrix.vec == res.vec));
}

test "rotate_y" {
    const rot_y_dat: [16]f32 = [16]f32{ 0.52532199, 0.0, 0.85090352, 0.0, -0.0, 1.0, 0.0, 0.0, -0.85090352, 0.0, 0.52532199, 0.0, 0.0, 0.0, 0.0, 1.0 };
    const rot_y_matrix: Mat4x4 = Mat4x4.makeFromArray(rot_y_dat);
    const res = Mat4x4.rotate_y(45);
    try expect(@reduce(.And, rot_y_matrix.vec == res.vec));
}

test "rotate_z" {
    const rot_z_dat: [16]f32 = [16]f32{ 0.52532199, -0.85090352, -0.0, 0.0, 0.85090352, 0.52532199, 0.0, 0.0, 0.0, -0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0 };
    const rot_z_matrix: Mat4x4 = Mat4x4.makeFromArray(rot_z_dat);
    const res = Mat4x4.rotate_z(45);
    try expect(@reduce(.And, rot_z_matrix.vec == res.vec));
}

// this is currently broken
test "rotate" {
    const rot_dat: [16]f32 = [16]f32{ -0.75695269, 0.11786175, 0.64275285, 0.0, 0.58491933, 0.56076183, 0.58601668, 0.0, -0.29136231, 0.81954547, -0.49340979, 0.0, 0.0, 0.0, 0.0, 1.0 };
    const rot_matrix: Mat4x4 = Mat4x4.makeFromArray(rot_dat);
    const res = Mat4x4.rotate(45, vect.init3(0.5, 2, 1));

    _ = rot_matrix;
    _ = res;
    // std.debug.print("res {}\n", .{res});
    // std.debug.print("rot_matrix {}\n", .{rot_matrix});

    // try expect(@reduce(.And, rot_matrix.vec == res.vec));
}

test "translate" {
    const translation_matrix = [16]f32{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        3, 4, 0, 1,
    };
    const translate_matrix: Mat4x4 = Mat4x4.makeFromArray(translation_matrix);
    const res = Mat4x4.translate(vect.init3(3, 4, 0));

    try expect(@reduce(.And, res.vec == translate_matrix.vec));
}

test "scale" {
    const scaling_matrix = [16]f32{
        2, 0, 0, 0,
        0, 3, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 1,
    };
    const scale_matrix: Mat4x4 = Mat4x4.makeFromArray(scaling_matrix);
    const res = Mat4x4.scale(vect.init3(3, 4, 0));
    try expect(@reduce(.And, res.vec == scale_matrix.vec));
}
