const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;

pub fn assertPrint(condition: bool, comptime fmt: []const u8, args: anytype) void {
    if (!condition) {
        print(fmt ++ "\n", args);
        assert(false);
    }
}
