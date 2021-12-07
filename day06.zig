const std = @import("std");

const print = std.debug.print;

const expectEqual = std.testing.expectEqual;

const Parser = @import("lib/parse.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day06.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

fn part1(input: *Parser) !u64 {
    return simulateFish(input, 80);
}

fn part2(input: *Parser) !u64 {
    return simulateFish(input, 256);
}

fn simulateFish(input: *Parser, days: u64) !u64 {
    var fish = [_]u64 {0} ** 7;
    var bebes = [_]u64 {0} ** 2;

    while (input.hasMore()) {
        const index = try input.takeType(usize, "\n,");
        _ = try input.takeDelimiter("\n,");

        fish[index] += 1;
    }

    var day: u64 = 0;
    while (day < days) : (day += 1) {
        const fishIndex = day % 7;
        const bebeIndex = day % 2;
        const newBebes = fish[fishIndex];
        const newFish = bebes[bebeIndex];

        bebes[bebeIndex] = newBebes;
        fish[fishIndex] += newFish;
    }

    var total_fish: u64 = 0;
    for (fish) |f| { total_fish += f; }
    for (bebes) |f| { total_fish += f; }
    return total_fish;
}

test "Part 1" {
    const test_input = "3,4,3,1,2\n";
    try expectEqual(@as(u64, 5934), try part1(&Parser.init(test_input)));
}
