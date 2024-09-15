const std = @import("std");
const String = @import("string.zig").String;
const str = @import("string.zig");
const Colour = @import("colour.zig").Colour;

pub fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // i will determine the colour of this from the string its self in the future
    const scope_string = comptime String.initWfg(Colour.pink(), @tagName(scope));

    const prefix_string = comptime switch (level) {
        .err => String.initWfg(
            Colour.red(),
            "ERROR",
        ),
        .debug => String.initWfg(
            Colour.lightBlue(),
            "DEBUG",
        ),
        .info => String.initWfg(
            Colour.green(),
            "INFO",
        ),
        .warn => String.initWfg(
            Colour.orange(),
            "WARN",
        ),
    };

    const prefix = "[" ++ std.fmt.comptimePrint(
        str.colour_set_string_fmt ++ "{s}" ++ str.colour_end_string_fmt,
        .{
            prefix_string.colour_fg.r,
            prefix_string.colour_fg.g,
            prefix_string.colour_fg.b,
            prefix_string.colour_bg.r,
            prefix_string.colour_bg.g,
            prefix_string.colour_bg.b,
            prefix_string.string,
        },
    ) ++ "]";

    const scope_prefix = "[" ++ std.fmt.comptimePrint(
        str.colour_set_string_fmt ++ "{s}" ++ str.colour_end_string_fmt,
        .{
            scope_string.colour_fg.r,
            scope_string.colour_fg.g,
            scope_string.colour_fg.b,
            scope_string.colour_bg.r,
            scope_string.colour_bg.g,
            scope_string.colour_bg.b,
            scope_string.string,
        },
    ) ++ "]: ";

    // Print the message to stderr, silently ignoring any errors
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ scope_prefix ++ format ++ "\n", args) catch return;
}
