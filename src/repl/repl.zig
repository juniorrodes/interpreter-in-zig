const std = @import("std");
const lexer = @import("../lexer/lexer.zig");

const PROMPT = ">> ";

fn next(l: *lexer.TokenIterator) lexer.Token {
    return l.NextToken() catch |err| {
        std.debug.print("{s}", .{@errorName(err)});
        return lexer.Token{ .tt = .Illegal, .literal = lexer.LiteralType.none };
    };
}

pub fn Start() !void {
    const stdin = std.io.getStdIn();
    var reader = stdin.reader();

    var allocator = std.heap.GeneralPurposeAllocator(.{}){};

    while (true) {
        std.debug.print("{s}", .{PROMPT});
        const line = try reader.readUntilDelimiterAlloc(allocator.allocator(), '\n', 200);

        var l = lexer.Lexer(line);
        var t: lexer.Token = next(&l);

        while (t.tt != .EOF) : (t = next(&l)) {
            std.debug.print("{s}\n", .{@tagName(t.tt)});
        }
    }
}
