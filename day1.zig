const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const stdin = std.io.getStdIn();

const MB = 1024 * 1024;

pub fn main() !void {
    var alloc = &gpa.allocator;
    const buffer = try alloc.alloc(u8, 256 * MB);
    defer alloc.free(buffer);

    const bytesRead = try stdin.readAll(buffer);
    assert(bytesRead < buffer.len);

    const input = buffer[0..bytesRead];

    var lines = std.mem.split(u8, input, "\n");

    var part1Counter: u64 = 0;
    var prevValue = try std.fmt.parseInt(u64, lines.next().?, 10);
    while (lines.next()) |line| {
        const thisValue = try std.fmt.parseInt(u64, line, 10);
        defer prevValue = thisValue;

        if (thisValue > prevValue) part1Counter += 1;
    }

    print("Part 1: {}\n", .{part1Counter});

    lines.index = 0;
    var lineIndex: usize = 0;
    var part2Counter: u64 = 0;
    var prevValues = [_]u64 {0} ** 3;
    while (lines.next()) |line| : (lineIndex += 1) {
        const thisValue = try std.fmt.parseInt(u64, line, 10);
        if (lineIndex >= 3 and thisValue > prevValues[(lineIndex - 3) % prevValues.len]) part2Counter += 1;
        prevValues[lineIndex % prevValues.len] = thisValue;
    }

    print("Part 2: {}\n", .{part2Counter});
}
