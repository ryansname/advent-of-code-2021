const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualStrings = std.testing.expectEqualStrings;

const debug = std.debug;
const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const math = std.math;
const sort = std.sort;

const assertPrint = util.assertPrint;
const dbg = util.dbg;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const HashMap = std.HashMap;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const util = @import("lib/util.zig");
const REAL_INPUT = @embedFile("inputs/day25.txt");

const CellValue = enum {
    empty,
    wall,
    down,
    right,
    down_m,
    right_m,
    moved,
};

const World = struct {
    start: usize,
    height: usize,
    width: usize,
    stride: usize,

    cells: []CellValue,
};

fn printWorld(world: World) void {
    var y: usize = 0;
    while (y < world.height) : (y += 1) {
        const row_start = world.start + y * world.stride;
        const row = world.cells[row_start .. row_start + world.width];

        for (row) |c| {
            const char: u8 = switch (c) {
                .wall => ' ',
                .empty => '.',
                .down => 'v',
                .right => '>',
                else => 'X',
            };
            print("{c}", .{char});
        }
        print("\n", .{});
    }
}

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

fn step(world: World) bool {
    // First the right facing herd moves, and no moving in a conga line
    for (world.cells) |c, i| {
        if (c != .right) continue;

        switch (world.cells[i + 1]) {
            .empty => {
                world.cells[i] = .moved;
                world.cells[i + 1] = .right_m;
            },
            .wall => {
                const wrapped_idx = i + 1 - world.width;
                if (world.cells[wrapped_idx] == .empty) {
                    world.cells[i] = .moved;
                    world.cells[wrapped_idx] = .right_m;
                }
            },
            else => {},
        }
    }
    for (world.cells) |*c| {
        if (c.* == .moved) c.* = .empty;
    }

    for (world.cells) |c, i| {
        if (c != .down) continue;

        const target_idx = i + world.stride;
        switch (world.cells[target_idx]) {
            .empty => {
                world.cells[i] = .moved;
                world.cells[target_idx] = .down_m;
            },
            .wall => {
                const wrapped_idx = target_idx - world.stride * world.height;
                if (world.cells[wrapped_idx] == .empty) {
                    world.cells[i] = .moved;
                    world.cells[wrapped_idx] = .down_m;
                }
            },
            else => {},
        }
    }

    var was_movement = false;
    for (world.cells) |*c| {
        switch (c.*) {
            .moved => c.* = .empty,

            .down_m => {
                c.* = .down;
                was_movement = true;
            },
            .right_m => {
                c.* = .right;
                was_movement = true;
            },
            else => {},
        }
    }
    return was_movement;
}

fn parseWorld(input: *Parser) !World {
    var cells = ArrayList(CellValue).init(alloc);
    errdefer cells.deinit();

    var height: usize = 0;
    var width: usize = undefined;
    while (input.subparse("\n")) |*line| {
        if (height == 0) {
            width = line.source.len;
            try cells.appendNTimes(.wall, width + 2);
        }
        height += 1;

        try cells.append(.wall);

        while (try line.takeTypeByCount([]const u8, 1)) |val| {
            const cell_value: CellValue = switch (val[0]) {
                '.' => .empty,
                '>' => .right,
                'v' => .down,
                else => debug.panic("Unexpected cell value {s}\n", .{val}),
            };
            try cells.append(cell_value);
        }

        try cells.append(.wall);
    }
    try cells.appendNTimes(.wall, width + 2);

    return World{
        .start = width + 3,
        .height = height,
        .width = width,
        .stride = width + 2,

        .cells = cells.toOwnedSlice(),
    };
}

fn part1(input: *Parser) !u64 {
    const world = try parseWorld(input);

    var steps: u64 = 0;
    while (step(world)) : (steps += 1) {
        // print("\n", .{});
        // printWorld(world);
    }
    // print("\n", .{});
    // printWorld(world);
    return steps + 1;
    // 449: High
}

fn part2(input: *Parser) !u64 {
    _ = input;
    return 0;
}

test "Part 1 test" {
    const world = try parseWorld(&Parser.init(
        \\...>...
        \\.......
        \\......>
        \\v.....>
        \\......>
        \\.......
        \\..vvv..
    ));

    // print("\n", .{});
    // printWorld(world);
    _ = step(world);
    // print("\n", .{});
    // printWorld(world);
    _ = step(world);
    // print("\n", .{});
    // printWorld(world);
    _ = step(world);
    // print("\n", .{});
    // printWorld(world);
    _ = step(world);
    // print("\n", .{});
    // printWorld(world);

    // debug.panic("Testing", .{});
}

test "Part 1" {
    try expectEqual(@as(u64, 58), try part1(&Parser.init(
        \\v...>>.vv>
        \\.vv>>.vv..
        \\>>.>v>...v
        \\>>v>>.>.v.
        \\v>v.vv.v..
        \\>.>>..v...
        \\.vv..>.>v.
        \\v.v..>>v.v
        \\....v..v.>
    )));
}

fn expectWorldAfterSteps(steps: *u64, desired_steps: u64, world: World, expected_cells: []const u8) !void {
    assert(steps.* <= desired_steps);

    while (steps.* < desired_steps) : (steps.* += 1) {
        _ = step(world);
    }

    // print("\nStep {}:\n", .{steps.*});
    // printWorld(world);

    const expected_end = try parseWorld(&Parser.init(expected_cells));
    try expectEqualSlices(CellValue, expected_end.cells, world.cells);
}

test "Part 1 detailed" {
    const world = try parseWorld(&Parser.init(
        \\v...>>.vv>
        \\.vv>>.vv..
        \\>>.>v>...v
        \\>>v>>.>.v.
        \\v>v.vv.v..
        \\>.>>..v...
        \\.vv..>.>v.
        \\v.v..>>v.v
        \\....v..v.>
    ));

    var steps: u64 = 0;

    try expectWorldAfterSteps(&steps, 0, world,
        \\v...>>.vv>
        \\.vv>>.vv..
        \\>>.>v>...v
        \\>>v>>.>.v.
        \\v>v.vv.v..
        \\>.>>..v...
        \\.vv..>.>v.
        \\v.v..>>v.v
        \\....v..v.>
    );

    try expectWorldAfterSteps(&steps, 1, world,
        \\....>.>v.>
        \\v.v>.>v.v.
        \\>v>>..>v..
        \\>>v>v>.>.v
        \\.>v.v...v.
        \\v>>.>vvv..
        \\..v...>>..
        \\vv...>>vv.
        \\>.v.v..v.v
    );

    try expectWorldAfterSteps(&steps, 2, world,
        \\>.v.v>>..v
        \\v.v.>>vv..
        \\>v>.>.>.v.
        \\>>v>v.>v>.
        \\.>..v....v
        \\.>v>>.v.v.
        \\v....v>v>.
        \\.vv..>>v..
        \\v>.....vv.
    );

    try expectWorldAfterSteps(&steps, 3, world,
        \\v>v.v>.>v.
        \\v...>>.v.v
        \\>vv>.>v>..
        \\>>v>v.>.v>
        \\..>....v..
        \\.>.>v>v..v
        \\..v..v>vv>
        \\v.v..>>v..
        \\.v>....v..
    );

    try expectWorldAfterSteps(&steps, 10, world,
        \\..>..>>vv.
        \\v.....>>.v
        \\..v.v>>>v>
        \\v>.>v.>>>.
        \\..v>v.vv.v
        \\.v.>>>.v..
        \\v.v..>v>..
        \\..v...>v.>
        \\.vv..v>vv.
    );

    try expectWorldAfterSteps(&steps, 58, world,
        \\..>>v>vv..
        \\..v.>>vv..
        \\..>>v>>vv.
        \\..>>>>>vv.
        \\v......>vv
        \\v>v....>>v
        \\vvv.....>>
        \\>vv......>
        \\.>v.vv.v..
    );
}
