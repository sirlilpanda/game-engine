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
    // makes no differnce if these are comptime or not, might blaot the bin tho
    const scope_string = String.initWfg(Colour.pink(), @tagName(scope));

    const prefix_string = switch (level) {
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

    // Print the message to stderr, silently ignoring any errors
    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print("[{}][{}]" ++ format ++ "\n", .{prefix_string} ++ .{scope_string} ++ args) catch return;
    // nosuspend stderr.print(prefix ++ scope_prefix ++ format ++ "\n", args) catch return;
}
