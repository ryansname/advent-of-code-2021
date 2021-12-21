const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;

const fmt = std.fmt;
const mem = std.mem;
const math = std.math;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day17.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const V2 = struct {
    x: i64,
    y: i64,
};

const IterTrajectoriesResult = struct {
    max_height: u64,
    count: u64,
};

fn iterTrajectories(min: V2, max: V2) IterTrajectoriesResult {
    var max_height: i64 = math.minInt(i64);
    var hit_count: u64 = 0;

    var init_x: i64 = 0;
    while (init_x <= max.x) : (init_x += 1) {
        var init_y: i64 = min.y;
        while (init_y < 5000) : (init_y += 1) {
            
            var pos = V2{ .x = 0, .y = 0 };
            var vel = V2{ .x = init_x, .y = init_y };
            var max_height_this_shot: i64 = math.minInt(i64);

            while (pos.x < max.x and pos.y > min.y) {
                pos.x += vel.x;
                pos.y += vel.y;

                vel.x = if (vel.x > 0) vel.x - 1 else if (vel.x == 0) 0 else vel.x + 1;
                vel.y -= 1;

                max_height_this_shot = @maximum(max_height_this_shot, pos.y);

                if (pos.x >= min.x and pos.x <= max.x and pos.y >= min.y and pos.y <= max.y) {
                    hit_count += 1;
                    max_height = @maximum(max_height, max_height_this_shot);
                    break;
                }
            }
        }
    }

    return .{
        .max_height = @intCast(u64, max_height),
        .count = hit_count,
    };
}

fn part1(input: *Parser) !u64 {
    _ = try input.takeType([]const u8, "=");
    const xmin = (try input.takeType(i64, ".")).?;
    _ = try input.takeType([]const u8, ".");
    const xmax = (try input.takeType(i64, ",")).?;
    _ = try input.takeType([]const u8, "=");
    const ymin = (try input.takeType(i64, ".")).?;
    _ = try input.takeType([]const u8, ".");
    const ymax = (try input.takeType(i64, ",")).?;

    return iterTrajectories(.{.x = xmin, .y = ymin}, .{.x = xmax, .y = ymax}).max_height;
}

fn part2(input: *Parser) !u64 {
    _ = try input.takeType([]const u8, "=");
    const xmin = (try input.takeType(i64, ".")).?;
    _ = try input.takeType([]const u8, ".");
    const xmax = (try input.takeType(i64, ",")).?;
    _ = try input.takeType([]const u8, "=");
    const ymin = (try input.takeType(i64, ".")).?;
    _ = try input.takeType([]const u8, ".");
    const ymax = (try input.takeType(i64, ",")).?;

    return iterTrajectories(.{.x = xmin, .y = ymin}, .{.x = xmax, .y = ymax}).count;
}

test "Part 1" {
    try expectEqual(@as(u64, 45), try part1(&Parser.init("target area: x=20..30, y=-10..-5")));
}

test "Part 2" {
    try expectEqual(@as(u64, 112), try part2(&Parser.init("target area: x=20..30, y=-10..-5")));
}
