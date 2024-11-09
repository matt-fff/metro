const std = @import("std");
const clap = @import("clap");
const print = std.debug.print;
const cmd_common = @import("commands/common.zig");
const cmd_add = @import("commands/add.zig");
const cmd_start = @import("commands/start.zig");
const cmd_stop = @import("commands/stop.zig");
const config = @import("config.zig");
const default_config_path = "$HOME/.config/.metro/tunnels.json";

const SubCommands = enum {
    add,
    start,
    stop,
};

const main_parsers = .{
    .command = clap.parsers.enumeration(SubCommands),
    .path = clap.parsers.string,
};

const main_usage =
    \\-h, --help          Display help and exit
    \\-c, --config <path>  An optional config file path
    \\<command>           The command to run (add, start, stop)
    \\
;
const main_params = clap.parseParamsComptime(main_usage);

pub fn cli() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var iter = try std.process.ArgIterator.initWithAllocator(allocator);
    defer iter.deinit();
    _ = iter.next(); // skip exe name

    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &main_params, main_parsers, &iter, .{
        .diagnostic = &diag,
        .allocator = allocator,

        // TODO this is basically fucked until I can get on the right version.
        // Clap only supports this on master, which requires Zig master.
        // And Zig master requires LLVM 19 - which isn't on Arch yet.
        // Come back to this.
        // .terminating_positional = 0,
    }) catch |err| {
        try diag.report(std.io.getStdErr().writer(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0 or res.positionals.len == 0) {
        try cmd_common.printUsage(main_usage);
        return;
    }

    const command = res.positionals[0];
    const config_path = if (res.args.config) |c| c else default_config_path;
    var tunnels = try config.load(config_path);

    switch (command) {
        .add => try cmd_add.command.handler(&tunnels, &iter, &diag, allocator),
        .start => try cmd_start.command.handler(&tunnels, &iter, &diag, allocator),
        .stop => try cmd_stop.command.handler(&tunnels, &iter, &diag, allocator),
    }
}
