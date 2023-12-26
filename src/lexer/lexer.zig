const std = @import("std");
const parseIntError = std.fmt.ParseIntError;

const asciiHelper = fn (ch: u8) bool;

const TokenType = enum {
    Illegal,
    EOF,

    // Identifiers
    Ident,
    Int,

    // Operators
    Assign,
    Plus,
    Minus,
    Bang,
    Asterisk,
    Slash,
    GreaterThan,
    LessThan,
    Equal,
    NotEqual,

    // Delimiters
    Comma,
    Semicolon,

    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,

    // Keywords
    Function,
    Let,
    If,
    Else,
    True,
    False,
    Return,
};
const LexerError = error{ InvalidCharacter, NumberOverflow };

pub const LiteralType = union(enum) { LiteralS: []const u8, LiteralI: u64, LiteralF: f64, none };
pub const Token = struct { tt: TokenType, literal: LiteralType };

const keywordMap = std.ComptimeStringMap(TokenType, .{
    .{ "let", TokenType.Let },
    .{ "fn", TokenType.Function },
    .{ "if", TokenType.If },
    .{ "else", TokenType.Else },
    .{ "true", TokenType.True },
    .{ "false", TokenType.False },
    .{ "return", TokenType.Return },
});

fn lookUpIdent(ident: []const u8) Token {
    const tt = keywordMap.get(ident) orelse TokenType.Ident;

    return Token{ .tt = tt, .literal = LiteralType.none };
}

pub const TokenIterator = struct {
    input: []const u8,
    position: u32,
    read_position: u32,
    ch: u8,

    const Self = @This();

    fn readChar(self: *Self) void {
        if (self.read_position >= self.input.len) {
            self.ch = 0;
        } else {
            self.ch = self.input[self.read_position];
        }

        self.position = self.read_position;
        self.read_position += 1;
    }

    fn advamcePosition(self: *Self, comptime f: asciiHelper) void {
        while (f(self.ch)) : (self.readChar()) {}
    }

    fn readIdentifier(self: *Self) Token {
        const position = self.position;
        self.advamcePosition(std.ascii.isAlphabetic);

        const ident = self.input[position..self.position];

        return lookUpIdent(ident);
    }

    fn readInt(self: *Self) LexerError!Token {
        const position = self.position;
        self.advamcePosition(std.ascii.isDigit);

        const number = std.fmt.parseInt(u64, self.input[position..self.position], 10) catch |err| {
            switch (err) {
                parseIntError.InvalidCharacter => return LexerError.InvalidCharacter,
                parseIntError.Overflow => return LexerError.NumberOverflow,
            }
        };

        return Token{ .tt = TokenType.Int, .literal = LiteralType{ .LiteralI = number } };
    }

    fn peekNext(self: *Self) u8 {
        if (self.read_position > self.input.len) {
            return 0;
        }

        return self.input[self.read_position];
    }

    pub fn NextToken(self: *Self) LexerError!Token {
        while (std.ascii.isWhitespace(self.ch)) : (self.readChar()) {}

        const tok = switch (self.ch) {
            '=' => t: {
                if (self.peekNext() == '=') {
                    self.readChar();

                    break :t Token{ .tt = .Equal, .literal = LiteralType.none };
                }
                break :t Token{ .tt = .Assign, .literal = LiteralType.none };
            },
            '+' => Token{ .tt = .Plus, .literal = LiteralType.none },
            '(' => Token{ .tt = .LeftParen, .literal = LiteralType.none },
            ')' => Token{ .tt = .RightParen, .literal = LiteralType.none },
            '{' => Token{ .tt = .LeftBrace, .literal = LiteralType.none },
            '}' => Token{ .tt = .RightBrace, .literal = LiteralType.none },
            ';' => Token{ .tt = .Semicolon, .literal = LiteralType.none },
            ',' => Token{ .tt = .Comma, .literal = LiteralType.none },
            '!' => t: {
                if (self.peekNext() == '=') {
                    self.readChar();

                    break :t Token{ .tt = .NotEqual, .literal = LiteralType.none };
                }
                break :t Token{ .tt = .Bang, .literal = LiteralType.none };
            },
            '*' => Token{ .tt = .Asterisk, .literal = LiteralType.none },
            '/' => Token{ .tt = .Slash, .literal = LiteralType.none },
            '-' => Token{ .tt = .Minus, .literal = LiteralType.none },
            '>' => Token{ .tt = .GreaterThan, .literal = LiteralType.none },
            '<' => Token{ .tt = .LessThan, .literal = LiteralType.none },
            0 => Token{ .tt = .EOF, .literal = LiteralType.none },
            else => {
                if (std.ascii.isAlphabetic(self.ch)) {
                    return self.readIdentifier();
                }
                if (std.ascii.isDigit(self.ch)) {
                    return self.readInt();
                }
                return LexerError.InvalidCharacter;
            },
        };

        self.readChar();

        return tok;
    }
};

pub fn Lexer(input: []const u8) TokenIterator {
    var l = TokenIterator{
        .input = input,
        .position = 0,
        .read_position = 0,
        .ch = 0,
    };

    l.readChar();

    return l;
}

test "New_Token" {
    const testing = @import("std").testing;

    const input =
        \\let five = 5; 
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\  x + y;
        \\};
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\
        \\if(5 < 10) {
        \\  return true;
        \\} else {
        \\  return false;
        \\}
        \\
        \\10 == 10;
    ;

    var l = Lexer(input);

    const result = [_]Token{ .{
        .tt = .Let,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "five" },
    }, .{
        .tt = .Assign,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 5 },
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .Let,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "ten" },
    }, .{
        .tt = .Assign,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 10 },
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .Let,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "add" },
    }, .{
        .tt = .Assign,
        .literal = LiteralType.none,
    }, .{
        .tt = .Function,
        .literal = LiteralType.none,
    }, .{
        .tt = .LeftParen,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "x" },
    }, .{
        .tt = .Comma,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "y" },
    }, .{
        .tt = .RightParen,
        .literal = LiteralType.none,
    }, .{
        .tt = .LeftBrace,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "x" },
    }, .{
        .tt = .Plus,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "y" },
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .RightBrace,
        .literal = LiteralType.none,
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .Let,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "result" },
    }, .{
        .tt = .Assign,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "add" },
    }, .{
        .tt = .LeftParen,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "five" },
    }, .{
        .tt = .Comma,
        .literal = LiteralType.none,
    }, .{
        .tt = .Ident,
        .literal = LiteralType{ .LiteralS = "ten" },
    }, .{
        .tt = .RightParen,
        .literal = LiteralType.none,
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .Bang,
        .literal = LiteralType.none,
    }, .{
        .tt = .Minus,
        .literal = LiteralType.none,
    }, .{
        .tt = .Slash,
        .literal = LiteralType.none,
    }, .{
        .tt = .Asterisk,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 5 },
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 5 },
    }, .{
        .tt = .LessThan,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 10 },
    }, .{
        .tt = .GreaterThan,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 5 },
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .If,
        .literal = LiteralType.none,
    }, .{
        .tt = .LeftParen,
        .literal = LiteralType.none,
    }, .{ .tt = .Int, .literal = LiteralType{ .LiteralI = 5 } }, .{
        .tt = .LessThan,
        .literal = LiteralType.none,
    }, .{ .tt = .Int, .literal = LiteralType{ .LiteralI = 10 } }, .{
        .tt = .RightParen,
        .literal = LiteralType.none,
    }, .{
        .tt = .LeftBrace,
        .literal = LiteralType.none,
    }, .{
        .tt = .Return,
        .literal = LiteralType.none,
    }, .{ .tt = .True, .literal = LiteralType.none }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .RightBrace,
        .literal = LiteralType.none,
    }, .{
        .tt = .Else,
        .literal = LiteralType.none,
    }, .{
        .tt = .LeftBrace,
        .literal = LiteralType.none,
    }, .{
        .tt = .Return,
        .literal = LiteralType.none,
    }, .{
        .tt = .False,
        .literal = LiteralType.none,
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .RightBrace,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 10 },
    }, .{
        .tt = .Equal,
        .literal = LiteralType.none,
    }, .{
        .tt = .Int,
        .literal = LiteralType{ .LiteralI = 10 },
    }, .{
        .tt = .Semicolon,
        .literal = LiteralType.none,
    }, .{
        .tt = .EOF,
        .literal = LiteralType.none,
    } };

    std.debug.print("\nTotal steps: {d}\n", .{result.len});

    for (result, 0..result.len) |v, i| {
        const t = try l.NextToken();
        testing.expect(v.tt == t.tt) catch |err| {
            std.debug.print("#{d} --> got token: {s}, expect token: {s}\n", .{ i, @tagName(t.tt), @tagName(v.tt) });
            return err;
        };
        switch (t.literal) {
            LiteralType.LiteralS => {
                testing.expect(std.mem.eql(u8, v.literal.LiteralS, t.literal.LiteralS)) catch |err| {
                    std.debug.print("#{d} --> got string literal: {s}, expect string literal: {s}\n", .{ i, t.literal.LiteralS, v.literal.LiteralS });
                    return err;
                };
            },
            LiteralType.LiteralI => {
                testing.expect(v.literal.LiteralI == t.literal.LiteralI) catch |err| {
                    std.debug.print("#{d} --> got int: {d}, expect int: {d}\n", .{ i, t.literal.LiteralI, v.literal.LiteralI });
                    return err;
                };
            },
            LiteralType.none => continue,
            else => unreachable,
        }
    }
}
