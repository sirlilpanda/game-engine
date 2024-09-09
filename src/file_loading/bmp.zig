const std = @import("std");

pub const Header = packed struct {
    // should just be BM
    signature: u16 = 0x424d, // BM
    /// size in bytes
    file_size: u32,
    /// im going to abuse this
    reserved: u32 = 0,
    data_offset: u32,

    pub fn arrayToHeader(array: [12]u8) Header {
        return Header{
            .signature = std.mem.bytesAsValue(u16, array[0..2]).*,
            .file_size = std.mem.bytesAsValue(u32, array[2..6]).*,
            .data_offset = 54,
        };
    }
};

pub const InfoHeader = packed struct {
    // size of the info header = 40
    size: u32,
    width: i32,
    height: i32,
    /// number of plane? the fucks a plane
    planes: u16,
    /// 1 : The bitmap is monochrome, and the palette contains two entries. Each bit in the bitmap array represents a pixel. If the bit is clear, the pixel is displayed with the color of the first entry in the palette; if the bit is set, the pixel has the color of the second entry in the table.
    /// 4 : The bitmap has a maximum of 16 colors, and the palette contains up to 16 entries. Each pixel in the bitmap is represented by a 4-bit index into the palette. For example, if the first byte in the bitmap is 1Fh, the byte represents two pixels. The first pixel contains the color in the second palette entry, and the second pixel contains the color in the sixteenth palette entry.
    /// 8 : The bitmap has a maximum of 256 colors, and the palette contains up to 256 entries. In this case, each byte in the array represents a single pixel.
    /// 16 : The bitmap has a maximum of 2^16 colors. If the Compression field of the bitmap file is set to BI_RGB, the Palette field does not contain any entries. Each word in the bitmap array represents a single pixel. The relative intensities of red, green, and blue are represented with 5 bits for each color component. The value for blue is in the least significant 5 bits, followed by 5 bits each for green and red, respectively. The most significant bit is not used.
    /// If the Compression field of the bitmap file is set to BI_BITFIELDS, the Palette field contains three 4 byte color masks that specify the red, green, and blue components, respectively, of each pixel.  Each 2 bytes in the bitmap array represents a single pixel.
    /// 24 :  	The bitmap has a maximum of 2^24 colors, and the Palette field does not contain any entries. Each 3-byte triplet in the bitmap array represents the relative intensities of blue, green, and red, respectively, for a pixel.
    /// everthing will be expanded to 24
    bits_per_pixel: u16,
    /// Type of Compression
    /// 0 = BI_RGB   no compression
    /// 1 = BI_RLE8 8bit RLE encoding
    /// 2 = BI_RLE4 4bit RLE encoding
    compression: u32,
    /// (compressed) Size of Image
    /// It is valid to set this =0 if Compression = 0
    image_size: u32,
    x_pixels_per_meter: i32,
    y_pixels_per_meter: i32,

    /// Number of actually used colors. For a 8-bit / pixel bitmap this will be 100h or 256.
    colours_used: u32,

    ///Number of important colors
    ///0 = all
    important_colors: u32,

    pub fn arrayToInfoheader(array: [42]u8) InfoHeader {
        return InfoHeader{
            .size = std.mem.bytesAsValue(u32, array[2..6]).*,
            .width = std.mem.bytesAsValue(i32, array[6..10]).*,
            .height = std.mem.bytesAsValue(i32, array[10..14]).*,
            .planes = std.mem.bytesAsValue(u16, array[14..16]).*,
            .bits_per_pixel = std.mem.bytesAsValue(u16, array[16..18]).*,
            .compression = std.mem.bytesAsValue(u32, array[18..22]).*,
            .image_size = std.mem.bytesAsValue(u32, array[22..26]).*,
            .x_pixels_per_meter = std.mem.bytesAsValue(i32, array[26..30]).*,
            .y_pixels_per_meter = std.mem.bytesAsValue(i32, array[30..34]).*,
            .colours_used = std.mem.bytesAsValue(u32, array[34..38]).*,
            .important_colors = std.mem.bytesAsValue(u32, array[38..]).*,
        };
    }
};

/// present only if Info.BitsPerPixel less than 8
/// colors should be ordered by importance
/// repeated NumColors times
pub const ColourTable = struct {
    red: u8,
    green: u8,
    blue: u8,
    reserved: u8,
};

pub const Bmp = struct {
    const Self = @This();
    header: Header,
    infoheader: InfoHeader,
    data: []u8,

    pub fn init(width: i32, height: i32) Self {
        return Self{
            .header = Header{
                .file_size = undefined,
                .data_offset = 54,
            },
            .infoheader = InfoHeader{
                .size = 40,
                .width = width,
                .height = height,
                .bits_per_pixel = 24,
                .compression = 0,
                .image_size = 0,
                .planes = 1,
                .x_pixels_per_meter = 0,
                .y_pixels_per_meter = 0,
                .colours_used = 0,
                .important_colors = 0,
            },
            .data = undefined,
        };
    }

    fn updateHeaders(self: *Self) void {
        self.header.file_size = @as(u32, @intCast(self.data.len)) + self.header.data_offset;
        self.infoheader.image_size = @as(u32, @intCast(self.data.len));
    }

    pub fn updateData(self: *Self, data: []u8) void {
        self.data = data;
        updateHeaders(self);
    }

    pub fn load(alloc: std.mem.Allocator, filename: []const u8) !Self {
        var bmp: Self = Bmp.init(0, 0);

        const current_dir = std.fs.cwd();
        var buffer: [256]u8 = undefined;
        std.debug.print("reserved = {}\n", .{bmp.header.reserved});

        std.debug.print("std.fs.cwd : {s}\n", .{try current_dir.realpath(filename, &buffer)});
        const raw_bmp_file: std.fs.File = try current_dir.openFile(filename, .{});
        defer raw_bmp_file.close();
        const rbf_reader = raw_bmp_file.reader();

        const header = try rbf_reader.readBytesNoEof(12);

        // std.debug.print("pos {any} : byte {X}\n", .{ rbf_reader.context.getPos(), try rbf_reader.readByte() });
        const info_header = try rbf_reader.readBytesNoEof(42);

        bmp.header = Header.arrayToHeader(header);
        std.debug.print("header = {any}\n", .{bmp.header});

        bmp.infoheader = InfoHeader.arrayToInfoheader(info_header);
        std.debug.print("infoheader = {any}\n", .{bmp.infoheader});

        const size: usize =
            @as(usize, @intCast(bmp.infoheader.width)) *
            @as(usize, @intCast(bmp.infoheader.height)) *
            @as(usize, bmp.infoheader.bits_per_pixel / 8);

        std.debug.print("width : {}\n", .{@as(usize, @intCast(bmp.infoheader.width))});
        std.debug.print("height : {}\n", .{@as(usize, @intCast(bmp.infoheader.height))});

        const data = try alloc.alloc(u8, size);
        if (bmp.infoheader.bits_per_pixel < 8) {
            std.debug.print("i cant be fucked supporting bits per pixel less than 8\n", .{});
            std.process.exit(2);
        }
        const data_read = try raw_bmp_file.readAll(data);
        if (@as(usize, bmp.infoheader.bits_per_pixel / 8) == 3) {
            var idex: usize = 0;
            while (idex < data.len - 3) : (idex += 3) {
                std.mem.swap(u8, &data[idex], &data[idex + 2]);
            }
        }

        std.debug.print("amount read : {}\n", .{data_read});
        std.debug.print("amount size : {}\n", .{size});
        bmp.data = data;

        return bmp;
    }

    pub fn save(self: Self, filename: []const u8) !void {
        const outfile = try std.fs.cwd().createFile(filename, .{ .truncate = true });
        std.debug.print("len : {}\n", .{std.mem.toBytes(self.header).len});
        const outfile_writer = outfile.writer();

        _ = try outfile_writer.writeInt(@TypeOf(self.header.signature), self.header.signature, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.header.file_size), self.header.file_size, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.header.reserved), self.header.reserved, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.header.data_offset), self.header.data_offset, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.size), self.infoheader.size, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.width), self.infoheader.width, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.height), self.infoheader.height, std.builtin.Endian.little);

        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.planes), self.infoheader.planes, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.bits_per_pixel), self.infoheader.bits_per_pixel, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.compression), self.infoheader.compression, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.image_size), self.infoheader.image_size, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.x_pixels_per_meter), self.infoheader.x_pixels_per_meter, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.y_pixels_per_meter), self.infoheader.y_pixels_per_meter, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.colours_used), self.infoheader.colours_used, std.builtin.Endian.little);
        _ = try outfile_writer.writeInt(@TypeOf(self.infoheader.important_colors), self.infoheader.important_colors, std.builtin.Endian.little);

        if (@as(usize, self.infoheader.bits_per_pixel / 8) == 3) {
            var idex: usize = 0;
            while (idex < self.data.len - 3) : (idex += 3) {
                std.mem.swap(u8, &self.data[idex], &self.data[idex + 1]);
            }
        }

        _ = try outfile.write(self.data);
    }
};

test "load file bmp" {
    std.debug.print("header size : {}\n", .{@sizeOf(Header)});
    std.debug.print("InfoHeader size : {}\n", .{@sizeOf(InfoHeader)});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const bmp = try Bmp.load(allocator, "textures/Earth.bmp");
    std.debug.print("{any}\n", .{bmp.header});
    std.debug.print("{any}\n", .{bmp.infoheader});
    std.debug.print("changed\n", .{});

    try bmp.save("textures/earth_2.bmp");
    const bmp2 = try Bmp.load(allocator, "textures/earth_2.bmp");

    // try std.testing.expect(std.mem.eql(u8, &std.mem.toBytes(bmp), &std.mem.toBytes(bmp2)));

    allocator.free(bmp2.data);
    allocator.free(bmp.data);
}

// i have no idea why this shit dont work
// // bmp.header = try rbf_reader.readStruct(Header);
// bmp.header.signature = try rbf_reader.readInt(@TypeOf(bmp.header.signature), std.builtin.Endian.little);
// bmp.header.file_size = try rbf_reader.readInt(@TypeOf(bmp.header.file_size), std.builtin.Endian.little);
// try rbf_reader.skipBytes(4, .{ .buf_size = 4 });
// // try rbf_reader.context.seekBy(4);
// bmp.header.data_offset = try rbf_reader.readInt(@TypeOf(bmp.header.data_offset), std.builtin.Endian.little);
// std.debug.print("offset {any} \n", .{rbf_reader.context.getPos()});
// // these work
// bmp.infoheader.size = try rbf_reader.readInt(@TypeOf(bmp.infoheader.size), std.builtin.Endian.little);
// bmp.infoheader.width = try rbf_reader.readInt(@TypeOf(bmp.infoheader.width), std.builtin.Endian.little);
// bmp.infoheader.height = try rbf_reader.readInt(@TypeOf(bmp.infoheader.height), std.builtin.Endian.little);
// _ = try rbf_reader.readByte();

// // bmp.infoheader.planes = try raw_bmp_file.reader().readInt(@TypeOf(bmp.infoheader.planes), std.builtin.Endian.little);
// bmp.infoheader.bits_per_pixel = try rbf_reader.readInt(@TypeOf(bmp.infoheader.bits_per_pixel), std.builtin.Endian.little);
// bmp.infoheader.compression = try rbf_reader.readInt(@TypeOf(bmp.infoheader.compression), std.builtin.Endian.little);
// bmp.infoheader.image_size = try rbf_reader.readInt(@TypeOf(bmp.infoheader.image_size), std.builtin.Endian.little);
// bmp.infoheader.x_pixels_per_meter = try rbf_reader.readInt(@TypeOf(bmp.infoheader.x_pixels_per_meter), std.builtin.Endian.little);
// bmp.infoheader.y_pixels_per_meter = try rbf_reader.readInt(@TypeOf(bmp.infoheader.y_pixels_per_meter), std.builtin.Endian.little);
// bmp.infoheader.colours_used = try rbf_reader.readInt(@TypeOf(bmp.infoheader.colours_used), std.builtin.Endian.little);
// bmp.infoheader.important_colors = try rbf_reader.readInt(@TypeOf(bmp.infoheader.important_colors), std.builtin.Endian.little);
