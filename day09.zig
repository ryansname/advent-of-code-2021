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

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day09.txt");

const World = struct {
    height_map: [10000]u8,
    width: usize,
    count: usize,

    fn heights(self: World) []const u8 {
        return self.height_map[0..self.count];
    }
};

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

fn part1(input: *Parser) !u64 {
    const world = try load_world(input);

    var result: u64 = 0;
    next_location: for (world.heights()) |h, i| {

        const neighbours = find_neighbours(u8, world.heights(), world.width, i);
        for (neighbours) |nh| {
            if (nh == null) continue;
            if (h >= nh.?) continue :next_location;
        }
        assert(h < 10);
        result += h + 1;
    }

    return result;
}

fn part2(input: *Parser) !u64 {
    const world = try load_world(input);
    var basin_raw = [_]bool {false} ** 10_000;
    var basin = basin_raw[0..world.heights().len];

    for (world.heights()) |h, i| {
        if (h == 9) basin[i] = true;
    }

    var largest_three_groups = [_]u64 {0} ** 3;
    var current_min = &largest_three_groups[0];
    var index: usize = 0;
    while (index < basin.len) : (index += 1) {
        if (basin[index]) continue;
        const this_count = count(basin, index, world.width);

        if (this_count > current_min.*) {
            current_min.* = this_count;
            for (largest_three_groups) |*v| {
                if (v.* < current_min.*) current_min = v;
            }
        }
    }

    return largest_three_groups[0] * largest_three_groups[1] * largest_three_groups[2];
}

fn count(world: []bool, start_location: usize, width: usize) u64 {
    if (world[start_location]) return 0;

    var stack = [_]usize {undefined} ** 5000;
    stack[0] = start_location;
    var stack_index: usize = 1;

    var size: u64 = 0;
    while (stack_index > 0) {
        stack_index -= 1;
        const location = stack[stack_index];

        if (world[location]) continue;
        world[location] = true;
        size += 1;

        if (location % width != 0) {
            stack[stack_index] = location - 1;
            stack_index += 1;
        }
        if (location % width != width - 1) {
            stack[stack_index] = location + 1;
            stack_index += 1;
        }
        if (location >= width) {
            stack[stack_index] = location - width;
            stack_index += 1;
        }
        if (location < world.len - width) {
            stack[stack_index] = location + width;
            stack_index += 1;
        }
    }
    return size;
}

fn load_world(input: *Parser) !World {
    var world = [_]u8 {undefined} ** 10_000;
    var index: usize = 0;
    var width: usize = 0;
    while (input.subparse("\n")) |*line| {
        if (width != 0) assert(width == line.source.len);
        if (width == 0) width = line.source.len;

        while (try line.takeTypeByCount(u8, 1)) |depth| {
            world[index] = depth;
            index += 1;
        }
    }

    return World{
        .height_map = world,
        .width = width,
        .count = index,
    };
}

fn find_neighbours(comptime T: type, world: []const T, width: usize, location: usize) [4]?T {
    var result = [_]?T {null} ** 4;
    var index: usize = 0;
    if (location % width != 0) {
        result[index] = world[location - 1];
        index += 1;
    }
    if (location % width != width - 1) {
        result[index] = world[location + 1];
        index += 1;
    }
    if (location >= width) {
        result[index] = world[location - width];
        index += 1;
    }
    if (location < world.len - width) {
        result[index] = world[location + width];
        index += 1;
    }

    return result;
} 

test "Part 1" {
    const test_input = 
    \\2199943210
    \\3987894921
    \\9856789892
    \\8767896789
    \\9899965678
    ;
    try expectEqual(@as(u64, 15), try part1(&Parser.init(test_input)));
}

test "Part 2" {
    const test_input = 
    \\2199943210
    \\3987894921
    \\9856789892
    \\8767896789
    \\9899965678
    ;
    try expectEqual(@as(u64, 1134), try part2(&Parser.init(test_input)));
}
