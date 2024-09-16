const time = @import("std").time;
const std = @import("std");
const String = @import("string.zig").String;
const Colour = @import("colour.zig").Colour;
const builtin = @import("builtin");

pub const TimeStamp = struct {
    const Self = @This();

    millisec: u64,
    sec: u64,
    min: u64,
    hour: u64,
    day: u64,
    month: u64,
    year: u64,

    /// gets the current time
    pub fn current() Self {
        const current_time: u64 = @abs(time.timestamp());
        return fromTime(current_time);
    }

    fn lengthOfMonth(month: u64, year: u64) u64 {
        return switch (month) {
            1 => 2678400,
            3 => 2678400,
            5 => 2678400,
            7 => 2678400,
            8 => 2678400,
            10 => 2678400,
            12 => 2678400,
            4 => 2592000,
            6 => 2592000,
            9 => 2592000,
            11 => 2592000,
            else => blk: {
                if (!isLeapYear(year)) {
                    break :blk 2505600;
                } else {
                    break :blk 2419200;
                }
            },
        };
    }

    fn isLeapYear(year: u64) bool {
        return (year % 100 == 0 and year % 400 == 0) or (year % 100 != 0 and year % 4 == 0);
    }

    fn lengthOfYear(year: u64) u64 {
        if (isLeapYear(year)) {
            return 31622400;
        } else {
            return 31536000;
        }
    }

    /// creates a new time_stamp form a unix epoch time, doesnt support going backwards though
    pub fn fromTime(time_stamp: u64) Self {
        var temp_time_stamp: u64 = time_stamp;
        var year: u64 = 1970;

        while (temp_time_stamp >= lengthOfYear(year)) {
            temp_time_stamp -= lengthOfYear(year);
            year += 1;
        }

        var month: u64 = 1;

        while (temp_time_stamp >= lengthOfMonth(month, year)) {
            temp_time_stamp -= lengthOfMonth(month, year);
            month += 1;
        }

        const day: u64 = temp_time_stamp / 86400 + 1;
        temp_time_stamp %= 86400;

        var hour: u64 = temp_time_stamp / 3600;
        temp_time_stamp %= 3600;
        hour +%= 12;

        const min: u64 = temp_time_stamp / 60;
        temp_time_stamp %= 60;

        const sec: u64 = temp_time_stamp;

        return Self{
            .millisec = 0,
            .sec = sec,
            .min = min,
            .hour = hour,
            .day = day,
            .month = month,
            .year = year,
        };
    }

    pub fn format(self: Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = options;
        if (std.mem.eql(u8, fmt, "name")) {
            try writer.print("{d:.4}-{d:.2}-{d:.2}_{d:.2}-{d:.2}-{d:.2}", .{
                self.day,
                self.month,
                self.year,
                self.hour,
                self.min,
                self.sec,
            });
        } else if (std.mem.eql(u8, fmt, "time")) {
            var colour_printer = String.initNoString();
            colour_printer.setFgColour(Colour.rangeToColour(0, 23, @intCast(self.hour)));

            try writer.print("{start}{d:.2}{end}", .{ colour_printer, self.hour, colour_printer });

            try writer.print(":", .{});

            colour_printer.setFgColour(Colour.rangeToColour(0, 60, @intCast(self.min)));
            try writer.print("{start}{d:.2}{end}", .{ colour_printer, self.min, colour_printer });

            try writer.print(".", .{});

            colour_printer.setFgColour(Colour.rangeToColour(0, 60, @intCast(self.sec)));
            try writer.print("{start}{d:.2}{end}", .{ colour_printer, self.sec, colour_printer });
        } else if (std.mem.eql(u8, fmt, "date")) {
            try writer.print("{d:.4}-{d:.2}-{d:.2}", .{
                self.day,
                self.month,
                self.year,
            });
        } else {
            try writer.print("{d:.4}-{d:.2}-{d:.2}_{d:.2}:{d:.2}:{d:.2}", .{
                self.day,
                self.month,
                self.year,
                self.hour,
                self.min,
                self.sec,
            });
        }
    }
};

test "works" {
    const time_stamp = TimeStamp.current();
    // const time_stamp = TimeStamp.fromTime(0);

    std.debug.print("time : {}\n", .{time_stamp});
}
