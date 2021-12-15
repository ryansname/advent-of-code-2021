const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;

const mem = std.mem;
const math = std.math;
const absInt = std.math.absInt;
const indexOfScalar = std.mem.indexOfScalar;
const rotate = std.mem.rotate;
const round = std.math.round;
const sort = std.sort.sort;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day15.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const Node = struct {
    visited: bool = false,
    cost: u8,
    prev_node_idx: usize = math.maxInt(usize),
    min_cost_to_here: u64 = math.maxInt(u64),
};
const MAX_RISK = Node{
    .visited = true,
    .cost = math.maxInt(u8),
};

fn part1(input: *Parser) !u64 {
    const MAX_DIM = 102;
    var world_raw = try BoundedArray(Node, MAX_DIM * MAX_DIM).init(0);

    var stride: usize = undefined;
    var width: usize = undefined;
    var height: usize = 0;

    while (input.subparse("\n")) |*line| {
        if (height == 0) {
            width = line.source.len;
            stride = width + 2;
            try world_raw.appendNTimes(MAX_RISK, stride);
        } else {
            assert(width == line.source.len);
        }

        try world_raw.append(MAX_RISK);
        while (try line.takeTypeByCount(u8, 1)) |risk| {
            const node = Node{
                .cost = risk,
            };
            try world_raw.append(node);
        }
        try world_raw.append(MAX_RISK);

        height += 1;
    }
    try world_raw.appendNTimes(MAX_RISK, stride);

    var world = world_raw.slice();

    const start = stride + 1;
    const end = start + (height - 1) * stride + width - 1;

    world[start].min_cost_to_here = 0;
    world[start].prev_node_idx = 0;

    var fringe = try BoundedArray(usize, MAX_DIM * MAX_DIM).init(0);
    try fringe.append(start);

    while (world[end].prev_node_idx == MAX_RISK.prev_node_idx) {
        var lowest_unvisited_cost: u64 = math.maxInt(u64);
        var index_in_fringe: usize = undefined;
        for (fringe.slice()) |f_idx, i| {
            const f_cost = world[f_idx].min_cost_to_here;
            if (f_cost < lowest_unvisited_cost) {
                index_in_fringe = i;
                lowest_unvisited_cost = f_cost;
            }
        }

        const idx = fringe.swapRemove(index_in_fringe);
        const node = &world[idx];
        node.visited = true;

        // Node to the right
        const neighbour_indicies = [_]usize {
            idx + 1, idx - 1, idx + stride, idx - stride
        };
        for (neighbour_indicies) |n_idx| {
            const n_node = &world[n_idx];
            const cost = node.min_cost_to_here + n_node.cost;
            if (cost < n_node.min_cost_to_here) {
                n_node.min_cost_to_here = cost;
                n_node.prev_node_idx = idx;
            }

            if (
                !n_node.visited and 
                mem.indexOfScalar(usize, fringe.slice(), n_idx) == null
            ) {
                try fringe.append(n_idx);
            }
        }
    }


    return world[end].min_cost_to_here;
}

fn part2(input: *Parser) !u64 {
    var parsed_input = try BoundedArray(u8, 100 * 100).init(0);
    var parse_width: usize = mem.indexOfScalar(u8, input.source, '\n').?;
    for (input.source) |c| {
        if (c == '\n') continue;
        try parsed_input.append(c - '0');
    }

    const MAX_DIM = 502;
    var world_raw = try ArrayList(Node).initCapacity(alloc, MAX_DIM * MAX_DIM);
    defer world_raw.deinit();

    var width: usize = parse_width * 5;
    var stride: usize = width + 2;
    var start = stride + 1;

    try world_raw.appendNTimes(MAX_RISK, stride);
    var repeat_y: u8 = 0;
    while (repeat_y < 5) : (repeat_y += 1) {
        var idx: usize = 0;
        
        while (idx < parsed_input.len) : (idx += parse_width) {
            try world_raw.append(MAX_RISK);
    
            const row = parsed_input.slice()[idx..idx + parse_width];
            
            var repeat_x: u8 = 0;
            while (repeat_x < 5) : (repeat_x += 1) {
                for (row) |risk| {
                    var node = .{ .cost = risk + repeat_x + repeat_y };
                    while (node.cost > 9) { node.cost -= 9; }
                    try world_raw.append(node);
                }
            }

            try world_raw.append(MAX_RISK);
        }
    }
    try world_raw.appendNTimes(MAX_RISK, stride);

    var world = world_raw.toOwnedSlice();
    defer alloc.free(world);

    const end = world.len - stride - 2;

    world[start].min_cost_to_here = 0;
    world[start].prev_node_idx = 0;

    var fringe = try BoundedArray(usize, MAX_DIM * MAX_DIM).init(0);
    try fringe.append(start);

    while (world[end].prev_node_idx == MAX_RISK.prev_node_idx) {
        var lowest_unvisited_cost: u64 = math.maxInt(u64);
        var index_in_fringe: usize = undefined;
        for (fringe.slice()) |f_idx, i| {
            const f_cost = world[f_idx].min_cost_to_here;
            if (f_cost < lowest_unvisited_cost) {
                index_in_fringe = i;
                lowest_unvisited_cost = f_cost;
            }
        }

        const idx = fringe.swapRemove(index_in_fringe);
        const node = &world[idx];
        node.visited = true;

        // Node to the right
        const neighbour_indicies = [_]usize {
            idx + 1, idx - 1, idx + stride, idx - stride
        };
        for (neighbour_indicies) |n_idx| {
            const n_node = &world[n_idx];
            const cost = node.min_cost_to_here + n_node.cost;
            if (cost < n_node.min_cost_to_here) {
                n_node.min_cost_to_here = cost;
                n_node.prev_node_idx = idx;
            }

            if (
                !n_node.visited and 
                mem.indexOfScalar(usize, fringe.slice(), n_idx) == null
            ) {
                try fringe.append(n_idx);
            }
        }
    }


    return world[end].min_cost_to_here;
}

test "Part 1" {
    const test_input = 
        \\1163751742
        \\1381373672
        \\2136511328
        \\3694931569
        \\7463417111
        \\1319128137
        \\1359912421
        \\3125421639
        \\1293138521
        \\2311944581
    ;
    try expectEqual(@as(u64, 40), try part1(&Parser.init(test_input)));
}

test "Part 2" {
    const test_input = 
        \\1163751742
        \\1381373672
        \\2136511328
        \\3694931569
        \\7463417111
        \\1319128137
        \\1359912421
        \\3125421639
        \\1293138521
        \\2311944581
    ;
    try expectEqual(@as(u64, 315), try part2(&Parser.init(test_input)));
}
