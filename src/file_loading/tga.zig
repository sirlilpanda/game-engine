const std = @import("std");
const Allocator = std.mem.Allocator;

const Header = packed struct {
    id_length: u8, //
    colour_map_type: u8, //
    image_type: u8, //
    colour_map_spec: u40, // // //
    x_origin: u16, //
    y_origin: u16, //
    wdith: u16, //
    height: u16, //
    bits_per_pixel: u8,
    descriptor: u8,
};

pub const TgaFileError = error{
    incorrect_header_length,
};

pub const Tga = struct {
    const Self = @This();
    header: Header,
    data: []u8,

    pub fn init(width: u16, height: u16, data: []u8) Self {
        return Self{
            .header = Header{
                .id_length = 0,
                .colour_map_type = 0,
                .image_type = 2,
                .colour_map_spec = 0,
                .x_origin = 0,
                .y_origin = 0,
                .wdith = width,
                .height = height,
                .bits_per_pixel = 24,
                .descriptor = 0,
            },
            .data = data,
        };
    }

    pub fn updateData(self: Self, data: []u8) void {
        self.data = data;
    }

    pub fn load(allocator: Allocator, filename: []const u8) !Self {
        const current_dir = std.fs.cwd();
        var buffer: [256]u8 = undefined;

        std.debug.print("std.fs.cwd : {s}\n", .{try current_dir.realpath(filename, &buffer)});
        const obj_file: std.fs.File = try current_dir.openFile(filename, .{});

        var head: [@sizeOf(Header)]u8 = undefined;
        if (try obj_file.read(&head) != @sizeOf(Header)) return TgaFileError.incorrect_header_length;
        const header = std.mem.bytesToValue(Header, head[0..]);

        const amount: usize = @as(usize, header.height) * @as(usize, header.wdith) * @as(usize, header.bits_per_pixel / 8);

        const data = try allocator.alloc(u8, amount);
        _ = try obj_file.readAll(data);
        std.debug.print("amount : {}\n", .{amount});
        // honestly i have no clue why i have to do this
        std.mem.reverse(u8, data);
        std.debug.print("reversed\n", .{});

        var row: usize = 0;
        while (row < header.height) : (row += 1) {
            std.mem.reverse(u8, data[(row * header.wdith * @as(usize, header.bits_per_pixel / 8)) .. (row * header.wdith + header.wdith) * @as(usize, header.bits_per_pixel / 8)]);
        }

        if (@as(usize, header.bits_per_pixel / 8) == 3) {
            var idex: usize = 0;
            while (idex < data.len - 3) : (idex += 3) {
                std.mem.swap(u8, &data[idex + 1], &data[idex + 2]);
            }
        }

        return Self{
            .header = header,
            .data = data,
        };
    }

    pub fn save(self: Self, name: []const u8) !void {
        const outfile = try std.fs.cwd().createFile(name, .{ .truncate = true });
        std.debug.print("len : {}\n", .{std.mem.toBytes(self.header).len});
        _ = try outfile.write(&std.mem.toBytes(self.header));
        _ = try outfile.write(self.data);
        _ = try outfile.write(&[2]u8{ 0, 0 });
        _ = try outfile.write("TRUEVISION-XFILE.");
        _ = try outfile.write(&[1]u8{0});
    }
};

test "load_file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const filename = "screenshot.tga";
    std.debug.print("filename : {s}\n", .{filename});
    const file = try Tga.load(allocator, filename);

    try file.save("test_rebuild.tga");

    allocator.free(file.data);
}

// var i: usize = 0;
// while (i < header.wdith) : (i += 1) {
//     std.mem.swap(
//         u8,
//         &data[top * header.wdith + i],
//         &data[bottom * header.wdith + i],
//     );
// }

// var top: usize = 0;
// var bottom: usize = header.height - 1;

// while (top < header.height / 2) : ({
//     top += 1;
//     bottom -= 1;
// }) {
//     std.mem.swap(
//         []u8,
//         @constCast(&data[top * header.wdith .. top * header.wdith + header.wdith]),
//         @constCast(&data[bottom * header.wdith .. bottom * header.wdith + header.wdith]),
//     );
// }
