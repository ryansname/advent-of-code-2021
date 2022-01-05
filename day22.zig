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
const BoundedArray = std.BoundedArray;
const HashMap = std.HashMap;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const util = @import("lib/util.zig");
const REAL_INPUT = @embedFile("inputs/day22.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const V3 = struct {
    x: i32,
    y: i32,
    z: i32,
};

const Volume = struct {
    min: V3,
    max: V3,

    fn volume(self: Volume) u64 {
        const l = @intCast(u64, self.max.x - self.min.x) + 1;
        const w = @intCast(u64, self.max.y - self.min.y) + 1;
        const h = @intCast(u64, self.max.z - self.min.z) + 1;
        return l * w * h;
    }

    fn isValid(self: Volume) bool {
        // assertPrint(self.min.x > -100_000, "min.x was {}\n", .{self.min.x});
        // assertPrint(self.min.y > -100_000, "min.y was {}\n", .{self.min.y});
        // assertPrint(self.min.z > -100_000, "min.z was {}\n", .{self.min.z});
        // assertPrint(self.max.x < 100_000, "max.x was {}\n", .{self.max.x});
        // assertPrint(self.max.y < 100_000, "max.y was {}\n", .{self.max.y});
        // assertPrint(self.max.z < 100_000, "max.z was {}\n", .{self.max.z});
        return self.min.x <= self.max.x and self.min.y <= self.max.y and self.min.z <= self.max.z;
    }

    fn intersects(self: Volume, other: Volume) bool {
        return self.min.x <= other.max.x and self.max.x >= other.min.x and
            self.min.y <= other.max.y and self.max.y >= other.min.y and
            self.min.z <= other.max.z and self.max.z >= other.min.z;
    }

    fn totallyContains(self: Volume, other: Volume) bool {
        return self.min.x <= other.min.x and self.max.x >= other.max.x and
            self.min.y <= other.min.y and self.max.y >= other.max.y and
            self.min.z <= other.min.z and self.max.z >= other.max.z;
    }
};

const Instruction = struct {
    vol: Volume,
    state_on: bool,
    order: u32,
};

fn parseInstructions(input: *Parser) !ArrayList(Instruction) {
    var instructions = ArrayList(Instruction).init(alloc);
    errdefer instructions.deinit();

    var line_num: usize = 0;
    while (input.subparse("\n")) |*line| {
        var instruction = try instructions.addOne();
        instruction.state_on = line.source[1] == 'n';

        instruction.order = @intCast(u32, line_num);
        line_num += 1;

        _ = try line.takeType([]const u8, "=");
        instruction.vol.min.x = (try line.takeType(i32, ".")).?;
        _ = try line.takeTypeByCount([]const u8, 1);
        instruction.vol.max.x = (try line.takeType(i32, ",")).?;

        _ = try line.takeType([]const u8, "=");
        instruction.vol.min.y = (try line.takeType(i32, ".")).?;
        _ = try line.takeTypeByCount([]const u8, 1);
        instruction.vol.max.y = (try line.takeType(i32, ",")).?;

        _ = try line.takeType([]const u8, "=");
        instruction.vol.min.z = (try line.takeType(i32, ".")).?;
        _ = try line.takeTypeByCount([]const u8, 1);
        instruction.vol.max.z = (try line.takeType(i32, ",")).?;
    }
    return instructions;
}

fn part1(input: *Parser) !u64 {
    var instructions = try parseInstructions(input);
    defer instructions.deinit();

    const dim: usize = 101;
    var world = [_]bool{false} ** (dim * dim * dim);

    for (instructions.items) |i| {
        var z = @maximum(-50, i.vol.min.z);
        while (z <= @minimum(50, i.vol.max.z)) : (z += 1) {
            const zidx = @intCast(u64, z + 50) * dim * dim;
            var y = @maximum(-50, i.vol.min.y);
            while (y <= @minimum(50, i.vol.max.y)) : (y += 1) {
                const yidx = @intCast(u64, y + 50) * dim;
                var x = @maximum(-50, i.vol.min.x);
                while (x <= @minimum(50, i.vol.max.x)) : (x += 1) {
                    world[@intCast(u64, x + 50) + yidx + zidx] = i.state_on;
                }
            }
        }
    }

    var count: u64 = 0;
    for (world) |on| {
        if (on) {
            count += 1;
        }
    }
    return count;
}

fn part2Slow(input: *Parser) !u64 {
    var instructions = try parseInstructions(input);
    defer instructions.deinit();
    // mem.reverse(Instruction, instructions.items);

    const dim: usize = 200_000;
    const offset: i64 = dim / 2;
    var count: u64 = 0;

    var z: i64 = -offset;
    while (z < offset) : (z += 1) {
        var y: i64 = -offset;
        while (y < offset) : (y += 1) {
            if (@rem(y, 1000) == 0) print("\r z = {}, y = {}", .{ z, y });

            var world = [_]bool{false} ** dim;

            for (instructions.items) |instruction| {
                if (instruction.vol.min.z > z or instruction.vol.max.z < z) continue;
                if (instruction.vol.min.y > y or instruction.vol.max.y < y) continue;

                var slice_min = @intCast(usize, instruction.vol.min.x + offset);
                var slice_max = @intCast(usize, instruction.vol.max.x + offset);

                for (world[slice_min..slice_max]) |*w| {
                    w.* = instruction.state_on;
                }
            }

            for (world) |on| {
                if (on) count += 1;
            }
        }
    }

    return count;
}

fn subtract(lhs: Volume, rhs: Volume) BoundedArray(Volume, 6) {
    var result = BoundedArray(Volume, 6).init(0) catch unreachable;

    if (!lhs.intersects(rhs)) {
        result.appendAssumeCapacity(lhs);
        return result;
    }

    const vol_pos_x = Volume{
        .min = .{
            .x = rhs.max.x + 1,
            .y = lhs.min.y,
            .z = lhs.min.z,
        },
        .max = .{
            .x = lhs.max.x,
            .y = lhs.max.y,
            .z = lhs.max.z,
        },
    };
    if (vol_pos_x.isValid()) result.appendAssumeCapacity(vol_pos_x);
    const vol_neg_x = Volume{
        .min = .{
            .x = lhs.min.x,
            .y = lhs.min.y,
            .z = lhs.min.z,
        },
        .max = .{
            .x = rhs.min.x - 1,
            .y = lhs.max.y,
            .z = lhs.max.z,
        },
    };
    if (vol_neg_x.isValid()) result.appendAssumeCapacity(vol_neg_x);

    const vol_pos_y = Volume{
        .min = .{
            .x = @maximum(lhs.min.x, rhs.min.x),
            .y = rhs.max.y + 1,
            .z = lhs.min.z,
        },
        .max = .{
            .x = @minimum(lhs.max.x, rhs.max.x),
            .y = lhs.max.y,
            .z = lhs.max.z,
        },
    };
    if (vol_pos_y.isValid()) result.appendAssumeCapacity(vol_pos_y);
    const vol_neg_y = Volume{
        .min = .{
            .x = @maximum(lhs.min.x, rhs.min.x),
            .y = lhs.min.y,
            .z = lhs.min.z,
        },
        .max = .{
            .x = @minimum(lhs.max.x, rhs.max.x),
            .y = rhs.min.y - 1,
            .z = lhs.max.z,
        },
    };
    if (vol_neg_y.isValid()) result.appendAssumeCapacity(vol_neg_y);

    const vol_pos_z = Volume{
        .min = .{
            .x = @maximum(lhs.min.x, rhs.min.x),
            .y = @maximum(lhs.min.y, rhs.min.y),
            .z = rhs.max.z + 1,
        },
        .max = .{
            .x = @minimum(lhs.max.x, rhs.max.x),
            .y = @minimum(lhs.max.y, rhs.max.y),
            .z = lhs.max.z,
        },
    };
    if (vol_pos_z.isValid()) result.appendAssumeCapacity(vol_pos_z);
    const vol_neg_z = Volume{
        .min = .{
            .x = @maximum(lhs.min.x, rhs.min.x),
            .y = @maximum(lhs.min.y, rhs.min.y),
            .z = lhs.min.z,
        },
        .max = .{
            .x = @minimum(lhs.max.x, rhs.max.x),
            .y = @minimum(lhs.max.y, rhs.max.y),
            .z = rhs.min.z - 1,
        },
    };
    if (vol_neg_z.isValid()) result.appendAssumeCapacity(vol_neg_z);

    return result;
}

test "subtraction 1" {
    const lhs = Volume{ .min = zero_v3, .max = .{ .x = 2, .y = 2, .z = 2 } };
    const rhs = Volume{ .min = .{ .x = 1, .y = 1, .z = 1 }, .max = .{ .x = 1, .y = 1, .z = 1 } };
    const result = subtract(lhs, rhs).slice();

    // simple sanity check, sum of result vols + rhs == lhs
    var resulting_volume: u64 = rhs.volume();
    for (result) |r| resulting_volume += r.volume();
    // for (result) |r| print("{}\n", .{r});
    try expectEqual(lhs.volume(), resulting_volume);
}

fn subtractAll(lhss: []Volume, rhs: Volume, results: *ArrayList(Volume)) !void {
    for (lhss) |lhs| {
        const still_on_chunks = subtract(lhs, rhs).slice();
        for (still_on_chunks) |r_i| assert(r_i.isValid());
        for (still_on_chunks) |still_on| {
            try results.append(still_on);
        }
    }
}

const zero_v3 = V3{ .x = -0, .y = 0, .z = 0 };
const zero_volume = Volume{ .min = zero_v3, .max = zero_v3 };

fn part2(input: *Parser) !u64 {
    var instructions = try parseInstructions(input);
    defer instructions.deinit();

    // mem.reverse(Instruction, instructions.items);

    var on = ArrayList(Volume).init(alloc);

    next_instruction: for (instructions.items) |i| {
        const was_on = on.toOwnedSlice();
        defer on.allocator.free(was_on);

        if (i.state_on) {
            // First we'll check to see if any existing volumes wholly include i.vol
            for (was_on) |on_vol| {
                if (on_vol.totallyContains(i.vol)) {
                    // print("Existing vol: {} totally contains {}\n", .{ on_vol, i.vol });
                    assert(on.items.len == 0);
                    try on.appendSlice(was_on);
                    continue :next_instruction;
                }
            }

            try on.append(i.vol);
            for (was_on) |on_vol| {
                if (i.vol.totallyContains(on_vol)) {
                    // print("new volume: {} totally contains {}\n", .{ i.vol, on_vol });
                    continue;
                }

                // Goal is to add the entirety of the new volume
                // So from every existing volume, remove the new volume
                const remaining_volumes = subtract(on_vol, i.vol).slice();
                try on.appendSlice(remaining_volumes);
            }
        } else {
            for (was_on) |on_vol| {
                // If we're turning off the whole volume, then we're done
                if (i.vol.totallyContains(on_vol)) continue;

                // If there's no intersection, then preseve the entire volume
                if (!i.vol.intersects(on_vol)) {
                    try on.append(on_vol);
                    continue;
                }

                // Otherwise we simply take the existing volume and remove the instruction's volume
                const remaining_volumes = subtract(on_vol, i.vol).slice();
                try on.appendSlice(remaining_volumes);
            }
        }

        var volume: u64 = 0;
        for (on.items) |vol_on| volume += vol_on.volume();
        // print("{}\t{}\t", .{ i.vol, i.state_on });
        // print("Total on Volumes: {}, total volume: {}\n", .{ on.items.len, volume });
        // if (on.items.len == 4 or on.items.len == 8)
        // print("Volumes: {any}\n", .{on.items});
        // printOnCubes(on.items, .{ .x = 9, .y = 9, .z = 9 }, .{ .x = 13, .y = 13, .z = 13 });

        for (on.items) |vol_a, i_a| {
            for (on.items[i_a + 1 ..]) |vol_b| {
                // print("{}\nvs\n{}\n", .{ vol_a, vol_b });
                assert(!vol_a.intersects(vol_b));
            }
        }
    }

    var count: u64 = 0;
    for (on.items) |vol_on| count += vol_on.volume();

    return count;
}

fn printOnCubes(on_volumes: []Volume, min: V3, max: V3) void {
    var x = min.x;
    while (x <= max.x) : (x += 1) {
        var y = min.y;
        while (y <= max.y) : (y += 1) {
            var z = min.z;
            while (z <= max.z) : (z += 1) {
                const test_v3 = V3{ .x = x, .y = y, .z = z };
                const test_vol = Volume{ .min = test_v3, .max = test_v3 };

                for (on_volumes) |on_vol| {
                    if (on_vol.intersects(test_vol)) {
                        assert(on_vol.totallyContains(test_vol));
                        print("{:3} {:3} {:3}\n", .{ x, y, z });
                        break;
                    } else {
                        assert(!on_vol.totallyContains(test_vol));
                    }
                }
            }
        }
    }
}

test "Part 1" {
    try expectEqual(@as(u64, 39), try part1(&Parser.init(
        \\on x=10..12,y=10..12,z=10..12
        \\on x=11..13,y=11..13,z=11..13
        \\off x=9..11,y=9..11,z=9..11
        \\on x=10..10,y=10..10,z=10..10
    )));

    try expectEqual(@as(u64, 590784), try part1(&Parser.init(
        \\on x=-20..26,y=-36..17,z=-47..7
        \\on x=-20..33,y=-21..23,z=-26..28
        \\on x=-22..28,y=-29..23,z=-38..16
        \\on x=-46..7,y=-6..46,z=-50..-1
        \\on x=-49..1,y=-3..46,z=-24..28
        \\on x=2..47,y=-22..22,z=-23..27
        \\on x=-27..23,y=-28..26,z=-21..29
        \\on x=-39..5,y=-6..47,z=-3..44
        \\on x=-30..21,y=-8..43,z=-13..34
        \\on x=-22..26,y=-27..20,z=-29..19
        \\off x=-48..-32,y=26..41,z=-47..-37
        \\on x=-12..35,y=6..50,z=-50..-2
        \\off x=-48..-32,y=-32..-16,z=-15..-5
        \\on x=-18..26,y=-33..15,z=-7..46
        \\off x=-40..-22,y=-38..-28,z=23..41
        \\on x=-16..35,y=-41..10,z=-47..6
        \\off x=-32..-23,y=11..30,z=-14..3
        \\on x=-49..-5,y=-3..45,z=-29..18
        \\off x=18..30,y=-20..-8,z=-3..13
        \\on x=-41..9,y=-7..43,z=-33..15
        \\on x=-54112..-39298,y=-85059..-49293,z=-27449..7877
        \\on x=967..23432,y=45373..81175,z=27513..53682
    )));
}

test "Part 2 tiny" {
    try expectEqual(@as(u64, 26), try part2(&Parser.init(
        \\on x=10..12,y=10..12,z=10..12
        \\off x=11..11,y=11..11,z=11..11
    )));
}

test "Part 2 small" {
    try expectEqual(@as(u64, 27), try part2(&Parser.init(
        \\on x=10..12,y=10..12,z=10..12
    )));

    try expectEqual(@as(u64, 27 + 19), try part2(&Parser.init(
        \\on x=10..12,y=10..12,z=10..12
        \\on x=11..13,y=11..13,z=11..13
    )));

    try expectEqual(@as(u64, 27 + 19 - 8), try part2(&Parser.init(
        \\on x=10..12,y=10..12,z=10..12
        \\on x=11..13,y=11..13,z=11..13
        \\off x=9..11,y=9..11,z=9..11
    )));

    try expectEqual(@as(u64, 39), try part2(&Parser.init(
        \\on x=10..12,y=10..12,z=10..12
        \\on x=11..13,y=11..13,z=11..13
        \\off x=9..11,y=9..11,z=9..11
        \\on x=10..10,y=10..10,z=10..10
    )));

    try expectEqual(@as(u64, 590784), try part1(&Parser.init(
        \\on x=-20..26,y=-36..17,z=-47..7
        \\on x=-20..33,y=-21..23,z=-26..28
        \\on x=-22..28,y=-29..23,z=-38..16
        \\on x=-46..7,y=-6..46,z=-50..-1
        \\on x=-49..1,y=-3..46,z=-24..28
        \\on x=2..47,y=-22..22,z=-23..27
        \\on x=-27..23,y=-28..26,z=-21..29
        \\on x=-39..5,y=-6..47,z=-3..44
        \\on x=-30..21,y=-8..43,z=-13..34
        \\on x=-22..26,y=-27..20,z=-29..19
        \\off x=-48..-32,y=26..41,z=-47..-37
        \\on x=-12..35,y=6..50,z=-50..-2
        \\off x=-48..-32,y=-32..-16,z=-15..-5
        \\on x=-18..26,y=-33..15,z=-7..46
        \\off x=-40..-22,y=-38..-28,z=23..41
        \\on x=-16..35,y=-41..10,z=-47..6
        \\off x=-32..-23,y=11..30,z=-14..3
        \\on x=-49..-5,y=-3..45,z=-29..18
        \\off x=18..30,y=-20..-8,z=-3..13
        \\on x=-41..9,y=-7..43,z=-33..15
    )));
}

test "Part 2 large" {
    try expectEqual(@as(u64, 2758514936282235), try part2(&Parser.init(
        \\on x=-5..47,y=-31..22,z=-19..33
        \\on x=-44..5,y=-27..21,z=-14..35
        \\on x=-49..-1,y=-11..42,z=-10..38
        \\on x=-20..34,y=-40..6,z=-44..1
        \\off x=26..39,y=40..50,z=-2..11
        \\on x=-41..5,y=-41..6,z=-36..8
        \\off x=-43..-33,y=-45..-28,z=7..25
        \\on x=-33..15,y=-32..19,z=-34..11
        \\off x=35..47,y=-46..-34,z=-11..5
        \\on x=-14..36,y=-6..44,z=-16..29
        \\on x=-57795..-6158,y=29564..72030,z=20435..90618
        \\on x=36731..105352,y=-21140..28532,z=16094..90401
        \\on x=30999..107136,y=-53464..15513,z=8553..71215
        \\on x=13528..83982,y=-99403..-27377,z=-24141..23996
        \\on x=-72682..-12347,y=18159..111354,z=7391..80950
        \\on x=-1060..80757,y=-65301..-20884,z=-103788..-16709
        \\on x=-83015..-9461,y=-72160..-8347,z=-81239..-26856
        \\on x=-52752..22273,y=-49450..9096,z=54442..119054
        \\on x=-29982..40483,y=-108474..-28371,z=-24328..38471
        \\on x=-4958..62750,y=40422..118853,z=-7672..65583
        \\on x=55694..108686,y=-43367..46958,z=-26781..48729
        \\on x=-98497..-18186,y=-63569..3412,z=1232..88485
        \\on x=-726..56291,y=-62629..13224,z=18033..85226
        \\on x=-110886..-34664,y=-81338..-8658,z=8914..63723
        \\on x=-55829..24974,y=-16897..54165,z=-121762..-28058
        \\on x=-65152..-11147,y=22489..91432,z=-58782..1780
        \\on x=-120100..-32970,y=-46592..27473,z=-11695..61039
        \\on x=-18631..37533,y=-124565..-50804,z=-35667..28308
        \\on x=-57817..18248,y=49321..117703,z=5745..55881
        \\on x=14781..98692,y=-1341..70827,z=15753..70151
        \\on x=-34419..55919,y=-19626..40991,z=39015..114138
        \\on x=-60785..11593,y=-56135..2999,z=-95368..-26915
        \\on x=-32178..58085,y=17647..101866,z=-91405..-8878
        \\on x=-53655..12091,y=50097..105568,z=-75335..-4862
        \\on x=-111166..-40997,y=-71714..2688,z=5609..50954
        \\on x=-16602..70118,y=-98693..-44401,z=5197..76897
        \\on x=16383..101554,y=4615..83635,z=-44907..18747
        \\off x=-95822..-15171,y=-19987..48940,z=10804..104439
        \\on x=-89813..-14614,y=16069..88491,z=-3297..45228
        \\on x=41075..99376,y=-20427..49978,z=-52012..13762
        \\on x=-21330..50085,y=-17944..62733,z=-112280..-30197
        \\on x=-16478..35915,y=36008..118594,z=-7885..47086
        \\off x=-98156..-27851,y=-49952..43171,z=-99005..-8456
        \\off x=2032..69770,y=-71013..4824,z=7471..94418
        \\on x=43670..120875,y=-42068..12382,z=-24787..38892
        \\off x=37514..111226,y=-45862..25743,z=-16714..54663
        \\off x=25699..97951,y=-30668..59918,z=-15349..69697
        \\off x=-44271..17935,y=-9516..60759,z=49131..112598
        \\on x=-61695..-5813,y=40978..94975,z=8655..80240
        \\off x=-101086..-9439,y=-7088..67543,z=33935..83858
        \\off x=18020..114017,y=-48931..32606,z=21474..89843
        \\off x=-77139..10506,y=-89994..-18797,z=-80..59318
        \\off x=8476..79288,y=-75520..11602,z=-96624..-24783
        \\on x=-47488..-1262,y=24338..100707,z=16292..72967
        \\off x=-84341..13987,y=2429..92914,z=-90671..-1318
        \\off x=-37810..49457,y=-71013..-7894,z=-105357..-13188
        \\off x=-27365..46395,y=31009..98017,z=15428..76570
        \\off x=-70369..-16548,y=22648..78696,z=-1892..86821
        \\on x=-53470..21291,y=-120233..-33476,z=-44150..38147
        \\off x=-93533..-4276,y=-16170..68771,z=-104985..-24507
    )));
}
