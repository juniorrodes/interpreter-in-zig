const repl = @import("repl/repl.zig");
const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello, welcome to mlang repl:\n", .{});

    try repl.Start();
}
