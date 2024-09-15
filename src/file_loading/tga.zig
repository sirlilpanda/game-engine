//! i implement this as its the simplest data format that exists
//! i believe there are errors in here due to the packet struct
//! i will be fixing this, however i will continue to use
//! bmp file over this
//! https://docs.fileformat.com/image/tga/
const std = @import("std");
const Allocator = std.mem.Allocator;

const tga_logger = std.log.scoped(.Tga_file);

/// header of tga file
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
    /// header
    header: Header,
    /// image data
    data: []u8,

    /// creates a new tga image
    pub fn init(width: u16, height: u16, data: []u8) Self {
        tga_logger.info("creating new tga with {} x {}", .{ width, height });
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

    /// updates the data o fthe tga image
    pub fn updateData(self: Self, data: []u8) void {
        tga_logger.info("updating tga with new data", .{});
        self.data = data;
    }

    /// loads a new tga image
    pub fn load(allocator: Allocator, filename: []const u8) !Self {
        tga_logger.info("loading tga file with name {s}", .{filename});
        const current_dir = std.fs.cwd();

        const obj_file: std.fs.File = current_dir.openFile(filename, .{}) catch |err| {
            var buffer: [256]u8 = undefined;

            tga_logger.err("loading {s} : error {any}", .{ try current_dir.realpath(filename, &buffer), err });
            return err;
        };

        var head: [@sizeOf(Header)]u8 = undefined;
        if (try obj_file.read(&head) != @sizeOf(Header)) return TgaFileError.incorrect_header_length;
        const header = std.mem.bytesToValue(Header, head[0..]);

        const amount: usize = @as(usize, header.height) * @as(usize, header.wdith) * @as(usize, header.bits_per_pixel / 8);

        const data = try allocator.alloc(u8, amount);
        const amount_read = try obj_file.readAll(data);
        tga_logger.debug("read {} bytes", .{amount_read});
        // std.debug.print("amount : {}", .{amount});
        // i believe the packet struct size is wrong at it over writes some image data
        std.mem.reverse(u8, data);
        // std.debug.print("reversed", .{});

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

    /// save the given tga file to the with the name
    pub fn save(self: Self, name: []const u8) !void {
        const outfile = std.fs.cwd().createFile(name, .{ .truncate = true }) catch |err| {
            tga_logger.err("attempting to create file {s} got error {any}", .{ name, err });
            return err;
        };
        _ = try outfile.write(&std.mem.toBytes(self.header));
        _ = try outfile.write(self.data);
        _ = try outfile.write(&[2]u8{ 0, 0 });
        _ = try outfile.write("TRUEVISION-XFILE.");
        _ = try outfile.write(&[1]u8{0});
        tga_logger.info("saved tga file with name {}", .{name});
    }
};

test "load_file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const filename = "screenshot.tga";
    std.debug.print("filename : {s}", .{filename});
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
