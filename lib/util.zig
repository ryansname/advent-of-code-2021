const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;

pub fn dbg(src: std.builtin.SourceLocation, value: anytype) @TypeOf(value) {
    print("{s: >30}:{}:{}>\t{any}\n", .{src.file, src.line, src.column, value});
    return value;
}

pub fn assertPrint(condition: bool, comptime fmt: []const u8, args: anytype) void {
    if (!condition) {
        print(fmt ++ "\n", args);
        assert(false);
    }
}

pub fn readLineFromStdin(buffer: []u8, comptime prompt: []const u8, args: anytype) !?[]u8 {
    print(prompt, args);

    var line = (try std.io.getStdIn().reader().readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    // trim annoying windows-only carriage return character
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}
