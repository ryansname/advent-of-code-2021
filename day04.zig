const std = @import("std");

const assert = std.debug.assert;
const print = std.debug.print;

const mem = std.mem;
const eql = std.mem.eql;
const indexOf = std.mem.indexOf;
const parseInt = std.fmt.parseInt;

const Parser = @import("lib/parse.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day04.txt");

pub fn main() !void {
    try part1(&Parser.init(REAL_INPUT));
    try part2(&Parser.init(REAL_INPUT));
}

fn part1(input: *Parser) !void {
    var numbersRaw = [_]u8 {0} ** 256;

    numbersRaw[0] = try input.takeType(u8, ",\n");
    var i: u64 = 1;
    while ((try input.takeDelimiter(",\n")) != '\n') : (i += 1) {
        numbersRaw[i] = try input.takeType(u8, ",\n");
    }
    const numbers = numbersRaw[0..i];

    var boardsRaw = [_]u8 {0} ** 25 ** 512;
    var boardNumber: usize = 0;
    while (input.hasMore()) : (boardNumber += 1) {
        _ = try input.takeDelimiter(" \n");
        i = 0;
        while (i < 25) : (i += 1) {
            boardsRaw[i + boardNumber * 25] = try input.takeTypeByCount(u8, 2);
            _ = try input.takeDelimiter(" \n");
        }
    }
    const boards = boardsRaw[0..boardNumber * 25];
    var markedRaw = [_]bool {false} ** 25 ** 512;
    var marked = markedRaw[0..boards.len];

    var lastNumber: u8 = 0;
    const bingoIndex = for (numbers) |n| {
        lastNumber = n;
        for (boards) |value, valueIndex| {
            if (value == n) marked[valueIndex] = true;
        }

        if (findBoardWithBingo(marked)) |boardIndex| {
            break boardIndex;
        }
    } else 9999;

    const bingoBoard = boards[bingoIndex * 25..(bingoIndex + 1) * 25];
    const bingoMarks = marked[bingoIndex * 25..(bingoIndex + 1) * 25];
    var sum: u64 = 0;
    for (bingoBoard) |v, index| {
        if (!bingoMarks[index]) sum += v;
    }

    print("Part 1: {}\n", .{sum * lastNumber});
}

fn part2(input: *Parser) !void {
    var numbersRaw = [_]u8 {0} ** 256;

    numbersRaw[0] = try input.takeType(u8, ",\n");
    var i: u64 = 1;
    while ((try input.takeDelimiter(",\n")) != '\n') : (i += 1) {
        numbersRaw[i] = try input.takeType(u8, ",\n");
    }
    const numbers = numbersRaw[0..i];

    var boardsRaw = [_]u8 {0} ** 25 ** 512;
    var boardNumber: usize = 0;
    while (input.hasMore()) : (boardNumber += 1) {
        _ = try input.takeDelimiter(" \n");
        i = 0;
        while (i < 25) : (i += 1) {
            boardsRaw[i + boardNumber * 25] = try input.takeTypeByCount(u8, 2);
            _ = try input.takeDelimiter(" \n");
        }
    }
    const boards = boardsRaw[0..boardNumber * 25];
    var markedRaw = [_]bool {false} ** 25 ** 512;
    var marked = markedRaw[0..boards.len];

    var lastNumber: u8 = 0;
    const bingoIndex = for (numbers) |n| {
        lastNumber = n;
        var marked_here_this_round: ?usize = null;
        for (boards) |value, valueIndex| {
            if (value == n) {
                marked_here_this_round = valueIndex;
                marked[valueIndex] = true;
            }
        }

        if (allBoardsHaveBingo(marked)) {
            const result: usize = 44;
            break result;
        }
    } else 9999;

    const bingoBoard = boards[bingoIndex * 25..(bingoIndex + 1) * 25];
    const bingoMarks = marked[bingoIndex * 25..(bingoIndex + 1) * 25];
    var sum: u64 = 0;
    for (bingoBoard) |v, index| {
        print("{} {}\n", .{v, bingoMarks[index]});
        if (!bingoMarks[index]) sum += v;
    }

    print("Part 2: {} x {} = {}\n", .{sum, lastNumber, sum * lastNumber});
}

fn allBoardsHaveBingo(marks: []const bool) bool {
    var i: usize = 0;
    while (i < marks.len) : (i += 25) {
        if (!checkBoardForBingo(marks[i..i + 25])) {
            print("Board {} FALSE\n", .{i / 25});
            return false;
        }
    }
    return true;
}

fn findBoardWithBingo(marks: []const bool) ?usize {
    var i: usize = 0;
    while (i < marks.len) : (i += 25) {
        if (checkBoardForBingo(marks[i..i+25])) return i / 25;
    }
    return null;
}

fn checkBoardForBingo(board: []const bool) bool {
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        if (board[0 + 5 * i] and board[1 + 5 * i] and board[2 + 5 * i] and board[3 + 5 * i] and board[4 + 5 * i]) return true;
        if (board[0 + i] and board[5 + i] and board[10 + i] and board[15 + i] and board[20 + i]) return true;
    }
    return false;
}
