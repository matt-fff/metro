const std = @import("std");
const clap = @import("clap");
const common = @import("common.zig");
const print = std.debug.print;

pub const command = common.Command{ .name = "start", .description = "Start ssh tunnels", .handler = handler, .usage = common.start_stop_usage };

fn handler(tunnels: *std.ArrayList(common.Tunnel), _: *std.process.ArgIterator, _: *clap.Diagnostic, _: std.mem.Allocator) !void {
    print("Starting metro ssh tunnels from {any}\n", .{tunnels});
    // TODO: Implement component creation logic
    // TODO: Implement server start logic
}
