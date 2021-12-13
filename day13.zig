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
const REAL_INPUT = @embedFile("inputs/day13.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT), 1311, 895)});
    // 1259 high
    // 802 high
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT), 1311, 895)});
}

fn part1(input: *Parser, comptime width_in: u32, comptime height_in: u32) !u64 {
    var width: u32 = width_in;
    var height: u32 = height_in;
    var pitch = width;

    var paper = [_]u8 {'.'} ** (width_in * height_in);

    while (input.subparse("\n")) |*line| {
        if (line.source.len == 0) break;

        const x = (try line.takeType(u64, ",")).?;
        const y = (try line.takeType(u64, ",")).?;
        paper[x + y * pitch] = '#';
    }

    var line = input.subparse("\n").?;
    const fold_dir = line.source[11];

    if (fold_dir == 'y') {
        var y_front: usize = 0;
        var y_back: usize = height - 1;
        defer height /= 2;

        while (y_front != y_back) {
            defer y_front += 1;
            defer y_back -= 1;
            var x: usize = 0;
            while (x < width) : (x += 1) {
                var back = &paper[x + y_back * pitch];
                if (back.* == '#') {
                    paper[x + y_front * pitch] = '#';
                    back.* = '.';
                }
            }
        }
    } else {
        assert(fold_dir == 'x');
        var x_front: usize = 0;
        var x_back: usize = width - 1;
        defer width /= 2;

        while (x_front != x_back) {
            defer x_front += 1;
            defer x_back -= 1;
            var y: usize = 0;
            while (y < height) : (y += 1) {
                var back = &paper[x_back + y * pitch];
                if (back.* == '#') {
                    paper[x_front + y * pitch] = '#';
                    back.* = '.';
                }
            }
        }
    }

    // var y: usize = 0;
    // while (y < height) : (y += 1) {
    //     var x: usize = 0;
    //     while (x < width) : (x += 1) {
    //         print("{s}", .{&[_]u8 {paper[x + y * pitch]}});
    //     }
    //     print("\n", .{});
    // }

    return std.mem.count(u8, &paper, "#");
}

fn part2(input: *Parser, comptime width_in: u32, comptime height_in: u32) !u64 {
    var width: u32 = width_in;
    var height: u32 = height_in;
    var pitch = width;

    var paper = [_]u8 {' '} ** (width_in * height_in);

    while (input.subparse("\n")) |*line| {
        if (line.source.len == 0) break;

        const x = (try line.takeType(u64, ",")).?;
        const y = (try line.takeType(u64, ",")).?;
        paper[x + y * pitch] = '#';
    }

    while (input.subparse("\n")) |*line| {
        const fold_dir = line.source[11];

        if (fold_dir == 'y') {
            var y_front: usize = 0;
            var y_back: usize = height - 1;
            defer height /= 2;

            while (y_front != y_back) {
                defer y_front += 1;
                defer y_back -= 1;
                var x: usize = 0;
                while (x < width) : (x += 1) {
                    var back = &paper[x + y_back * pitch];
                    if (back.* == '#') {
                        paper[x + y_front * pitch] = '#';
                        back.* = ' ';
                    }
                }
            }
        } else {
            assert(fold_dir == 'x');
            var x_front: usize = 0;
            var x_back: usize = width - 1;
            defer width /= 2;

            while (x_front != x_back) {
                defer x_front += 1;
                defer x_back -= 1;
                var y: usize = 0;
                while (y < height) : (y += 1) {
                    var back = &paper[x_back + y * pitch];
                    if (back.* == '#') {
                        paper[x_front + y * pitch] = '#';
                        back.* = ' ';
                    }
                }
            }
        }
    }

    print("Part 2: Below letters\n", .{});
    var y: usize = 0;
    while (y < height) : (y += 1) {
        var x: usize = 0;
        while (x < width) : (x += 1) {
            print("{s}", .{&[_]u8 {paper[x + y * pitch]}});
        }
        print("\n", .{});
    }

    return 0;
}

test "Part 1" {
    const test_input = 
        \\6,10
        \\0,14
        \\9,10
        \\0,3
        \\10,4
        \\4,11
        \\6,0
        \\6,12
        \\4,1
        \\0,13
        \\10,12
        \\3,4
        \\3,0
        \\8,4
        \\1,10
        \\2,14
        \\8,10
        \\9,0
        \\
        \\fold along y=7
        \\fold along x=5
    ;
    try expectEqual(@as(u64, 17), try part1(&Parser.init(test_input), 11, 15));
}
