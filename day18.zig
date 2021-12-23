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
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day18.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const Number = []Element;
fn serializeNumber(self: Number) ![]u8 {
    var buffer = ArrayList(u8).init(alloc);
    for (self) |elem| {
        try switch (elem) {
            .start => buffer.append('['),
            .middle => buffer.append(','),
            .end => buffer.append(']'),
            .digit => |d| buffer.append('0' + d),
        };
    }
    return buffer.toOwnedSlice();
}

const Element = union(enum) {
    digit: u8,
    start: void,
    middle: void,
    end: void,
};

fn reduce(number: *Number) !bool {
    var prev_digit_index: ?usize = null;
    var value_to_add_to_next_digit: ?u8 = null;
    var write_index: usize = 0;
    var read_index: usize = 0;
    var depth: u8 = 0;

    // First scan for depth
    var action_performed = false;
    while (read_index < number.len) : (read_index += 1) {
        const element = number.*[read_index];

        if (element == .digit and value_to_add_to_next_digit != null) {
            number.*[write_index] = .{ .digit = element.digit + value_to_add_to_next_digit.? };
            value_to_add_to_next_digit = null;
        } else {
            number.*[write_index] = element;
        }
        defer write_index += 1;

        if (action_performed) continue;

        switch (element) {
            .start => depth += 1,
            .end => depth -= 1,
            else => {},
        }

        if (element == .digit) {
            if (depth > 4) {
                // print("Exploding at index {} with depth = {}, char = {}\n", .{ read_index, depth, number.*[read_index] });
                action_performed = true;

                // First lets add the lhs to the previous digit if there was one
                if (prev_digit_index) |d| {
                    assert(number.*[d] == .digit);
                    number.*[d] = .{ .digit = number.*[d].digit + element.digit };
                }

                // Then we'll add the rhs to the next digit if there is one
                assert(number.*[read_index + 2] == .digit);
                value_to_add_to_next_digit = number.*[read_index + 2].digit;

                // Finally replace the entire snailfish number with 0
                assert(number.*[write_index] == .digit);
                assert(number.*[write_index - 1] == .start);
                assert(number.*[read_index + 1] == .middle);
                assert(number.*[read_index + 2] == .digit);
                assert(number.*[read_index + 2].digit == value_to_add_to_next_digit.?);
                assert(number.*[read_index + 3] == .end); // We should be trying to read the remaining ,x]
                number.*[write_index - 1] = .{ .digit = 0 };
                write_index -= 1;
                read_index += 3;
            } else {
                // print("Previous digit index is now {} = {c}\n", .{ write_index, number.*[write_index] });
                prev_digit_index = write_index;
            }
        }
    }
    if (action_performed) {
        number.* = number.*[0..write_index];
        return true;
    }

    var new_number = ArrayList(Element).init(alloc);
    for (number.*) |n| {
        if (!action_performed and n == .digit and n.digit > 9) {
            // print("Splitting at index {}, value = {}\n", .{ i, n });
            try new_number.append(.start);
            try new_number.append(.{ .digit = n.digit / 2 });
            try new_number.append(.middle);
            try new_number.append(.{ .digit = @floatToInt(u8, @ceil(@intToFloat(f32, n.digit) / 2)) });
            try new_number.append(.end);
            action_performed = true;
        } else {
            try new_number.append(n);
        }
    }
    number.* = new_number.toOwnedSlice();

    return action_performed;
}

fn add(a: Number, b: Number) !Number {
    var result_buffer = ArrayList(Element).init(alloc);

    try result_buffer.append(.start);
    try result_buffer.appendSlice(a);
    try result_buffer.append(.middle);
    try result_buffer.appendSlice(b);
    try result_buffer.append(.end);

    var result = result_buffer.toOwnedSlice();
    // print("Before reduciton: {s}\n", .{try serializeNumber(result)});
    while (try reduce(&result)) {
        // print("{s}\n", .{try serializeNumber(result)});
    }
    // print("Fully reduced\n", .{});

    return result;
}

fn addList(number_per_line: []const u8) !Number {
    var input = Parser.init(number_per_line);
    var lhs = try parse((try input.takeType([]const u8, "\n")).?);
    while (try input.takeType([]const u8, "\n")) |line| {
        const rhs = try parse(line);
        lhs = try add(lhs, rhs);
    }
    return lhs;
}

fn magnitudeOf(number: Number) u64 {
    const number_str = serializeNumber(number) catch unreachable;
    // print("Number: {s}\n", .{number_str});
    var index: usize = 0;
    return magnitudeOfRecurse(number_str, &index);
}

fn magnitudeOfRecurse(values: []const u8, index: *usize) u64 {
    while (index.* < values.len) {
        const char = values[index.*];

        switch (char) {
            '0'...'9' => {
                index.* += 1;
                return char - '0';
            },
            '[' => {
                // 3 * x + 2 * y
                index.* += 1; // [
                const lhs = magnitudeOfRecurse(values, index);
                index.* += 1; // ,
                const rhs = magnitudeOfRecurse(values, index);
                index.* += 1; // ]
                // print("3x{} + 2x{}\n", .{ lhs, rhs });
                return 3 * lhs + 2 * rhs;
            },
            else => unreachable,
        }
    }
    unreachable;
}

fn part1(input: *Parser) !u64 {
    const result = try addList(input.source);
    return magnitudeOf(result);
}

fn part2(input: *Parser) !u64 {
    var largest_magniture: u64 = 0;

    var input_lines = ArrayList([]const u8).init(alloc);
    defer input_lines.deinit();

    while (try input.takeType([]const u8, "\n")) |line| try input_lines.append(line);
    const lines = input_lines.items;

    var pair = ArrayList(u8).init(alloc);
    defer pair.deinit();

    var index_1: usize = 0;
    while (index_1 < lines.len) : (index_1 += 1) {
        var index_2: usize = 0;
        while (index_2 < lines.len) : (index_2 += 1) {
            if (index_1 == index_2) continue;

            pair.clearRetainingCapacity();
            try pair.appendSlice(lines[index_1]);
            try pair.append('\n');
            try pair.appendSlice(lines[index_2]);

            const this_sum = try addList(pair.items);
            const this_magnitude = magnitudeOf(this_sum);
            largest_magniture = @maximum(largest_magniture, this_magnitude);
        }
    }

    return largest_magniture;
}

fn parse(input_string: []const u8) anyerror!Number {
    var number_builder = ArrayList(Element).init(alloc);

    for (input_string) |char| {
        switch (char) {
            '[' => try number_builder.append(.start),
            ',' => try number_builder.append(.middle),
            ']' => try number_builder.append(.end),
            '0'...'9' => try number_builder.append(.{ .digit = char - '0' }),
            else => unreachable,
        }
    }

    return number_builder.toOwnedSlice();
}

test "Part 1 add 1" {
    try expectEqualStrings("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]", try serializeNumber(try add(try parse("[[[[4,3],4],4],[7,[[8,4],9]]]"), try parse("[1,1]"))));
}

test "Part 1 add 2" {
    try expectEqualStrings("[[[[1,1],[2,2]],[3,3]],[4,4]]", try serializeNumber(try addList(
        \\[1,1]
        \\[2,2]
        \\[3,3]
        \\[4,4]
    )));
    try expectEqualStrings("[[[[3,0],[5,3]],[4,4]],[5,5]]", try serializeNumber(try addList(
        \\[1,1]
        \\[2,2]
        \\[3,3]
        \\[4,4]
        \\[5,5]
    )));
    try expectEqualStrings("[[[[5,0],[7,4]],[5,5]],[6,6]]", try serializeNumber(try addList(
        \\[1,1]
        \\[2,2]
        \\[3,3]
        \\[4,4]
        \\[5,5]
        \\[6,6]
    )));
    try expectEqualStrings("[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]", try serializeNumber(try addList(
        \\[[[0,[4,5]],[0,0]],[[[4,5],[2,6]],[9,5]]]
        \\[7,[[[3,7],[4,3]],[[6,3],[8,8]]]]
        \\[[2,[[0,8],[3,4]]],[[[6,7],1],[7,[1,6]]]]
        \\[[[[2,4],7],[6,[0,5]]],[[[6,8],[2,8]],[[2,1],[4,5]]]]
        \\[7,[5,[[3,8],[1,4]]]]
        \\[[2,[2,2]],[8,[8,1]]]
        \\[2,9]
        \\[1,[[[9,3],9],[[9,0],[0,7]]]]
        \\[[[5,[7,4]],7],1]
        \\[[[[4,2],2],6],[8,7]]
    )));
}

test "Part 1 magnitude" {
    try expectEqual(@as(u64, 143), magnitudeOf(try parse("[[1,2],[[3,4],5]]")));
    try expectEqual(@as(u64, 1384), magnitudeOf(try parse("[[[[0,7],4],[[7,8],[6,0]]],[8,1]]")));
    try expectEqual(@as(u64, 445), magnitudeOf(try parse("[[[[1,1],[2,2]],[3,3]],[4,4]]")));
    try expectEqual(@as(u64, 791), magnitudeOf(try parse("[[[[3,0],[5,3]],[4,4]],[5,5]]")));
    try expectEqual(@as(u64, 1137), magnitudeOf(try parse("[[[[5,0],[7,4]],[5,5]],[6,6]]")));
    try expectEqual(@as(u64, 3488), magnitudeOf(try parse("[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]")));
}

test "Part 1 example" {
    try expectEqual(@as(u64, 4140), try part1(&Parser.init(
        \\[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
        \\[[[5,[2,8]],4],[5,[[9,9],0]]]
        \\[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
        \\[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
        \\[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
        \\[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
        \\[[[[5,4],[7,7]],8],[[8,3],8]]
        \\[[9,3],[[9,9],[6,[4,9]]]]
        \\[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
        \\[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
    )));
}

test "Part 2" {
    try expectEqual(@as(u64, 3993), try part2(&Parser.init(
        \\[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
        \\[[[5,[2,8]],4],[5,[[9,9],0]]]
        \\[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
        \\[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
        \\[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
        \\[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
        \\[[[[5,4],[7,7]],8],[[8,3],8]]
        \\[[9,3],[[9,9],[6,[4,9]]]]
        \\[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
        \\[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
    )));
}
