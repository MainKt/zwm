const std = @import("std");
const linux = std.os.linux;

const x11 = @import("x11.zig");
const c = @import("c.zig");

const config = @import("config.zig");

const Drawable = @import("drawable.zig");
const Dimension = Drawable.Dimension;
const Screen = Drawable.Screen;
const Cursor = Drawable.Cursor;
const Font = Drawable.Font;
const ColorScheme = Drawable.ColorScheme;

var display: *x11.Display = undefined;
var screen: Screen = undefined;
var root: x11.Window = undefined;
var cursor: Cursor = undefined;
var defaultErrorHandler: x11.XErrorHandler = undefined;
var fonts: [config.fonts.len]Font = undefined;
var color_scheme: struct {
    normal: ColorScheme,
    selected: ColorScheme,
} = undefined;

pub fn start() !void {
    display = x11.XOpenDisplay(null) orelse
        return blk: {
        std.debug.print("zwm: cannot open display\n", .{});
        break :blk error.UnableToOpenDisplay;
    };

    if (c.setlocale(c.LC_CTYPE, "") == null or x11.XSupportsLocale() == x11.False)
        std.debug.print("warning: no locale support\n", .{});

    checkOtherWM();

    preventChildZombies();
    cleanUpZombies();

    try init();
    cleanUp();
}

fn init() !void {
    screen = .{
        .number = x11.DefaultScreen(display),
        .dimension = .{
            .width = x11.DisplayWidth(display, screen.number),
            .height = x11.DisplayHeight(display, screen.number),
        },
    };

    root = x11.RootWindow(display, screen.number);

    cursor = Cursor.create(display);

    for (config.fonts, 0..) |font, i| {
        fonts[i] = try Font.create(display, screen.number, .{ .name = font });
    }

    color_scheme = .{
        .normal = try ColorScheme.create(display, screen.number, config.colors.normal),
        .selected = try ColorScheme.create(display, screen.number, config.colors.selected),
    };
}

fn cleanUp() void {
    for (&fonts) |*font| {
        font.destroy();
    }
    cursor.destroy();
    _ = x11.XCloseDisplay(display);
}

fn checkOtherWM() void {
    defaultErrorHandler = x11.XSetErrorHandler(handleStartError);
    _ = x11.XSelectInput(display, x11.DefaultRootWindow(display), x11.SubstructureRedirectMask);
    _ = x11.XSync(display, x11.False);

    _ = x11.XSetErrorHandler(handleXerrors);
    _ = x11.XSync(display, x11.False);
}

fn handleStartError(_: ?*x11.Display, _: [*c]x11.XErrorEvent) callconv(.C) c_int {
    std.debug.print("zwm: another window manager is already running\n", .{});
    std.process.exit(1);
    return -1;
}

fn handleXerrors(dpy: ?*x11.Display, error_event: [*c]x11.XErrorEvent) callconv(.C) c_int {
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
    return defaultErrorHandler.?(dpy, error_event);
}

/// Do not transform children into zombies when they terminate
fn preventChildZombies() void {
    var sig_action = linux.Sigaction{
        .handler = .{ .handler = linux.SIG.IGN },
        .mask = linux.empty_sigset,
        .flags = linux.SA.NOCLDSTOP | linux.SA.NOCLDWAIT | linux.SA.RESTART,
    };
    _ = linux.sigaction(linux.SIG.CHLD, &sig_action, null);
}

/// Clean up any zombies (inherited from .xinitrc etc) immediately
fn cleanUpZombies() void {
    var status: u32 = undefined;
    while (linux.waitpid(-1, &status, linux.W.NOHANG) > 0) {}
}
