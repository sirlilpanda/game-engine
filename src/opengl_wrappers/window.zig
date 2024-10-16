const glfw = @import("mach-glfw");
const gl = @import("gl");
const std = @import("std");

const program = @import("program.zig");
const Bmp = @import("../file_loading/bmp.zig").Bmp;
const vec = @import("../math/vec.zig");

const window_logger = std.log.scoped(.Window);
const glfw_logger = std.log.scoped(.glfw);

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_logger.err("{}: {s}", .{ error_code, description });
}

/// gets the opengl procedure address
fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// wrapper on a glfw window
pub const Window = struct {
    const Self = @This();

    /// the glfw window
    window: glfw.Window,
    /// the the mouse was last
    last_mouse_pos: vec.Vec2 = vec.init2(0.0, 0.0),

    /// creates a new opengl window, with the given height and width
    pub fn init(width: u32, height: u32) !Self {
        window_logger.info("attempting to create window with width : {} and height : {}", .{ width, height });
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            glfw_logger.err("[ERROR] failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }
        // Create our window
        const window = glfw.Window.create(width, height, "game-shit-dwag", null, null, .{
            .opengl_profile = .opengl_core_profile,
            .context_version_major = 4,
            .context_version_minor = 5,
        }) orelse {
            glfw_logger.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        };
        glfw.makeContextCurrent(window);

        const proc: glfw.GLProc = undefined;

        gl.load(proc, glGetProcAddress) catch |err| {
            glfw_logger.err("failed to load opengl got error {any}\n", .{err});
        };

        return Self{
            .window = window,
        };
    }

    /// gets the aspect ratio of the window
    pub fn getAspectRatio(self: Self) f32 {
        const size = self.window.getSize();
        return @as(
            f32,
            @floatFromInt(size.width),
        ) / @as( // --------------------------------- // looks like a fraction
            f32,
            @floatFromInt(size.height),
        );
    }

    /// will more then likely be added to the app struct
    pub fn runRoutine(self: Self) !void {
        _ = self;
        @compileError("runRoutine not implement and i dont know if i ever will");
    }

    /// is the cursor
    pub fn hideCursor(self: Self) void {
        window_logger.info("hiding mouse cursor", .{});
        self.window.setInputModeCursor(.disabled);
    }

    /// shows the cursor
    pub fn showCursor(self: Self) void {
        window_logger.info("showing mouse cursor", .{});
        self.window.setInputModeCursor(.normal);
    }

    /// gets the current pos of the cursor
    pub inline fn getCursorPos(self: Self) vec.Vec2 {
        const mouse_pos = self.window.getCursorPos();
        return vec.init2(@floatCast(mouse_pos.xpos), @floatCast(mouse_pos.ypos));
    }

    /// gets the delta between the current pos and last pos of the mouse
    pub inline fn getCursorDelta(self: *Self) vec.Vec2 {
        const current_pos = self.getCursorPos();
        const mouse_delta = current_pos.sub(self.last_mouse_pos);
        self.last_mouse_pos = current_pos;
        return mouse_delta;
    }

    /// swaps the render buffers for displaying
    pub inline fn swapBuffer(self: Self) void {
        self.window.swapBuffers();
    }

    /// check to see if the window should close
    pub inline fn shouldClose(self: Self) bool {
        return self.window.shouldClose();
    }

    /// saves a screen shot of the current image as a bmp
    pub fn saveImg(self: Self, name: []const u8) !void {
        window_logger.info("saving screenshot {s}", .{name});
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        const size = self.window.getSize();
        window_logger.info("screenshot size {} x {} pixels", .{ size.width, size.height });
        var rgb_data = try allocator.alloc(u8, size.height * size.width * 3);
        defer allocator.free(rgb_data);

        gl.readnPixels(
            0,
            0,
            @as(gl.GLint, @intCast(size.width)),
            @as(gl.GLint, @intCast(size.height)),
            gl.RGB,
            gl.UNSIGNED_BYTE,
            @as(gl.GLsizei, @intCast(rgb_data.len)),
            @ptrCast(&rgb_data[0]),
        );

        var outfile = Bmp.init(
            @intCast(size.width),
            @intCast(size.height),
        );
        outfile.updateData(rgb_data);

        try outfile.save(name);
    }

    /// frees the window
    pub fn deinit(self: Self) void {
        window_logger.info("deinit-ing window", .{});
        self.window.setInputModeCursor(.normal);
        self.window.destroy();
        glfw.terminate();
    }
};
