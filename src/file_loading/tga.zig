//! i implement this as its the simplest data format that exists
//! i believe there are errors in here due to the packet struct
//! i will be fixing this, however i will continue to use
//! bmp file over this
//! https://docs.fileformat.com/image/tga/
const std = @import("std");
const Allocator = std.mem.Allocator;

/// header of tga file
const Header = packed struct {
    id_length: u8, //
    colour_map_type: u8, //
    image_type: u8, //
    colour_map_spec: u40, // // //
    x_origin: u16, //
    y_origin: u16, //
    width: u16, //
    height: u16, //
    bits_per_pixel: u8,
    descriptor: u8,

    pub fn arrayToHeader(array: [18]u8) Header {
        return Header{
            .id_length = std.mem.bytesAsValue(u8, array[0..1]).*,
            .colour_map_type = std.mem.bytesAsValue(u8, array[1..2]).*,
            .image_type = std.mem.bytesAsValue(u8, array[2..3]).*,
            .colour_map_spec = std.mem.bytesAsValue(u40, array[3..8]).*,
            .x_origin = std.mem.bytesAsValue(u16, array[8..10]).*,
            .y_origin = std.mem.bytesAsValue(u16, array[10..12]).*,
            .width = std.mem.bytesAsValue(u16, array[12..14]).*,
            .height = std.mem.bytesAsValue(u16, array[14..16]).*,
            .bits_per_pixel = std.mem.bytesAsValue(u8, array[16..17]).*,
            .descriptor = std.mem.bytesAsValue(u8, array[17..18]).*,
        };
    }
};

pub const TgaFileError = error{
    incorrect_header_length,
};

pub const Tga = struct {
    const Self = @This();
    /// header
    header: Header,
    /// image data
    data: []u8,

    /// creates a new tga image
    pub fn init(width: u16, height: u16, data: []u8) Self {
        return Self{
            .header = Header{
                .id_length = 0,
                .colour_map_type = 0,
                .image_type = 2,
                .colour_map_spec = 0,
                .x_origin = 0,
                .y_origin = 0,
                .width = width,
                .height = height,
                .bits_per_pixel = 24,
                .descriptor = 0,
            },
            .data = data,
        };
    }

    /// updates the data o fthe tga image
    pub fn updateData(self: Self, data: []u8) void {
        self.data = data;
    }

    /// loads a new tga image
    pub fn load(allocator: Allocator, filename: []const u8) !Self {
        const current_dir = std.fs.cwd();
        var buffer: [256]u8 = undefined;

        std.debug.print("std.fs.cwd : {s}\n", .{try current_dir.realpath(filename, &buffer)});
        const obj_file: std.fs.File = try current_dir.openFile(filename, .{});

        var head: [18]u8 = undefined;
        if (try obj_file.read(&head) != 18) return TgaFileError.incorrect_header_length;
        const header = Header.arrayToHeader(head);

        const amount: usize = @as(usize, header.height) * @as(usize, header.width) * @as(usize, header.bits_per_pixel / 8);

        const data = try allocator.alloc(u8, amount);
        _ = try obj_file.readAll(data);
        std.debug.print("amount : {}\n", .{amount});

        // still no fucking clue why i have to do this
        if (@as(usize, header.bits_per_pixel / 8) == 3) {
            var idex: usize = 0;
            while (idex < data.len - 3) : (idex += 3) {
                std.mem.swap(u8, &data[idex], &data[idex + 2]);
                std.mem.swap(u8, &data[idex + 1], &data[idex]);
            }
        }

        return Self{
            .header = header,
            .data = data,
        };
    }

    /// save the given tga file to the with the name
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
// rgb(85, 60, 67)
// rgb(67, 60, 85)
// rgb(61, 68, 86)
test "load_file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const filename = "textures/sky_box_.tga";
    std.debug.print("filename : {s}\n", .{filename});
    const file = try Tga.load(allocator, filename);

    try file.save("test_rebuild.tga");

    allocator.free(file.data);
}
