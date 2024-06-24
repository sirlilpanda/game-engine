const glfw = @import("mach-glfw");
const gl = @import("gl");
const std = @import("std");

const program = @import("program.zig");
const file = @import("../file_loading/tga.zig");
/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

pub const Window = struct {
    const Self = @This();

    window: glfw.Window,

    pub fn init(width: u32, height: u32) !Self {
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }
        // Create our window
        const window = glfw.Window.create(width, height, "game-shit-dwag", null, null, .{
            .opengl_profile = .opengl_core_profile,
            .context_version_major = 4,
            .context_version_minor = 5,
        }) orelse {
            std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        };
        glfw.makeContextCurrent(window);

        const proc: glfw.GLProc = undefined;
        try gl.load(proc, glGetProcAddress);

        return Self{
            .window = window,
        };
    }

    pub fn getAspectRatio(self: Self) f32 {
        const size = self.window.getSize();
        return @as(f32, @floatFromInt(size.width)) / @as(f32, @floatFromInt(size.height));
    }

    pub fn runRoutine(self: Self) !void {
        _ = self;
    }

    pub fn hideCursor(self: Self) void {
        self.window.setInputModeCursor(.disabled);
    }

    pub fn showCursor(self: Self) void {
        self.window.setInputModeCursor(.normal);
    }

    pub inline fn swapBuffer(self: Self) void {
        self.window.swapBuffers();
    }

    pub inline fn shouldClose(self: Self) bool {
        return self.window.shouldClose();
    }

    pub fn saveImg(self: Self, name: []const u8) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        const size = self.window.getSize();

        var rgb_data = try allocator.alloc(u8, size.height * size.width * 3);
        defer allocator.free(rgb_data);

        gl.readPixels(
            0,
            0,
            @as(gl.GLint, @intCast(size.width)),
            @as(gl.GLint, @intCast(size.height)),
            gl.BGR,
            gl.UNSIGNED_BYTE,
            @ptrCast(&rgb_data[0]),
        );

        const outfile = file.Tga.init(
            @intCast(size.width),
            @intCast(size.height),
            rgb_data,
        );

        try outfile.save(name);
    }

    pub fn deinit(self: Self) void {
        self.window.setInputModeCursor(.normal);
        self.window.destroy();
        glfw.terminate();
    }
};
