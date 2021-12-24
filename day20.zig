const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const fmt = std.fmt;
const mem = std.mem;
const math = std.math;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const HashMap = std.HashMap;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day20.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const SparseImageMap = HashMap(V2, void, ImageMapContext, 75);
const ImageMapContext = struct {
    pub fn hash(_: ImageMapContext, v2: V2) u64 {
        var result: u64 = 0;
        result ^= @bitCast(u64, v2.x * 37);
        result ^= @bitCast(u64, v2.y * 37);
        return result;
    }

    pub fn eql(_: ImageMapContext, a: V2, b: V2) bool {
        return a.x == b.x and a.y == b.y;
    }
};

const V2 = struct {
    x: i64,
    y: i64,
};

const Image = struct {
    replacements: []bool,
    image: SparseImageMap,
    boundary_value: bool,
    min: V2 = .{ .x = 0, .y = 0 },
    max: V2 = .{ .x = 0, .y = 0 },

    fn addLight(self: *Image, light: V2) !void {
        try self.image.putNoClobber(light, {});

        if (light.x < self.min.x) self.min.x = light.x;
        if (light.x > self.max.x) self.max.x = light.x;
        if (light.y < self.min.y) self.min.y = light.y;
        if (light.y > self.max.y) self.max.y = light.y;
    }

    fn hasLight(self: Image, x: i64, y: i64) bool {
        if (x < self.min.x or x > self.max.x) return self.boundary_value;
        if (y < self.min.y or y > self.max.y) return self.boundary_value;
        return self.image.contains(.{ .x = x, .y = y });
    }
};

fn readInput(input: *Parser) !Image {
    var result = Image{
        .replacements = undefined,
        .image = SparseImageMap.init(alloc),
        .boundary_value = false,
    };

    const replacements_slice = (try input.takeType([]const u8, "\n")).?;
    result.replacements = try alloc.alloc(bool, replacements_slice.len);
    for (replacements_slice) |char, i| {
        result.replacements[i] = char == '#';
    }

    _ = try input.takeType([]const u8, "\n");

    var point = V2{ .x = 0, .y = 0 };
    while (try input.takeType([]const u8, "\n")) |line| {
        defer point.y += 1;

        for (line) |char, x| {
            if (char == '#') {
                point.x = @intCast(i64, x);
                try result.addLight(point);
            }
        }
    }

    return result;
}

fn enhance(image: Image) !Image {
    const new_boundary = if (image.boundary_value) blk: {
        break :blk image.replacements[image.replacements.len - 1];
    } else blk: {
        break :blk image.replacements[0];
    };
    var result = Image{
        .replacements = image.replacements,
        .image = SparseImageMap.init(image.image.allocator),
        .boundary_value = new_boundary,
    };

    var y = image.min.y - 1;
    while (y <= image.max.y + 1) : (y += 1) {
        var x = image.min.x - 1;
        while (x <= image.max.x + 1) : (x += 1) {
            var value: u9 = 0;
            for ([_]i8{ -1, 0, 1 }) |dy| {
                for ([_]i8{ -1, 0, 1 }) |dx| {
                    value <<= 1;
                    value += @boolToInt(image.hasLight(x + dx, y + dy));
                }
            }

            if (image.replacements[value]) _ = try result.addLight(.{ .x = x, .y = y });
        }
    }

    // print("\nAfter enhance: \n", .{});
    // y = result.min.y - 1;
    // while (y <= result.max.y + 1) : (y += 1) {
    //     var x = result.min.x - 1;
    //     while (x <= result.max.x + 1) : (x += 1) {
    //         const val = if (result.hasLight(x, y)) "#" else ".";
    //         print("{s}", .{val});
    //     }
    //     print("\n", .{});
    // }

    return result;
}

fn part1(input: *Parser) !u64 {
    var image = try readInput(input);

    image = try enhance(image);
    image = try enhance(image);

    const result = image.image.count();
    return result;
}

fn part2(input: *Parser) !u64 {
    var image = try readInput(input);

    for ([_]u8{undefined} ** 50) |_, i| {
        print("\rIter {}", .{i});
        image = try enhance(image);
    }

    const result = image.image.count();
    return result;
}

test "Part 1" {
    try expectEqual(@as(u64, 35), try part1(&Parser.init(
        \\..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
        \\
        \\#..#.
        \\#....
        \\##..#
        \\..#..
        \\..###
    )));
}

test "Part 2" {
    try expectEqual(@as(u64, 3351), try part2(&Parser.init(
        \\..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
        \\
        \\#..#.
        \\#....
        \\##..#
        \\..#..
        \\..###
    )));
}
