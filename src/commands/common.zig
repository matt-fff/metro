const std = @import("std");
const clap = @import("clap");
const print = std.debug.print;

pub const Command = struct {
    name: []const u8,
    description: []const u8,
    usage: []const u8,
    handler: fn (tunnels: *std.ArrayList(Tunnel), iter: *std.process.ArgIterator, diag: *clap.Diagnostic, allocator: std.mem.Allocator) anyerror!void,
};

pub const Tunnel = struct {
    host: []const u8,
    local_port: u16,
    host_port: u16,
};

pub const parsers = .{
    .remote_host = clap.parsers.string,
    .port = clap.parsers.int(u16, 10),
};

pub const start_stop_usage =
    \\-h, --help                Display this help and exit
    \\--host <remote_host>      Optionally filter tunnels by remote host
    \\-l, --local <port>        Optionally filter tunnels by local port
    \\-r, --remote <port>       Optionally filter tunnels by host port
    \\
;

pub fn printUsage(usage: []const u8) !void {
    print("Usage:\n{s}", .{usage});
}
