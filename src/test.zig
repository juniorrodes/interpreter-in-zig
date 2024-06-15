const lexer = @import("lexer/lexer.zig");
const testing = @import("std").testing;

test "Test_runner" {
    testing.refAllDecls(@This());
}
