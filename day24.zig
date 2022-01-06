const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const assertPrint = util.assertPrint;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const math = std.math;

const ArrayList = std.ArrayList;
const BufSet = std.BufSet;
const BoundedArray = std.BoundedArray;
const HashMap = std.HashMap;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const util = @import("lib/util.zig");
const REAL_INPUT = @embedFile("inputs/day24.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1()});
    print("Part 2: {}\n", .{try part2()});
}
fn part1() !u64 {
    // By inspection, last two digits are n, n-1, the highest of these in 98
    // var seen_digits = BufSet.init(alloc);
    // defer seen_digits.deinit();

    const known_suffix = [_]u8{ 9, 2, 9, 9, 4, 9, 9, 4, 9, 9, 8 };
    var buffer = [_]u8{1} ** (14 - known_suffix.len) ++ known_suffix;
    assert(buffer.len == 14);
    var best_result: u64 = 0;
    outer: while (true) {
        print("\r{any}", .{buffer});
        const buffer_u64 = squishArrayTou64(&buffer);
        if (buffer_u64 < best_result) {
            buffer = unsquashToBuffer(best_result);
            continue;
        }

        const result = try reduceNumberWithMonad(buffer, best_result, lessThan);
        if (result) |r| {
            if (best_result < r) {
                print("\r{s}", .{" " ** 50});
                print("\rNew best 0: {}\n", .{r});
                best_result = r;
                // seen_digits.deinit();
                // seen_digits = BufSet.init(alloc);
            }
        }

        var pos: usize = known_suffix.len;
        while (pos < buffer.len) : (pos += 1) {
            var idx = buffer.len - pos - 1;
            buffer[idx] += 1;
            if (buffer[idx] < 10) break;
            buffer[idx] = 1;
        } else {
            break :outer;
        }
    }

    print("\r" ++ " " ** 100 ++ "\r", .{});
    return best_result;
}

fn reduceNumberWithMonad(number: [14]u8, best_result_so_far: u64, comptime rhsBestFn: fn (u64, u64) bool) !?u64 {
    var input = number;

    var min_input = input;
    var min_value = runMonad(squishArrayTou64(&input)).?[3];
    new_test: while (min_value != 0) {
        var i_raw: usize = 0;
        while (i_raw < input.len) : (i_raw += 1) {
            var replacement: u8 = 1;
            var idx = i_raw;
            const original = input[idx];
            while (replacement < 10) : (replacement += 1) {
                input[idx] = replacement;

                const input_u64 = squishArrayTou64(&input);

                if (rhsBestFn(input_u64, best_result_so_far)) continue;

                const new_result = runMonad(input_u64) orelse continue;

                if (new_result[3] < min_value) {
                    min_input = input;
                    min_value = new_result[3];
                    continue :new_test;
                }
            }
            input[idx] = original;
        }

        return null;
    }

    return squishArrayTou64(&min_input);
}

fn squishArrayTou64(array: []u8) u64 {
    var result: u64 = 0;
    for (array) |val, i| {
        result += val * math.pow(u64, 10, array.len - i - 1);
    }
    return result;
}

fn unsquashToBuffer(number: u64) [14]u8 {
    assert(number < 100000000000000);
    var remaining = number;
    var result = [_]u8{0} ** 14;
    var idx = result.len;

    while (remaining != 0) {
        idx -= 1;
        result[idx] = @intCast(u8, @rem(remaining, 10));
        remaining -= result[idx];
        remaining /= 10;
    }

    return result;
}

test "Buffer round trip" {
    const input: u64 = 123456789;
    try expectEqual(input, squishArrayTou64(&unsquashToBuffer(input)));
}

fn lessThan(lhs: u64, rhs: u64) bool {
    return lhs < rhs;
}

fn greaterThan(lhs: u64, rhs: u64) bool {
    return lhs > rhs;
}

fn part2() !u64 {
    // By inspection, last two digits are n, n-1, the lowest of these in 21
    // var seen_digits = BufSet.init(alloc);
    // defer seen_digits.deinit();

    const known_suffix = [_]u8{ 1, 6, 1, 8, 1, 1, 1, 1, 6, 4, 1, 5, 2, 1 };
    var buffer = [_]u8{1} ** (14 - known_suffix.len) ++ known_suffix;
    assert(buffer.len == 14);
    var best_result_so_far: u64 = math.maxInt(u64);
    const result = outer: while (true) {
        print("\r{any}", .{buffer});
        const buffer_u64 = squishArrayTou64(&buffer);
        if (runMonad(buffer_u64)) |result_array| {
            if (result_array[3] == 0) break :outer buffer_u64;
        }

        const possible_result = try reduceNumberWithMonad(buffer, best_result_so_far, greaterThan);
        if (possible_result) |pr| {
            if (pr < best_result_so_far) {
                print("\r{s}", .{" " ** 50});
                print("\rPossible result from {}\n", .{pr});
                best_result_so_far = pr;
            }
        }

        var pos: usize = known_suffix.len;
        while (pos < buffer.len) : (pos += 1) {
            var idx = buffer.len - pos - 1;
            buffer[idx] += 1;
            if (buffer[idx] < 10) break;
            buffer[idx] = 1;
        } else {
            break :outer;
        }
    } else unreachable;

    print("\r" ++ " " ** 100 ++ "\r", .{});
    return result;
}

const Instruction = enum {
    inp,
    add,
    mul,
    div,
    mod,
    eql,
};

const Arg2 = union(enum) {
    imm: i64,
    reg: *i64,

    fn value(self: Arg2) i64 {
        return switch (self) {
            .imm => self.imm,
            .reg => self.reg.*,
        };
    }
};

fn runMonad(input: u64) ?[4]i64 {
    assert(input < 100000000000000);
    var buffer: [14]u8 = undefined;
    _ = fmt.bufPrint(&buffer, "{:0>14}", .{input}) catch unreachable;
    for (buffer) |*b| b.* -= '0';
    for (buffer) |b| {
        if (b == 0) return null;
    }

    const machine_out = simulateMachine(REAL_INPUT, &buffer);

    return machine_out;
}

fn simulateMachine(comptime program: []const u8, input: []const u8) [4]i64 {
    var result = [_]i64{0} ** 4;
    var val_2: ?i64 = undefined;

    comptime {
        @setEvalBranchQuota(100000);
        var next_input_index: usize = 0;
        var program_lines = mem.split(u8, program, "\n");
        inline while (program_lines.next()) |line| {
            const instruction = meta.stringToEnum(Instruction, line[0..3]).?;
            const reg_1 = line[4] - 'w';
            val_2 = if (line.len <= 5) null else if (line[6] >= 'w') result[line[6] - 'w'] else try fmt.parseInt(i64, line[6..], 10);

            switch (instruction) {
                .inp => {
                    result[reg_1] = input[next_input_index];
                    next_input_index += 1;
                },
                .add => result[reg_1] += val_2.?,
                .mul => result[reg_1] *= val_2.?,
                .div => result[reg_1] = @divTrunc(result[reg_1], val_2.?),
                .mod => result[reg_1] = @mod(result[reg_1], val_2.?),
                .eql => result[reg_1] = @boolToInt(result[reg_1] == val_2.?),
            }
        }
    }

    return result;
}

test "Part 1" {
    try expectEqual([4]i64{ 0, -4, 0, 0 }, simulateMachine(
        \\inp x
        \\mul x -1
    , &[_]u8{4}));

    const program_2 =
        \\inp z
        \\inp x
        \\mul z 3
        \\eql z x
    ;
    try expectEqual([4]i64{ 0, 3, 0, 1 }, simulateMachine(program_2, &[_]u8{ 1, 3 }));
    try expectEqual([4]i64{ 0, 4, 0, 0 }, simulateMachine(program_2, &[_]u8{ 1, 4 }));
    try expectEqual([4]i64{ 0, 3, 0, 0 }, simulateMachine(program_2, &[_]u8{ 2, 3 }));
    try expectEqual([4]i64{ 0, 6, 0, 1 }, simulateMachine(program_2, &[_]u8{ 2, 6 }));

    const to_binary_program =
        \\inp w
        \\add z w
        \\mod z 2
        \\div w 2
        \\add y w
        \\mod y 2
        \\div w 2
        \\add x w
        \\mod x 2
        \\div w 2
        \\mod w 2
    ;
    try expectEqual([4]i64{ 1, 1, 1, 1 }, simulateMachine(to_binary_program, &[_]u8{15}));
    try expectEqual([4]i64{ 1, 1, 1, 0 }, simulateMachine(to_binary_program, &[_]u8{14}));
    try expectEqual([4]i64{ 1, 1, 0, 1 }, simulateMachine(to_binary_program, &[_]u8{13}));
    try expectEqual([4]i64{ 1, 0, 1, 1 }, simulateMachine(to_binary_program, &[_]u8{11}));
    try expectEqual([4]i64{ 0, 1, 1, 1 }, simulateMachine(to_binary_program, &[_]u8{7}));
    try expectEqual([4]i64{ 0, 0, 1, 1 }, simulateMachine(to_binary_program, &[_]u8{3}));
    try expectEqual([4]i64{ 0, 0, 0, 1 }, simulateMachine(to_binary_program, &[_]u8{1}));
}

test "Part 2" {}
