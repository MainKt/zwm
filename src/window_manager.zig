const std = @import("std");

const x11 = @import("x11.zig");
const c = @import("c.zig");

pub fn run() !void {
    const display: *x11.Display = x11.XOpenDisplay(null) orelse
        return std.debug.print("zwm: cannot open display\n", .{});
    defer _ = x11.XCloseDisplay(display);

    if (c.setlocale(c.LC_CTYPE, "") == null or x11.XSupportsLocale() == x11.False)
        std.debug.print("warning: no locale support\n", .{});

    checkOtherWM(display);
}

var defaultErrorHandler: x11.XErrorHandler = undefined;

fn checkOtherWM(display: *x11.Display) void {
    defaultErrorHandler = x11.XSetErrorHandler(handleStartError);
    _ = x11.XSelectInput(display, x11.DefaultRootWindow(display), x11.SubstructureRedirectMask);
    _ = x11.XSync(display, x11.False);

    _ = x11.XSetErrorHandler(handleXerrors);
    _ = x11.XSync(display, x11.False);
}

fn setup() void {}

fn handleStartError(_: ?*x11.Display, _: [*c]x11.XErrorEvent) callconv(.C) c_int {
    std.debug.print("zwm: another window manager is already running\n", .{});
    std.process.exit(1);
    return -1;
}

fn handleXerrors(display: ?*x11.Display, error_event: [*c]x11.XErrorEvent) callconv(.C) c_int {
    const error_code = error_event.*.error_code;
    const request_code = error_event.*.request_code;

    const is_ignorable = error_code == switch (request_code) {
        x11.X_SetInputFocus, x11.X_ConfigureWindow => x11.BadMatch,
        x11.X_GrabButton, x11.X_GrabKey => x11.BadAccess,
        x11.X_PolyText8, x11.X_PolyFillRectangle, x11.X_PolySegment, x11.X_CopyArea => x11.BadDrawable,
        else => x11.BadWindow,
    };
    if (is_ignorable) return 0;

    std.debug.print(
        "zwm: fatal error: request code={d}, error code={d}",
        .{ request_code, error_code },
    );
    return defaultErrorHandler.?(display, error_event);
}
