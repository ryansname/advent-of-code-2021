const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;

const mem = std.mem;
const absInt = std.math.absInt;
const indexOfScalar = std.mem.indexOfScalar;
const max = std.math.max;
const min = std.math.min;
const rotate = std.mem.rotate;
const round = std.math.round;
const sort = std.sort.sort;

const BoundedArray = std.BoundedArray;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day11.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

fn part1(input: *Parser) !u64 {
    var world_raw = try BoundedArray(u8, 100).init(0);
    const width: usize = 10;
    for (input.source) |c| {
        if (c == '\n') continue;
        try world_raw.append(c - '0');
    }
    var world: [100]u8 = world_raw.buffer;

    var flashes: u64 = 0;
    var iteration: u64 = 0;
    while (iteration < 100) : (iteration += 1) {
        for (world) |*w| {
            w.* += 1;
        }

        var last_flash_count: u64 = 99999999;
        while (flashes != last_flash_count) {
            last_flash_count = flashes;
            for (world) |*w, i| {
                if (w.* > 9) {
                    w.* = 0;
                    flashes += 1;

                    for (neighbour_indicies(world.len, width, i)) |ni| {
                        if (ni == null) break;
                        if (world[ni.?] == 0) continue;
                        world[ni.?] += 1;
                    }
                }
            }
        }
    }

    return flashes;
}

fn part2(input: *Parser) !u64 {
    var world_raw = try BoundedArray(u8, 100).init(0);
    const width: usize = 10;
    for (input.source) |c| {
        if (c == '\n') continue;
        try world_raw.append(c - '0');
    }
    var world: [100]u8 = world_raw.buffer;

    var flashes: u64 = 0;
    var iteration: u64 = 0;
    while (flashes < 100) : (iteration += 1) {
        flashes = 0;
        for (world) |*w| {
            w.* += 1;
        }

        var last_flash_count: u64 = 999999;
        while (flashes != last_flash_count) {
            last_flash_count = flashes;
            for (world) |*w, i| {
                if (w.* > 9) {
                    w.* = 0;
                    flashes += 1;

                    for (neighbour_indicies(world.len, width, i)) |ni| {
                        if (ni == null) break;
                        if (world[ni.?] == 0) continue;
                        world[ni.?] += 1;
                    }
                }
            }
        }
    }

    return iteration;
}

fn neighbour_indicies(count: usize, width: usize, location: usize) [9]?usize {
    var result = BoundedArray(?usize, 9).init(0) catch unreachable;

    const top_row = location < width;
    const bottom_row = location + width >= count;
    const left_col = location % width == 0;
    const right_col = location % width == width - 1;

    if (!top_row) {
        if (!left_col) result.append(location - width - 1) catch unreachable;
        result.append(location - width) catch unreachable;
        if (!right_col) result.append(location - width + 1) catch unreachable;
    }
    if (!left_col) result.append(location - 1) catch unreachable;
    if (!right_col) result.append(location + 1) catch unreachable;
    if (!bottom_row) {
        if (!left_col) result.append(location + width - 1) catch unreachable;
        result.append(location + width) catch unreachable;
        if (!right_col) result.append(location + width + 1) catch unreachable;
    }

    result.appendNTimes(null, result.buffer.len - result.len) catch unreachable;

    return result.buffer;
}

test "Part 1" {
    const test_input = 
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
    ;
    try expectEqual(@as(u64, 1656), try part1(&Parser.init(test_input)));
}

test "Part 2" {
    const test_input = 
        \\5483143223
        \\2745854711
        \\5264556173
        \\6141336146
        \\6357385478
        \\4167524645
        \\2176841721
        \\6882881134
        \\4846848554
        \\5283751526
    ;
    try expectEqual(@as(u64, 195), try part2(&Parser.init(test_input)));
}
