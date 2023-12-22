const x11 = @import("x11.zig");
const std = @import("std");

pub const Dimension = struct { width: i32, height: i32 };
pub const Position = struct { x: i32, y: i32 };
pub const Screen = struct { number: i32, dimension: Dimension };

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

pub const Font = struct {
    const Self = @This();

    display: *x11.Display,
    xfont: *x11.XftFont,
    pattern: ?*x11.FcPattern,
    height: c_int,

    pub fn create(display: *x11.Display, screen: i32, font: struct {
        name: ?[]const u8 = null,
        pattern: ?*x11.FcPattern = null,
    }) !Font {
        var xfont: *x11.XftFont = undefined;
        var pattern: ?*x11.FcPattern = null;
        if (font.name) |name| {
            xfont = x11.XftFontOpenName(display, screen, @as([*c]const u8, @ptrCast(name))) orelse return error.CannotLoadFontFromName;
            pattern = x11.FcNameParse(@as([*c]const x11.FcChar8, @ptrCast(name))) orelse {
                x11.XftFontClose(display, xfont);
                return error.CannotParseFontNameToPattern;
            };
        } else if (font.pattern) |fc_pattern| {
            xfont = x11.XftFontOpenPattern(display, fc_pattern) orelse return error.CannotLoadFontFromPattern;
        } else {
            return error.NoFontSpecified;
        }
        return Self{
            .display = display,
            .xfont = xfont,
            .pattern = pattern,
            .height = xfont.ascent + xfont.descent,
        };
    }

    pub fn destroy(self: *Self) void {
        if (self.pattern) |pattern|
            x11.FcPatternDestroy(pattern);
        x11.XftFontClose(self.display, self.xfont);
    }
};

pub const ColorScheme = struct {
    foreground: x11.XftColor,
    background: x11.XftColor,
    border: x11.XftColor,

    pub fn create(display: *x11.Display, screen: i32, colors: struct { foreground: []const u8, background: []const u8, border: []const u8 }) !ColorScheme {
        return ColorScheme{
            .foreground = try allocateColor(display, screen, colors.foreground),
            .background = try allocateColor(display, screen, colors.background),
            .border = try allocateColor(display, screen, colors.border),
        };
    }

    fn allocateColor(display: *x11.Display, screen: i32, value: []const u8) !x11.XftColor {
        var color: x11.XftColor = undefined;

        if (x11.XftColorAllocName(display, x11.DefaultVisual(display, screen), x11.DefaultColormap(display, screen), @ptrCast(value), &color) == 0) {
            return error.CannotAllocateColor;
        }

        return color;
    }
};
