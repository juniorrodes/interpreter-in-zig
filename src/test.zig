pub const lexer = @import("lexer/lexer.zig");
const testing = @import("std").testing;

test "Test_runner" {
    //  _ = @import("lexer/lexer.zig");
    testing.refAllDecls(@This());
}
