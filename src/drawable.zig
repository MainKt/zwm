const x11 = @import("x11.zig");
const std = @import("std");

pub const Cursor = struct {
    const Self = @This();

    display: *x11.Display,
    normal: x11.Cursor,
    resize: x11.Cursor,
    move: x11.Cursor,

    pub fn create(display: *x11.Display) Self {
        return Self{
            .display = display,
            .normal = x11.XCreateFontCursor(display, x11.XC_left_ptr),
            .resize = x11.XCreateFontCursor(display, x11.XC_sizing),
            .move = x11.XCreateFontCursor(display, x11.XC_fleur),
        };
    }

    pub fn destroy(self: *Self) void {
        _ = x11.XFreeCursor(self.display, self.normal);
        _ = x11.XFreeCursor(self.display, self.resize);
        _ = x11.XFreeCursor(self.display, self.move);
    }
};
