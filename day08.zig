const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;

const absInt = std.math.absInt;
const indexOfScalar = std.mem.indexOfScalar;
const max = std.math.max;
const min = std.math.min;
const round = std.math.round;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day08.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
    // High: 1014835
}

fn part1(input: *Parser) !u64 {
    var result: u64 = 0;
    while (input.subparse("\n")) |*line| {
        _ = try line.takeType([]const u8, "|");
        _ = try line.takeDelimiter(" ");
        while (try line.takeType([]const u8, " ")) |signals| {
            if (signals.len == 2 or signals.len == 3 or signals.len == 4 or signals.len == 7) {
                result += 1;
            }
        }
    }
    return result;
}

fn part2(input: *Parser) !u64 {
    var sum: u64 = 0;
    while (input.subparse("\n")) |*line| {
        var digits: [10]u8 = undefined;
        for (digits) |_, i| {
            digits[i] = toU8((try line.takeType([]const u8, " ")).?);
        }

        var representations: [10]u8 = [_]u8 {1 << 7} ** 10;

        representations[1] = try takeByLength(digits, 2);
        representations[4] = try takeByLength(digits, 4);
        representations[7] = try takeByLength(digits, 3);
        representations[8] = try takeByLength(digits, 7);
        representations[2] = try findTwo(digits);
        representations[9] = try findNine(digits, representations[4], representations[8]);
        representations[3] = try findThree(digits, representations[1]);
        representations[5] = try findFive(digits, representations);
        representations[0] = try findZero(digits, representations);
        representations[6] = try findSix(digits, representations);

        for (representations) |r| assert(r < 1 << 7);
        assert(@popCount(u8, representations[0]) == 6);
        assert(@popCount(u8, representations[1]) == 2);
        assert(@popCount(u8, representations[2]) == 5);
        assert(@popCount(u8, representations[3]) == 5);
        assert(@popCount(u8, representations[4]) == 4);
        assert(@popCount(u8, representations[5]) == 5);
        assert(@popCount(u8, representations[6]) == 6);
        assert(@popCount(u8, representations[7]) == 3);
        assert(@popCount(u8, representations[8]) == 7);
        assert(@popCount(u8, representations[9]) == 6);
        for (representations) |r| assert(std.mem.count(u8, &representations, &[_]u8 {r}) == 1);

        try line.skipSequence("| ");

        var this_number: u64 = 0;
        while (try line.takeType([]const u8, " ")) |digit| {
            var decoded_digit = indexOfScalar(u8, &representations, toU8(digit)).?;
            this_number *= 10;
            this_number += decoded_digit;
        }
        assert(this_number < 10_000);
        sum += this_number;
    }

    return sum;
}

fn findSix(digits: [10]u8, representations: [10]u8) !u8 {
    for (digits) |digit| {
        if (indexOfScalar(u8, &representations, digit) == null) return digit;
    }
    return error.NotFound;
}

fn findZero(digits: [10]u8, representations: [10]u8) !u8 {
    var result: ?u8 = null;
    for (digits) |digit| {
        if (indexOfScalar(u8, &representations, digit) != null) continue;
        if (@popCount(u8, digit) != 6) continue;
        if (digit | representations[7] == digit) {
            assert(result == null);
            result = digit;
        }
    }
    return result.?;
}

fn findFive(digits: [10]u8, representations: [10]u8) !u8 {
    // From the three unknown digits only five is missing 2 segments
    var result: ?u8 = null;
    for (digits) |digit| {
        if (indexOfScalar(u8, &representations, digit) != null) continue;
        if (@popCount(u8, digit) == 5) {
            assert(result == null);
            result = digit;
        }
    }
    return result.?;
}

fn findThree(digits: [10]u8, one: u8) !u8 {
    // From digits missing 2 segments only three can be ored with one
    var result: ?u8 = null;
    for (digits) |digit| {
        if (@popCount(u8, digit) != 5) continue;
        if (one | digit == digit) {
            assert(result == null);
            result = digit;
        }
    }
    return result.?;
}

fn findNine(digits: [10] u8, four: u8, eight: u8) !u8 {
    // From (9,8,4) contains 4
    var result: ?u8 = null;
    for (digits) |digit| {
        if (digit == eight) continue;
        if (digit == four) continue;
        if (four & digit == four) {
            assert(result == null);
            result = digit;
        }
    }
    return result.?;
}

fn findTwo(digits: [10]u8) !u8 {
    // 2 is the only one with F off
    var bit: u8 = 1;
    nextBit: while (bit < 1 << 8) : (bit <<= 1) {
        var missingIndex: ?usize = null;

        for (digits) |digit, i| {
            if (digit & bit == 0) {
                if (missingIndex == null) {
                    missingIndex = i;
                } else {
                    continue :nextBit;
                }
            }
        }
        if (missingIndex) |i| return digits[i];
    }

    return error.NotFound;
}

fn toU8(segments: []const u8) u8 {
    var result: u8 = 0;
    for (segments) |s| {
        result += @as(u8, 1) << @intCast(u3, s - 'a');
    }
    return result;
}

fn takeByLength(digits: [10]u8, length: usize) !u8 {
    for (digits) |digit| {
        if (@popCount(u8, digit) == length) return digit;
    }
    return error.NotFound;
}

test "Part 1" {
    const test_input = 
    \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
    \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
    \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
    \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
    \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
    \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
    \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
    \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
    \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
    \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
    ;
    try expectEqual(@as(u64, 26), try part1(&Parser.init(test_input)));
}

test "Part 2 a" {
    const test_input = 
    \\acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf
    ;
    try expectEqual(@as(u64, 5353), try part2(&Parser.init(test_input)));
}

test "Part 2 b" {
    const test_input = 
    \\be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe
    \\edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc
    \\fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg
    \\fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb
    \\aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea
    \\fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb
    \\dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe
    \\bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef
    \\egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb
    \\gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce
    ;
    try expectEqual(@as(u64, 61229), try part2(&Parser.init(test_input)));
}
