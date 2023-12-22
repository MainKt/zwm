const std = @import("std");

const window_manager = @import("window_manager.zig");

pub fn main() !void {
    const args = std.os.argv;
    if (args.len == 1) {
        try window_manager.start();
    } else if (args.len == 2 and std.mem.eql(u8, std.mem.span(args[1]), "-v")) {
        const version = @import("config").version;
        try std.io.getStdOut().writer().print("zwm-{s}\n", .{version});
    } else {
        std.debug.print("usage: zwm [-v]\n", .{});
        return error.InvalidArgument;
    }
}
