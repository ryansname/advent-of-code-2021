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
const REAL_INPUT = @embedFile("inputs/day12.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const Cave = struct {
    id: []const u8,
    is_big: bool,
    neighbours: BoundedArray(*Cave, 25),
};

fn findOrCreateCave(caves: *BoundedArray(Cave, 50), id: []const u8) !*Cave {
    for (caves.slice()) |*c| {
        if (mem.eql(u8, c.id, id)) {
            return c;
        }
    } else {
        var new_cave = try caves.addOne();
        new_cave.* = Cave{
            .id = id,
            .is_big = std.ascii.isUpper(id[0]),
            .neighbours = try BoundedArray(*Cave, 25).init(0),
        };
        return new_cave;
    }
}

fn part1(input: *Parser) !u64 {
    var caves = try BoundedArray(Cave, 50).init(0);

    while (input.subparse("\n")) |*line| {
        const start = (try line.takeType([]const u8, "-")).?;
        const end = (try line.takeType([]const u8, "-")).?;

        var start_cave = try findOrCreateCave(&caves, start);
        var end_cave = try findOrCreateCave(&caves, end);

        try start_cave.neighbours.append(end_cave);
        try end_cave.neighbours.append(start_cave);
    }

    var already_seen = try BoundedArray(*const Cave, 50).init(0);

    for (caves.slice()) |*cave| {
        if (mem.eql(u8, cave.id, "start")) {
            try already_seen.append(cave);
            break;
        }
    }
    assert(already_seen.len == 1);

    return try traverse_and_count(already_seen.get(0), &already_seen);
}

fn traverse_and_count(here: *const Cave, already_visited: *BoundedArray(*const Cave, 50)) !u64 {
    if (mem.eql(u8, here.id, "end")) return 1;

    var paths_through_here: u64 = 0;
    for (here.neighbours.constSlice()) |neighbour| {
        if (!neighbour.is_big) {
            const index = mem.indexOfScalar(*const Cave, already_visited.slice(), neighbour);
            if (index) |_| continue;
        }
        
        try already_visited.append(neighbour);
        defer _ = already_visited.pop();

        paths_through_here += traverse_and_count(neighbour, already_visited) catch unreachable;
    }

    return paths_through_here;
}

fn part2(input: *Parser) !u64 {
    var caves = try BoundedArray(Cave, 50).init(0);

    while (input.subparse("\n")) |*line| {
        const start = (try line.takeType([]const u8, "-")).?;
        const end = (try line.takeType([]const u8, "-")).?;

        var start_cave = try findOrCreateCave(&caves, start);
        var end_cave = try findOrCreateCave(&caves, end);

        if (!mem.eql(u8, end_cave.id, "start")) try start_cave.neighbours.append(end_cave);
        if (!mem.eql(u8, start_cave.id, "start")) try end_cave.neighbours.append(start_cave);
    }

    var already_seen = try BoundedArray(*const Cave, 200).init(0);

    for (caves.slice()) |*cave| {
        if (mem.eql(u8, cave.id, "start")) {
            try already_seen.append(cave);
            break;
        }
    }
    assert(already_seen.len == 1);

    return try traverse_and_count_with_repeat(already_seen.get(0), &already_seen, false);
}

fn traverse_and_count_with_repeat(here: *const Cave, already_visited: *BoundedArray(*const Cave, 200), repeat_used: bool) !u64 {
    if (mem.eql(u8, here.id, "end")) return 1;

    var paths_through_here: u64 = 0;
    for (here.neighbours.constSlice()) |neighbour| {
        var is_repeat = repeat_used;
        if (!neighbour.is_big) {
            const index = mem.indexOfScalar(*const Cave, already_visited.slice(), neighbour);
            if (index) |_| {
                if (repeat_used) continue;
                is_repeat = true;
            }
        }
        
        try already_visited.append(neighbour);
        defer _ = already_visited.pop();

        paths_through_here += traverse_and_count_with_repeat(neighbour, already_visited, is_repeat) catch unreachable;
    }

    return paths_through_here;
}

test "Part 1 small" {
    const test_input =
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
    ;
    try expectEqual(@as(u64, 10), try part1(&Parser.init(test_input)));
}

test "Part 1 medium" {
    const test_input =
        \\dc-end
        \\HN-start
        \\start-kj
        \\dc-start
        \\dc-HN
        \\LN-dc
        \\HN-end
        \\kj-sa
        \\kj-HN
        \\kj-dc
    ;
    try expectEqual(@as(u64, 19), try part1(&Parser.init(test_input)));
}

test "Part 1 large" {
    const test_input =
        \\fs-end
        \\he-DX
        \\fs-he
        \\start-DX
        \\pj-DX
        \\end-zg
        \\zg-sl
        \\zg-pj
        \\pj-he
        \\RW-he
        \\fs-DX
        \\pj-RW
        \\zg-RW
        \\start-pj
        \\he-WI
        \\zg-he
        \\pj-fs
        \\start-RW
    ;
    try expectEqual(@as(u64, 226), try part1(&Parser.init(test_input)));
}

test "Part 2 small" {
    const test_input =
        \\start-A
        \\start-b
        \\A-c
        \\A-b
        \\b-d
        \\A-end
        \\b-end
    ;
    try expectEqual(@as(u64, 36), try part2(&Parser.init(test_input)));
}

test "Part 2 medium" {
    const test_input =
        \\dc-end
        \\HN-start
        \\start-kj
        \\dc-start
        \\dc-HN
        \\LN-dc
        \\HN-end
        \\kj-sa
        \\kj-HN
        \\kj-dc
    ;
    try expectEqual(@as(u64, 103), try part2(&Parser.init(test_input)));
}

test "Part 2 large" {
    const test_input =
        \\fs-end
        \\he-DX
        \\fs-he
        \\start-DX
        \\pj-DX
        \\end-zg
        \\zg-sl
        \\zg-pj
        \\pj-he
        \\RW-he
        \\fs-DX
        \\pj-RW
        \\zg-RW
        \\start-pj
        \\he-WI
        \\zg-he
        \\pj-fs
        \\start-RW
    ;
    try expectEqual(@as(u64, 3509), try part2(&Parser.init(test_input)));
}
