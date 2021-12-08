const std = @import("std");

const print = std.debug.print;

const expectEqual = std.testing.expectEqual;

const absInt = std.math.absInt;
const max = std.math.max;
const min = std.math.min;
const round = std.math.round;

const Parser = @import("lib/parse2.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day07.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

fn part1(input: *Parser) !u64 {
    var positions_raw: [1024]u16 = undefined;
    var position_index: usize = 0;
    while (input.takeType(u16, ",")) |p| {
        positions_raw[position_index] = p;
        position_index += 1;
        _ = input.takeDelimiter(",") catch {};
    } else |e| {
        if (e != error.FinishedParsing) return e;
    }
    const positions = positions_raw[0..position_index];

    var min_fuel: u64 = 99999999999999;
    for (positions) |_, i| {
        var this_fuel: u64 = 0;
        for (positions) |p| {
            const fuel_for_this_position = @intCast(u64, try absInt(@intCast(i64, p) - @intCast(i64, i)));
            this_fuel += fuel_for_this_position;
        }

        min_fuel = min(min_fuel, this_fuel);
    }

    return min_fuel;
}

fn part2(input: *Parser) !u64 {
    var positions_raw: [1024]u16 = undefined;
    var position_index: usize = 0;
    while (input.takeType(u16, ",")) |p| {
        positions_raw[position_index] = p;
        position_index += 1;
        _ = input.takeDelimiter(",") catch {};
    } else |e| {
        if (e != error.FinishedParsing) return e;
    }
    const positions = positions_raw[0..position_index];

    var min_fuel: u64 = 99999999999999;
    for (positions) |_, i| {
        var this_fuel: u64 = 0;
        for (positions) |p| {
            const distance = @intCast(u64, try absInt(@intCast(i64, p) - @intCast(i64, i)));
            if (distance == 0) continue;
            const fuel_for_this_position = (distance * (1 + distance)) / 2;
            this_fuel += fuel_for_this_position;
        }

        min_fuel = min(min_fuel, this_fuel);
    }

    return min_fuel;
}

test "Part 1" {
    const test_input = "16,1,2,0,4,2,7,1,2,14";
    try expectEqual(@as(u64, 37), try part1(&Parser.init(test_input)));
}

test "Part 2" {
    const test_input = "16,1,2,0,4,2,7,1,2,14";
    try expectEqual(@as(u64, 168), try part2(&Parser.init(test_input)));
}
