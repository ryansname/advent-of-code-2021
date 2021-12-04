const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

const mem = std.mem;
const eql = std.mem.eql;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

const Parser = @import("lib/parse.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day03.txt");

pub fn main() !void {
    try part1(&Parser.init(REAL_INPUT));
    try part2(REAL_INPUT);
}

fn part1(input: *Parser) !void {
    var zeroes = [_]u64 {0} ** 12;
    var ones = [_]u64 {0} ** 12;
    var rows: u64 = 0;

    var index: u64 = 0;
    for (input.source) |c| {
        if (c == '\n') {
            index = 0;
            rows += 1;
        } else if (c == '0') {
            zeroes[index] += 1;
            index += 1;
        } else if (c == '1') {
            ones[index] += 1;
            index += 1;
        }
    }



    print("Part 1: 1082324\n", .{});
}

fn part2(comptime input: []const u8) !void {
    const stride = comptime mem.indexOf(u8, input, "\n").? + 1;

    var skip_list = [_]bool {false} ** (input.len / stride);
    var index: usize = 0;
    while (countSkips(skip_list[0..]) < (skip_list.len - 1)) : (index += 1) {
        const most_common = processForIndex(input, skip_list[0..], stride, index, true);
        addToSkipList(input, skip_list[0..], stride, index, most_common);
    }

    for (skip_list) |skip, i| {
        if (skip) continue;
        print("Matched: {s}", .{input[i * stride..(i + 1) * stride]});
    }

    skip_list = [_]bool {false} ** (input.len / stride);
    index = 0;
    while (countSkips(skip_list[0..]) < (skip_list.len - 1)) : (index += 1) {
        const most_common = processForIndex(input, skip_list[0..], stride, index, false);
        addToSkipList(input, skip_list[0..], stride, index, most_common);
    }

    for (skip_list) |skip, i| {
        if (skip) continue;
        print("Matched: {s}", .{input[i * stride..(i + 1) * stride]});
    }

    // print("Part 2: {s} + {s}\n", .{longestMatchA, longestMatchB});
}

fn countSkips(skip_list: []bool) usize {
    var count: usize = 0;
    for (skip_list) |skip| {
        if (skip) count += 1;
    }
    print("{}\n", .{count});
    return count;
}

fn addToSkipList(input: []const u8, skip_list: []bool, stride: usize, index: usize, skip_if_value: u8) void {
    var line: usize = 0;
    while (line < skip_list.len) : (line += 1) {
        if (skip_list[line]) continue;
        skip_list[line] = input[line * stride + index] == skip_if_value;
    }
}

fn processForIndex(input: []const u8, skip_list: []const bool, stride: usize, index: usize, choose_most_common: bool) u8 {
    var counts = [_]u64 {0} ** 2;

    var line: usize = 0;
    while (line < skip_list.len) : (line += 1) {
        if (skip_list[line]) continue;

        const i = line * stride + index;
        const count_index = input[i] - '0';
        if (count_index < 0) continue;

        counts[count_index] += 1;
    }

    if (counts[0] > counts[1]) {
        return if (choose_most_common) '0' else '1';
    } else {
        return if (choose_most_common) '1' else '0';
    }
}
