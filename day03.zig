const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

const eql = std.mem.eql;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

const Parser = @import("lib/parse.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day03.txt");

pub fn main() !void {
    try part1(&Parser.init(REAL_INPUT));
    try part2(&Parser.init(REAL_INPUT));
}

fn part1(input: *Parser) !void {
    _ = try input.takeUntil("\n");
    try input.skipNewLine();
    const result = input.takeType(u64, "\n");
    print("Part 1: {}\n", .{result});
}

fn part2(input: *Parser) !void {
    const result = input.index;
    print("Part 2: {}\n", .{result});
}