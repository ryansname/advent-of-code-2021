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
const REAL_INPUT = @embedFile("inputs/day21.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

fn simulate(p1Start: u64, p2Start: u64) u64 {
    assert(p1Start <= 10);
    assert(p2Start <= 10);

    var p1_pos = p1Start - 1;
    var p2_pos = p2Start - 1; // Change from 1-10 to 0-9

    var p1_score: u64 = 0;
    var p2_score: u64 = 0;

    var die: u64 = 1;
    var rolls: u64 = 0;

    var p1Turn = true;
    while (p1_score < 1000 and p2_score < 1000) : (p1Turn = !p1Turn) {
        var pos: *u64 = undefined;
        var score: *u64 = undefined;
        if (p1Turn) {
            pos = &p1_pos;
            score = &p1_score;
        } else {
            pos = &p2_pos;
            score = &p2_score;
        }

        pos.* += 3 * die + 3;
        pos.* %= 10;
        score.* += pos.* + 1;
        die += 3;
        rolls += 3;

        // print("P1 = {}, pos = {}, score = {}\n", .{ p1Turn, pos.* + 1, score.* });
    }

    const losing_score = @minimum(p1_score, p2_score);
    return losing_score * rolls;
}

fn part1(input: *Parser) !u64 {
    _ = input;
    const p1Start = input.source[28] - '0';
    const p2Start = input.source[58] - '0';

    return simulate(p1Start, p2Start);
}

const Roll = struct {
    value: u32,
    count: u32 = 1,
};
fn initRolls() ![]Roll {
    var rolls = ArrayList(Roll).init(alloc);
    errdefer rolls.deinit();
    const single_roll = [_]u32{ 1, 2, 3 };
    for (single_roll) |a| {
        for (single_roll) |b| {
            for (single_roll) |c| {
                for (rolls.items) |*r| {
                    if (r.value == a + b + c) {
                        r.count += 1;
                        break;
                    }
                } else {
                    try rolls.append(.{ .value = a + b + c });
                }
            }
        }
    }
    return rolls.toOwnedSlice();
}

fn initStates() ![]State {
    var states = try ArrayList(State).initCapacity(alloc, 100000);
    errdefer states.deinit();
    var p1_score: u32 = 0;
    while (p1_score <= 21) : (p1_score += 1) {
        var p2_score: u32 = 0;
        while (p2_score <= 21) : (p2_score += 1) {
            if (p1_score == 21 and p2_score == 21) continue;

            var p1_pos: u32 = 0;
            while (p1_pos < 10) : (p1_pos += 1) {
                var p2_pos: u32 = 0;
                while (p2_pos < 10) : (p2_pos += 1) {
                    for ([_]Player{ .p1, .p2 }) |turn| {
                        try states.append(.{
                            .p1_score = p1_score,
                            .p2_score = p2_score,
                            .p1_pos = p1_pos,
                            .p2_pos = p2_pos,
                            .turn = turn,
                        });
                    }
                }
            }
        }
    }
    return states.toOwnedSlice();
}

const Player = enum { p1, p2 };
const State = struct {
    p1_score: u32,
    p2_score: u32,
    p1_pos: u32,
    p2_pos: u32,

    turn: Player,

    count: u64 = 0,

    fn winner(self: State) ?Player {
        return if (self.p1_score >= 21) Player.p1 else if (self.p2_score >= 21) Player.p2 else null;
    }
};

fn getFirstActiveNonWinningState(states: []State) ?*State {
    return for (states) |*state| {
        if (state.count == 0) continue;
        if (state.winner()) |_| continue;
        return state;
    } else null;
}

fn findState(states: []State, p1_score: u32, p2_score: u32, p1_pos: u32, p2_pos: u32, turn: Player) !*State {
    for (states) |*state| {
        if (state.p1_score == p1_score and
            state.p2_score == p2_score and
            state.p1_pos == p1_pos and
            state.p2_pos == p2_pos and
            state.turn == turn) return state;
    }
    const not_found_state = State{
        .p1_score = p1_score,
        .p2_score = p2_score,
        .p1_pos = p1_pos,
        .p2_pos = p2_pos,
        .turn = turn,
    };
    print("Not found: {}\n", .{not_found_state});
    return error.NotFound;
}

fn part2(input: *Parser) !u64 {
    var rolls = try initRolls();
    defer alloc.free(rolls);

    // Initialize all the possible states
    var states = try initStates();
    defer alloc.free(states);

    // Setup initial condition
    const p1Start = input.source[28] - '1';
    const p2Start = input.source[58] - '1';
    var matching_state = try findState(states, 0, 0, p1Start, p2Start, .p1);
    matching_state.count += 1;

    // Simulate
    while (getFirstActiveNonWinningState(states)) |state| {
        for (rolls) |roll| {
            var next_pos: u32 = undefined;
            var next_score: u32 = undefined;
            if (state.turn == .p1) {
                next_pos = state.p1_pos;
                next_score = state.p1_score;
            } else {
                next_pos = state.p2_pos;
                next_score = state.p2_score;
            }
            next_pos += roll.value;
            next_pos %= 10;
            next_score += next_pos + 1;
            next_score = @minimum(next_score, 21);

            const next_turn = if (state.turn == .p1) Player.p2 else Player.p1;

            var next_state = try findState(
                states,
                if (state.turn == .p1) next_score else state.p1_score,
                if (state.turn == .p2) next_score else state.p2_score,
                if (state.turn == .p1) next_pos else state.p1_pos,
                if (state.turn == .p2) next_pos else state.p2_pos,
                next_turn,
            );
            next_state.count += roll.count * state.count;
        }
        state.count = 0;
    }
    // for (states) |s| {
    //     if (s.count > 0) print("{}\n", .{s});
    // }

    var p1Wins: u64 = 0;
    var p2Wins: u64 = 0;
    for (states) |state| {
        const winner = state.winner() orelse continue;
        switch (winner) {
            .p1 => p1Wins += state.count,
            .p2 => p2Wins += state.count,
        }
    }

    return @maximum(p1Wins, p2Wins);
}

test "Part 1" {
    try expectEqual(@as(u64, 739785), try part1(&Parser.init(
        \\Player 1 starting position: 4
        \\Player 2 starting position: 8
    )));
}

test "Part 2" {
    try expectEqual(@as(u64, 444356092776315), try part2(&Parser.init(
        \\Player 1 starting position: 4
        \\Player 2 starting position: 8
    )));
}
