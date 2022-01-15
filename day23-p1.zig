const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const math = std.math;

const assertPrint = util.assertPrint;
const dbg = util.dbg;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const HashMap = std.HashMap;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const util = @import("lib/util.zig");
const REAL_INPUT = @embedFile("inputs/day23.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const Neighbours = BoundedArray(NodeId, 3);
const NodeId = usize;
const Node = struct {
    id: NodeId,
    critter: u16,
    home: u16,
    neighbours: Neighbours,

    fn isHallway(self: Node) bool {
        return self.home == 0;
    }
};

const World = struct {
    //  #############
    //  #01234567890#
    //  ###1#3#5#7###
    //    #2#4#6#8#
    //    #########
    nodes: [19]Node,

    fn nodesForCritter(self: World, critter: u16) [2]Node {
        const base = critter * 2 + 9;
        return [2]Node{
            self.nodes[base + 0],
            self.nodes[base + 1],
        };
    }

    fn linkNeighbours(a: *Node, b: *Node) void {
        a.neighbours.appendAssumeCapacity(b.id);
        b.neighbours.appendAssumeCapacity(a.id);
    }

    fn init() World {
        var result: World = undefined;
        for (result.nodes) |*node, i| {
            node.id = i;
            node.critter = 0;
            node.neighbours = Neighbours.init(0) catch unreachable;
            node.home = 0;

            switch (i) {
                0 => {},
                1...10 => linkNeighbours(node, &result.nodes[i - 1]),
                11, 13, 15, 17 => {
                    node.home = (@intCast(u16, i) - 9) / 2;
                    linkNeighbours(node, &result.nodes[i - 9]);
                },
                12, 14, 16, 18 => {
                    node.home = (@intCast(u16, i) - 10) / 2;
                    linkNeighbours(node, &result.nodes[i - 1]);
                },
                else => unreachable,
            }
        }
        return result;
    }

    fn isComplete(self: World) bool {
        for (self.nodes) |node| {
            if (node.critter != node.home) return false;
        }
        return true;
    }

    fn moveCritter(self: *World, from: NodeId, to: NodeId) void {
        const source = &self.nodes[from];
        const dest = &self.nodes[to];

        assert(dest.critter == 0);
        assert(source.critter != 0);
        assert(dest.home == 0 or dest.home == source.critter);
        dest.critter = source.critter;
        source.critter = 0;
    }

    fn printWorld(self: World) void {
        print("\n", .{});
        print("#" ** 13 ++ "\n", .{});
        print("#", .{});
        for (self.nodes[0..11]) |n| print("{}", .{n.critter});
        print("#\n", .{});
        print("###{}#{}#{}#{}###\n", .{ self.nodes[11].critter, self.nodes[13].critter, self.nodes[15].critter, self.nodes[17].critter });
        print("  #{}#{}#{}#{}#\n", .{ self.nodes[12].critter, self.nodes[14].critter, self.nodes[16].critter, self.nodes[18].critter });
        print("  " ++ "#" ** 9 ++ "  \n", .{});
    }
};

fn parseWorld(input: *Parser) !World {
    var result = World.init();
    _ = try input.takeType([]const u8, "\n");
    _ = try input.takeType([]const u8, "\n");
    var row: usize = 0;
    while (input.subparse("\n")) |*line| {
        if (row >= 2) break;

        result.nodes[11 + row].critter = line.source[3] - 'A' + 1;
        result.nodes[13 + row].critter = line.source[5] - 'A' + 1;
        result.nodes[15 + row].critter = line.source[7] - 'A' + 1;
        result.nodes[17 + row].critter = line.source[9] - 'A' + 1;

        row += 1;
    }

    return result;
}

const Move = struct {
    from: NodeId,
    to: NodeId,
    cost: u64,
};

/// Returns the total cost so far, or null if invalid
fn guessStep(in: World) ?u64 {
    var lowest_cost_so_far: ?u64 = null;
    // in.printWorld();

    if (in.isComplete()) {
        return 0;
    }

    const possible_moves = findPossibleMoves(in).slice();
    if (possible_moves.len == 0) return null;

    for (possible_moves) |move| {
        var next_world = in;

        next_world.moveCritter(move.from, move.to);
        const cost_for_this_move = guessStep(next_world) orelse continue;

        const cost_to_finish = cost_for_this_move + move.cost * (math.pow(u64, 10, in.nodes[move.from].critter - 1));
        lowest_cost_so_far = @minimum(lowest_cost_so_far orelse math.maxInt(u64), cost_to_finish);
    }

    // print("Return {}\n", .{lowest_cost_so_far});
    return lowest_cost_so_far;
}

fn findPossibleMoves(world: World) BoundedArray(Move, 64) {
    var result = BoundedArray(Move, 64).init(0) catch unreachable;

    // Optimisation:
    // If anyone in the hallway can go home, do that, it's always optimal
    go_home_check: for (world.nodes) |h, h_idx| {
        if (!h.isHallway()) continue;
        const critter = h.critter;
        if (critter == 0) continue;

        const target_nodes = world.nodesForCritter(critter);
        if (target_nodes[0].critter != 0) continue; // Room is completely full
        if (target_nodes[1].critter != 0 and target_nodes[1].critter != critter) continue; // Second space is taken, and not same type

        assert(target_nodes[0].critter == 0);
        assert(target_nodes[1].critter == 0 or target_nodes[1].critter == critter);

        const move_to_first_room = target_nodes[1].critter == critter;
        const index_outside_room = 2 * critter;
        // NOTE: We'll never be directly outside the room because of the movement rules
        if (!checkHallwayNodesEmpty(world, h_idx, index_outside_room)) continue :go_home_check;

        const distance = math.absInt(@intCast(isize, h_idx) - index_outside_room) catch unreachable;
        const room_idx = 1 - @as(u2, @boolToInt(move_to_first_room));
        const cost = distance + room_idx + 1;
        result.addOneAssumeCapacity().* = .{
            .from = h_idx,
            .to = target_nodes[room_idx].id,
            .cost = @intCast(u64, cost),
        };
        return result;
    }

    // By now we know that none of the hallway critters can move, due to rule 3
    for (world.nodes) |node, n_idx| {
        if (node.isHallway()) continue;
        if (node.critter == 0) continue;
        if (node.critter == node.home) {
            // If we're in the first room then we can stay (`continue`) iff the second slot is correct
            if (n_idx == 11 or n_idx == 13 or n_idx == 15 or n_idx == 17) {
                if (world.nodes[n_idx + 1].critter == node.home) continue;
            } else {
                continue;
            }
        }

        var exit_cost: u64 = 1;
        if (n_idx == 12 or n_idx == 14 or n_idx == 16 or n_idx == 18) {
            if (world.nodes[n_idx - 1].critter != 0) continue;
            exit_cost += 1;
        }

        const first_hall_idx = getHallwayIndex(n_idx);
        for ([_]i8{ 1, -1 }) |delta| {
            var distance: i64 = 0;
            while (true) {
                distance += delta;
                const check_idx = @intCast(u64, @intCast(i64, first_hall_idx) + distance);
                if (check_idx == 2 or check_idx == 4 or check_idx == 6 or check_idx == 8) continue;
                const check_node = world.nodes[check_idx];
                if (check_node.critter != 0) break;
                result.addOneAssumeCapacity().* = .{
                    .from = n_idx,
                    .to = check_idx,
                    .cost = exit_cost + @intCast(u64, (math.absInt(distance) catch unreachable)),
                };
                if (check_idx == 0 or check_idx == 10) break;
            }
        }
    }

    return result;
}

fn getHallwayIndex(idx: usize) usize {
    return switch (idx) {
        0...10 => idx,
        11, 13, 15, 17 => idx - 9,
        12, 14, 16, 18 => idx - 10,
        else => unreachable,
    };
}

/// Checks hallway nodes from start to end are empty. 
/// If start is in a room it is moved to the spot outside.
/// Assumes the starting index is alway ok.
fn checkHallwayNodesEmpty(world: World, start: usize, end_idx: usize) bool {
    var start_idx = getHallwayIndex(start);

    const dir: i30 = if (end_idx < start_idx) -1 else 1;
    var check_idx = @intCast(isize, start_idx) + dir;
    while (check_idx != end_idx) : (check_idx += dir) {
        if (world.nodes[@intCast(usize, check_idx)].critter != 0) return false;
    }
    return true;
}

fn part1(input: *Parser) !u64 {
    const world = try parseWorld(input);

    const min_path = guessStep(world).?;

    return min_path;
}

fn part2(input: *Parser) !u64 {
    return input.index;
}

test "find move to home left" {
    var world = World.init();
    world.nodes[7].critter = 1;

    var moves = findPossibleMoves(world).slice();
    try expectEqual(@as(usize, 1), moves.len);
    try expectEqual(@as(usize, 7), moves[0].from);
    try expectEqual(@as(usize, 12), moves[0].to);
    try expectEqual(@as(u64, 7), moves[0].cost);

    world.nodes[12].critter = 1;
    moves = findPossibleMoves(world).slice();
    try expectEqual(@as(usize, 1), moves.len);
    try expectEqual(@as(usize, 7), moves[0].from);
    try expectEqual(@as(usize, 11), moves[0].to);
    try expectEqual(@as(u64, 6), moves[0].cost);

    world.nodes[12].critter = 4;
    moves = findPossibleMoves(world).slice();
    try expectEqual(@as(usize, 4), moves.len);
}

test "find move to home right" {
    var world = World.init();
    world.nodes[3].critter = 4;

    var moves = findPossibleMoves(world).slice();
    try expectEqual(@as(usize, 1), moves.len);
    try expectEqual(@as(usize, 3), moves[0].from);
    try expectEqual(@as(usize, 18), moves[0].to);
    try expectEqual(@as(u64, 7), moves[0].cost);

    world.nodes[18].critter = 4;
    moves = findPossibleMoves(world).slice();
    try expectEqual(@as(usize, 1), moves.len);
    try expectEqual(@as(usize, 3), moves[0].from);
    try expectEqual(@as(usize, 17), moves[0].to);
    try expectEqual(@as(u64, 6), moves[0].cost);

    world.nodes[18].critter = 1;
    moves = findPossibleMoves(world).slice();
    try expectEqual(@as(usize, 4), moves.len);
}

test "find moves from start" {
    //  #############
    //  #01234567890#
    //  ###1#3#5#7###
    //    #2#4#6#8#
    //    #########

    var world = World.init();
    world.nodes[11].critter = 4;
    world.nodes[12].critter = 3;
    world.nodes[13].critter = 1;
    world.nodes[14].critter = 2;
    world.nodes[15].critter = 4;
    world.nodes[16].critter = 3;
    world.nodes[17].critter = 2;
    world.nodes[18].critter = 1;

    var moves = findPossibleMoves(world).slice();
    var expectedMoves = [_]Move{
        .{ .from = 11, .to = 0, .cost = 3 },
        .{ .from = 11, .to = 1, .cost = 2 },
        .{ .from = 11, .to = 3, .cost = 2 },
        .{ .from = 11, .to = 5, .cost = 4 },
        .{ .from = 11, .to = 7, .cost = 6 },
        .{ .from = 11, .to = 9, .cost = 8 },
        .{ .from = 11, .to = 10, .cost = 9 },
        .{ .from = 13, .to = 0, .cost = 5 },
        .{ .from = 13, .to = 1, .cost = 4 },
        .{ .from = 13, .to = 3, .cost = 2 },
        .{ .from = 13, .to = 5, .cost = 2 },
        .{ .from = 13, .to = 7, .cost = 4 },
        .{ .from = 13, .to = 9, .cost = 6 },
        .{ .from = 13, .to = 10, .cost = 7 },
        .{ .from = 15, .to = 0, .cost = 7 },
        .{ .from = 15, .to = 1, .cost = 6 },
        .{ .from = 15, .to = 3, .cost = 4 },
        .{ .from = 15, .to = 5, .cost = 2 },
        .{ .from = 15, .to = 7, .cost = 2 },
        .{ .from = 15, .to = 9, .cost = 4 },
        .{ .from = 15, .to = 10, .cost = 5 },
        .{ .from = 17, .to = 0, .cost = 9 },
        .{ .from = 17, .to = 1, .cost = 8 },
        .{ .from = 17, .to = 3, .cost = 6 },
        .{ .from = 17, .to = 5, .cost = 4 },
        .{ .from = 17, .to = 7, .cost = 2 },
        .{ .from = 17, .to = 9, .cost = 2 },
        .{ .from = 17, .to = 10, .cost = 3 },
    };

    try expectEqual(@as(usize, 28), moves.len);
    next_move: for (expectedMoves) |expectedMove| {
        for (moves) |move| {
            if (!meta.eql(move, expectedMove)) continue;
            continue :next_move;
        }
        expectEqual(expectedMove, .{ .from = 0, .to = 0, .cost = 0 }) catch |err| {
            print("Couldn't find {} in\n", .{expectedMove});
            for (moves) |m| print("{}\n", .{m});
            return err;
        };
    }
}

test "Part 1" {
    try expectEqual(@as(u64, 12521), try part1(&Parser.init(
        \\#############
        \\#...........#
        \\###B#C#B#D###
        \\  #A#D#C#A#
        \\  #########
    )));
}

test "Part 2" {}
