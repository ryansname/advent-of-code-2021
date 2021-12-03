const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

const eql = std.mem.eql;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

const REAL_INPUT = @embedFile("inputs/day02.txt");

pub fn main() !void {
    try part1(REAL_INPUT);
    try part2(REAL_INPUT);
}

fn part1(input: []const u8) !void {
    var lines = std.mem.split(u8, input, "\n");

    var depth: i64 = 0;
    var pos: i64 = 0;
    while (lines.next()) |line| {
        const space = indexOf(u8, line, " ").?;
        const dir = line[0..space];
        const delta = try parseInt(i64, line[space + 1..line.len], 10);

        if (eql(u8, dir, "up")) {
            depth -= delta;
        } else if (eql(u8, dir, "down")) {
            depth += delta;
        } else {
            assert(eql(u8, dir, "forward"));
            pos += delta;
        }
    }
    print("Part 1: {} x {} = {}\n", .{depth, pos, depth * pos});
}

fn part2(input: []const u8) !void {
    var lines = std.mem.split(u8, input, "\n");

    var aim: i64 = 0;
    var depth: i64 = 0;
    var pos: i64 = 0;
    while (lines.next()) |line| {
        const space = indexOf(u8, line, " ").?;
        const dir = line[0..space];
        const delta = try parseInt(i64, line[space + 1..line.len], 10);

        if (eql(u8, dir, "up")) {
            aim -= delta;
        } else if (eql(u8, dir, "down")) {
            aim += delta;
        } else {
            assert(eql(u8, dir, "forward"));
            pos += delta;
            depth += aim * delta;
        }
    }
    print("Part 2: {} x {} = {}\n", .{depth, pos, depth * pos});
}