const std = @import("std");
const cli = @import("cli.zig");
const print = std.debug.print;

pub fn main() !void {
    try cli.cli();
}
