const std = @import("std");
const Tunnel = @import("commands/common.zig").Tunnel;
const print = std.debug.print;
const Child = std.process.Child;

pub const config_struct = struct {
    tunnels: []Tunnel,
};

fn resolve_path(path: []const u8, page_allocator: std.mem.Allocator) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const argv = [_][]const u8{
        "sh",
        "-c",
        try std.fmt.allocPrint(arena_allocator, "echo {s}", .{path}),
    };

    // By default, child will inherit stdout & stderr from its parents,
    // this usually means that child's output will be printed to terminal.
    // Here we change them to pipe and collect into `ArrayList`.
    var child = Child.init(&argv, arena_allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    var stdout = std.ArrayList(u8).init(arena_allocator);
    var stderr = std.ArrayList(u8).init(arena_allocator);
    defer {
        stdout.deinit();
        stderr.deinit();
    }

    try child.spawn();
    try child.collectOutput(&stdout, &stderr, 1024);
    const term = try child.wait();

    if (term.Exited != 0) {
        print("Failed to resolve path: {s}\n", .{stderr.items});
        return error.FailedToResolvePath;
    }
    const trimmed = std.mem.trimRight(u8, stdout.items, "\n");
    if (trimmed.len == 0) {
        print("Error: resolved path is empty\n", .{});
        return error.EmptyPath;
    }
    return page_allocator.dupe(u8, trimmed);
}

pub fn load(config_path: []const u8) !std.ArrayList(Tunnel) {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get current working directory
    // Join the cwd with the expanded config path to get absolute path
    const abs_config_path = try resolve_path(config_path, allocator);
    defer allocator.free(abs_config_path);

    // Add validation
    if (abs_config_path.len == 0) {
        print("Error: config path is empty\n", .{});
        return error.InvalidConfigPath;
    }
    // Create parent directory if it doesn't exist
    const dirname = std.fs.path.dirname(abs_config_path) orelse {
        print("Error: could not get parent directory of config path\n", .{});
        return error.InvalidConfigPath;
    };
    // Try to create directory, ignore if it already exists
    std.fs.makeDirAbsolute(dirname) catch {};

    // Now we can safely create/open the file with the absolute path
    const file = try std.fs.createFileAbsolute(abs_config_path, .{ .read = true, .truncate = false });
    defer file.close();

    // Get file metadata
    var stat = try file.stat();

    // If file is empty, initialize with empty tunnels array
    if (stat.size == 0) {
        const empty_config = .{ .tunnels = &[_]Tunnel{} };
        try std.json.stringify(empty_config, .{}, file.writer());
        try file.sync();
        stat = try file.stat();
    }
    // Read and parse existing config
    const content = try file.readToEndAlloc(allocator, stat.size);
    defer allocator.free(content);

    var parsed = try std.json.parseFromSlice(
        config_struct,
        allocator,
        content,
        .{},
    );
    defer parsed.deinit();

    var tunnels = try std.ArrayList(Tunnel).initCapacity(
        allocator,
        parsed.value.tunnels.len,
    );
    try tunnels.appendSlice(parsed.value.tunnels);
    return tunnels;
}
