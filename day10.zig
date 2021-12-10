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

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day10.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

fn part1(input: *Parser) !u64 {
    var total: u64 = 0;
    while (input.subparse("\n")) |*line| {
        var stack: [10_000]u8 = undefined;
        var index: usize = 0;

        for (line.source) |char| {
            switch (char) {
                '[', '(', '<', '{' => {
                    stack[index] = char;
                    index += 1;
                },
                ']', ')', '>', '}' => {
                    index -= 1;
                    var toMatch = stack[index];

                    var score: u64 = 0;
                    if (char == ')' and toMatch != '(') score = 3;
                    if (char == ']' and toMatch != '[') score = 57;
                    if (char == '}' and toMatch != '{') score = 1197;
                    if (char == '>' and toMatch != '<') score = 25137;

                    if (score > 0) {
                        total += score;
                        break;
                    }
                },
                else => return error.UnsupportedCharacter,
            }
        }
    }
    return total;
}

fn part2(input: *Parser) !u64 {
    var results: [1000]u64 = undefined;
    var result_index: usize = 0;

    next_line: while (input.subparse("\n")) |*line| {
        var stack: [10_000]u8 = undefined;
        var index: usize = 0;

        for (line.source) |char| {
            switch (char) {
                '[', '(', '<', '{' => {
                    stack[index] = char;
                    index += 1;
                },
                ']', ')', '>', '}' => {
                    index -= 1;
                    var toMatch = stack[index];

                    if (char == ')' and toMatch != '(') continue :next_line;
                    if (char == ']' and toMatch != '[') continue :next_line;
                    if (char == '}' and toMatch != '{') continue :next_line;
                    if (char == '>' and toMatch != '<') continue :next_line;
                },
                else => return error.UnsupportedCharacter,
            }
        }

        var score: u64 = 0;
        assert(index > 0);
        while (index > 0) {
            index -= 1;
            var char = stack[index];

            score *= 5;
            switch (char) {
                '(' => score += 1,
                '[' => score += 2,
                '{' => score += 3,
                '<' => score += 4,
                else => return error.UnsupportedCharacter,
            }
        }
        results[result_index] = score;
        result_index += 1;
    }

    sort(u64, results[0..result_index], {}, comptime std.sort.asc(u64));
    return results[0..result_index][result_index / 2];
}

test "Part 1" {
    const test_input = 
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
    ;
    try expectEqual(@as(u64, 26397), try part1(&Parser.init(test_input)));
}

test "Part 2" {
    const test_input = 
        \\[({(<(())[]>[[{[]{<()<>>
        \\[(()[<>])]({[<{<<[]>>(
        \\{([(<{}[<>[]}>{[]{[(<()>
        \\(((({<>}<{<{<>}{[]{[]{}
        \\[[<[([]))<([[{}[[()]]]
        \\[{[{({}]{}}([{[{{{}}([]
        \\{<[[]]>}<{[{[{[]{()[[[]
        \\[<(<(<(<{}))><([]([]()
        \\<{([([[(<>()){}]>(<<{{
        \\<{([{{}}[<[[[<>{}]]]>[]]
    ;
    try expectEqual(@as(u64, 288957), try part2(&Parser.init(test_input)));
}

test "Actual Solutions" {
    try expectEqual(@as(u64, 265527), try part1(&Parser.init(REAL_INPUT)));
    try expectEqual(@as(u64, 3969823589), try part2(&Parser.init(REAL_INPUT)));
}