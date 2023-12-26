const std = @import("std");
const AST = @import("ast.zig");
const lexer = @import("../lexer/lexer.zig");

pub const Parser = struct {
    l: *lexer.TokenIterator,
    currentToken: lexer.Token,
    peekToken: lexer.Token,

    const Self = @This();

    pub fn new(l: *lexer.TokenIterator) Self {
        var parser = Parser{ .l = l };

        parser.nextToken();
        parser.nextToken();

        return parser;
    }

    fn nextToken(self: *Self) void {
        self.currentToken = self.peekToken;
        self.peekToken = self.l.NextToken();
    }
};
