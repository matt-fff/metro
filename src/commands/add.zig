const std = @import("std");
const clap = @import("clap");
const common = @import("common.zig");
const print = std.debug.print;

pub const command = common.Command{ .name = "add", .description = "Create a new SSH tunnel", .handler = handler, .usage = 
\\-h, --help                 Display this help and exit
\\-l, --local <port>         The local port to bind to
\\-r, --remote <port>        The host port to connect to
\\<remote_host>              The host to connect to
\\
};

fn handler(tunnels: *std.ArrayList(common.Tunnel), iter: *std.process.ArgIterator, diag: *clap.Diagnostic, allocator: std.mem.Allocator) !void {
    var add_res = clap.parseEx(clap.Help, &clap.parseParamsComptime(command.usage), common.parsers, iter, .{
        .diagnostic = diag,
        .allocator = allocator,
    }) catch |err| {
        try diag.report(std.io.getStdErr().writer(), err);
        return err;
    };
    defer add_res.deinit();

    if (add_res.args.help != 0 or add_res.positionals.len == 0) {
        try common.printUsage(command.usage);
        return;
    }

    const host = add_res.positionals[0];
    const local = if (add_res.args.local) |l| l else blk: {
        print("Enter local port: ", .{});
        var buf: [10]u8 = undefined;
        _ = std.io.getStdIn().reader().readUntilDelimiter(&buf, '\n') catch return error.InvalidInput;
        break :blk try std.fmt.parseInt(u16, buf[0..], 10);
    };
    const remote = if (add_res.args.remote) |r| r else blk: {
        print("Enter remote port: ", .{});
        var buf: [10]u8 = undefined;
        _ = std.io.getStdIn().reader().readUntilDelimiter(&buf, '\n') catch return error.InvalidInput;
        break :blk try std.fmt.parseInt(u16, buf[0..], 10);
    };

    try add(host, local, remote, tunnels);
}

fn add(host: []const u8, local_port: u16, host_port: u16, tunnels: *std.ArrayList(common.Tunnel)) !void {
    print("Adding new component: {s}:{d} -> {s}:{d}\n", .{ host, local_port, host, host_port });
    try tunnels.append(.{ .host = host, .local_port = local_port, .host_port = host_port });
    // TODO: Implement component creation logic
}
