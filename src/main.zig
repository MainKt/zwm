const std = @import("std");

const x11 = @import("x11.zig");

pub fn main() !void {
    var display: *x11.Display = x11.XOpenDisplay(null) orelse
        return std.debug.print("zwm: cannot open display", .{});
    defer _ = x11.XCloseDisplay(display);
}
