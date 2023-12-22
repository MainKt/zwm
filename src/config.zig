pub const border_pixel = 1;
pub const snap_pixel = 32;
pub const show_bar = true;
pub const top_bar = true;

pub const fonts = [_][]const u8{"monospace:size=10"};

pub const colors = .{
    .normal = .{ .foreground = "#bbbbbb", .background = "#222222", .border = "#444444" },
    .selected = .{ .foreground = "#eeeeee", .background = "#005577", .border = "#005577" },
};

pub const tags = [_][]const u8{ "1", "2", "3", "4", "5", "6", "7", "8", "9" };

const Rule = struct {
    class: ?[]const u8 = null,
    instance: ?[]const u8 = null,
    title: ?[]const u8 = null,
    tags: u8,
    is_floating: bool = false,
    monitor: i32 = -1,

    // pub fn apply(client: *Client) void {
    //     _ = client;
    // }
};

pub const rules = [_]Rule{
    .{ .class = "Gimp", .tags = 0, .is_floating = true },
    .{ .class = "Firefox", .tags = 1 << 8 },
};

pub const master_width_factor = 0.55;
pub const master_count = 1;
pub const resize_hints = true;
pub const lock_fullscreen_focus = true;

const Layout = struct {
    symbol: []const u8,
    mode: enum { masterStack, monocle, floating },

    fn apply(self: *Layout) void {
        _ = self;
    }
};

pub const layouts = [_]Layout{
    .{ .symbol = "[]=", .mode = .masterStack },
    .{ .symbol = "[M]", .mode = .monocle },
    .{ .symbol = "><>", .mode = .floating },
};
