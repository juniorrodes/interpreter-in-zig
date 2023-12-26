const std = @import("std");
const Token = @import("../lexer/lexer.zig").Token;

const Identifier = struct {
    token: Token,
    value: []const u8,

    const Self = @This();

    fn TokenLiteral(self: *Self) []const u8 {
        return self.token.literal;
    }
};

fn Expression(comptime T: type) type {
    return struct {
        token: Token,
        value: T,
    };
}

const Statement = struct { token: Token, name: *Identifier, value: *Expression(u64) };

pub const Program = struct {
    statements: std.ArrayList(Statement),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        var statements = std.ArrayList(Statement).init(allocator);
        return Program{
            .statements = statements,
        };
    }

    pub fn TokenLiteral(self: *Self) []const u8 {
        if (self.statements.items.len > 0) {
            return self.statements.items[0].token.literal;
        } else {
            return "";
        }
    }
};
