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

const BoundedArray = std.BoundedArray;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day14.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT), 40)});
}

const Substitution = struct {
    in: []const u8,
    out: []const u8,
};

fn part1(input: *Parser) !u64 {
    const buffer_size = 102400;
    var array1 = try BoundedArray(u8, buffer_size).init(0);
    var array2 = try BoundedArray(u8, buffer_size).init(0);

    try array1.appendSlice((try input.takeType([]const u8, "\n")).?);
    _ = try input.takeType([]const u8, "\n");

    var substitutions = try BoundedArray(Substitution, 100).init(0);
    while (input.subparse("\n")) |*line| {
        var sub = try substitutions.addOne();
        sub.in = (try line.takeType([]const u8, " ")).?;
        _ = try line.takeType([]const u8, " ");
        sub.out = (try line.takeType([]const u8, " ")).?;
    }

    var source = &array1;
    var dest = &array2;

    var iterations: usize = 0;
    while (iterations < 10) : (iterations += 1) {
        try dest.resize(0);

        const slice = source.slice();
        for (slice) |_, i| {
            if (i == 0) continue;

            const start = slice[i-1..i+1];
            try dest.append(start[0]);
            for (substitutions.slice()) |sub| {
                if (mem.eql(u8, sub.in, start)) {
                    try dest.appendSlice(sub.out);
                    break;
                }
            }
        }
        try dest.append(slice[slice.len - 1]);

        const temp = source;
        source = dest;
        dest = temp;
    }
    const final = source.slice();

    var counts = [_]u64 {0} ** 256;
    for (final) |c| counts[c] += 1;

    var max: u64 = 0;
    var min: u64 = math.maxInt(u64);
    for (counts) |c| {
        if (c == 0) continue;
        if (c > max) max = c;
        if (c < min) min = c;
    }
    assert(min < max);

    return max - min;
}

fn findIndex(buckets: []Substitution, pair: []const u8) ?usize {
    for (buckets) |*bucket, i| {
        if (mem.eql(u8, bucket.in, pair)) return i;
    }
    return null;
}

fn part2(input: *Parser, steps: usize) !u64 {
    const start = (try input.takeType([]const u8, "\n")).?;

    _ = try input.takeType([]const u8, "\n");

    var buckets_raw = try BoundedArray(Substitution, 100).init(0);

    while (input.subparse("\n")) |*line| {
        var sub = try buckets_raw.addOne();
        sub.in = (try line.takeType([]const u8, " ")).?;
        _ = try line.takeType([]const u8, " ");
        sub.out = (try line.takeType([]const u8, " ")).?;
    }
    const buckets = buckets_raw.slice();

    var counts = [_]u64 {0} ** 256;

    var array1 = [_]u64 {0} ** 100;
    var array2 = [_]u64 {0} ** 100;

    var source = array1[0..buckets.len];
    var dest = array2[0..buckets.len];

    // Initial load
    for (start) |char, i| {
        counts[char] += 1;
        if (i == 0) continue;
        var index = findIndex(buckets, start[i-1..i+1]).?;
        source[index] += 1;
    }

    var iterations: u64 = 0;
    while (iterations < steps) : (iterations += 1) {
        mem.set(u64, dest, 0);

        for (source) |count, i| {
            const substitution = buckets[i];
            counts[substitution.out[0]] += count;

            const out_index_a = findIndex(buckets, &[_]u8 {substitution.in[0], substitution.out[0]}).?;
            dest[out_index_a] += count;

            const out_index_b = findIndex(buckets, &[_]u8 {substitution.out[0], substitution.in[1]}).?;
            dest[out_index_b] += count;
        }

        const temp = source;
        source = dest;
        dest = temp;
    }

    var max: u64 = 0;
    var min: u64 = math.maxInt(u64);
    for (counts) |c| {
        if (c == 0) continue;
        if (c > max) max = c;
        if (c < min) min = c;
    }
    assert(min < max);

    return max - min;
}

test "Part 1" {
    const test_input = 
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
    ;
    try expectEqual(@as(u64, 1588), try part1(&Parser.init(test_input)));
}

test "Part 2" {
    const test_input = 
        \\NNCB
        \\
        \\CH -> B
        \\HH -> N
        \\CB -> H
        \\NH -> C
        \\HB -> C
        \\HC -> B
        \\HN -> C
        \\NN -> C
        \\BH -> H
        \\NC -> B
        \\NB -> B
        \\BN -> B
        \\BB -> N
        \\BC -> B
        \\CC -> N
        \\CN -> C
    ;
    try expectEqual(@as(u64, 1588), try part2(&Parser.init(test_input), 10));
    try expectEqual(@as(u64, 2188189693529), try part2(&Parser.init(test_input), 40));
}

test "Part 2 matches part 1" {
    try expectEqual(@as(u64, 2975), try part2(&Parser.init(REAL_INPUT), 10));
}
