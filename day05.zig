const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

const mem = std.mem;
const eql = std.mem.eql;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

const max = std.math.max;
const min = std.math.min;

const Parser = @import("lib/parse.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day05.txt");

pub fn main() !void {
    try part1(&Parser.init(REAL_INPUT));
    try part2(&Parser.init(REAL_INPUT));
}

const Line = struct {
    x1: usize,
    y1: usize,
    x2: usize,
    y2: usize,

    pub fn xmin(self: Line) usize { return min(self.x1, self.x2); }
    pub fn xmax(self: Line) usize { return max(self.x1, self.x2); }
    pub fn ymin(self: Line) usize { return min(self.y1, self.y2); }
    pub fn ymax(self: Line) usize { return max(self.y1, self.y2); }

    pub fn readFromParser(p: *Parser) !?Line {
        if (!p.hasMore()) return null;

        const x1 = try p.takeType(usize, ",");
        _ = try p.takeDelimiter(",");
        const y1 = try p.takeType(usize, " ");
        _ = try p.takeDelimiter(" ");
        _ = try p.takeDelimiter("-");
        _ = try p.takeDelimiter(">");
        _ = try p.takeDelimiter(" ");
        const x2 = try p.takeType(usize, ",");
        _ = try p.takeDelimiter(",");
        const y2 = try p.takeType(usize, "\n");
        _ = try p.takeDelimiter("\n");

        return Line{
            .x1 = x1,
            .y1 = y1,
            .x2 = x2,
            .y2 = y2,
        };
    }
};

fn part1(input: *Parser) !void {
    const board_size = 1000;
    var board = [_]u8 {0} ** board_size ** board_size;

    while (Line.readFromParser(input)) |line| {
        if (line == null) break;

        if (line.?.x1 == line.?.x2) {
            var y = line.?.ymin();
            while (y <= line.?.ymax()) : (y += 1) {
                board[y * board_size + line.?.x1] += 1;
            }
        } else if (line.?.y1 == line.?.y2) {
            var x = line.?.xmin();
            while (x <= line.?.xmax()) : (x += 1) {
                board[line.?.y1 * board_size + x] += 1;
            }
        }
    } else |err| {
        return err;
    }

    var sum: u64 = 0;
    for (board) |b| {
        if (b > 1) sum += 1;
    }

    print("Part 1: {}\n", .{sum});
}

fn part2(input: *Parser) !void {
    const board_size = 1000;
    var board = [_]u8 {0} ** board_size ** board_size;

    while (Line.readFromParser(input)) |line| {
        if (line == null) break;

        if (line.?.x1 == line.?.x2) {
            var y = line.?.ymin();
            while (y <= line.?.ymax()) : (y += 1) {
                board[y * board_size + line.?.x1] += 1;
            }
        } else if (line.?.y1 == line.?.y2) {
            var x = line.?.xmin();
            while (x <= line.?.xmax()) : (x += 1) {
                board[line.?.y1 * board_size + x] += 1;
            }
        } else {
            var x = @intCast(i32, line.?.x1);
            var y = @intCast(i32, line.?.y1);
            var dX = @intCast(i32, line.?.x2) - x; 
            dX = @divExact(dX, try std.math.absInt(dX));
            var dY = @intCast(i32, line.?.y2) - y;
            dY = @divExact(dY, try std.math.absInt(dY));
            while (x != line.?.x2) {
                board[@intCast(usize, y * board_size + x)] += 1;
                y += dY;
                x += dX;
            }
            board[@intCast(usize, y * board_size + x)] += 1;
            assert(y == line.?.y2);
        }
    } else |err| {
        return err;
    }

    var sum: u64 = 0;
    for (board) |b| {
        if (b > 1) sum += 1;
    }

    print("Part 2: {}\n", .{sum});
}
