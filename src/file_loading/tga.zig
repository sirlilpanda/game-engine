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
        const obj_file: std.fs.File = try std.fs.cwd().openFile(filename, .{});
        var head: [@sizeOf(Header)]u8 = undefined;
        if (try obj_file.read(&head) != @sizeOf(Header)) return TgaFileError.incorrect_header_length;
        const header = std.mem.bytesToValue(Header, head[0..]);
        std.debug.print("header : {?}\n", .{header});
        const amount: usize = @as(usize, header.height) * @as(usize, header.wdith) * @as(usize, header.bits_per_pixel / 8);

        const data = try allocator.alloc(u8, amount);
        _ = try obj_file.readAll(data);
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

    const file = try Tga.load(allocator, "screenshot.tga");

    try file.save("test_rebuild.tga");

    allocator.free(file.data);
}
