const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const math = std.math;
const sort = std.sort;

const assertPrint = util.assertPrint;
const dbg = util.dbg;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const HashMap = std.HashMap;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const util = @import("lib/util.zig");
const REAL_INPUT = @embedFile("inputs/day19.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const V3Set = HashMap(V3, void, V3MapContext, 75);
const V3MapContext = struct {
    pub fn hash(_: V3MapContext, v3: V3) u64 {
        var result: u64 = 0;
        result ^= @bitCast(u64, v3.x * 37);
        result ^= @bitCast(u64, v3.y * 37);
        result ^= @bitCast(u64, v3.z * 37);
        return result;
    }

    pub fn eql(_: V3MapContext, a: V3, b: V3) bool {
        return a.x == b.x and a.y == b.y and a.z == b.z;
    }
};

const V3 = struct {
    x: i64,
    y: i64,
    z: i64,

    fn plus(self: V3, other: V3) V3 {
        return .{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    fn minus(self: V3, other: V3) V3 {
        return .{
            .x = self.x - other.x,
            .y = self.y - other.y,
            .z = self.z - other.z,
        };
    }
};

const Scanner = struct {
    id: u32,
    beacons: []V3,

    has_offset: bool = false,
    offset: V3 = undefined,

    fn init(id: u32, buffer: *ArrayList(V3)) Scanner {
        return .{
            .id = id,
            .beacons = buffer.toOwnedSlice(),
        };
    }

    fn deinit(self: Scanner) void {
        alloc.free(self.beacons);
    }
};

fn parseInput(input: *Parser) ![]Scanner {
    var result = ArrayList(Scanner).init(alloc);
    errdefer {
        for (result.items) |r| r.deinit();
        result.deinit();
    }

    var scanner_id: u32 = 0;
    var beacons = ArrayList(V3).init(alloc);
    while (input.subparse("\n")) |*line| {
        if (line.source.len == 0) {
            (try result.addOne()).* = Scanner.init(scanner_id, &beacons);
            assert(beacons.items.len == 0);
            scanner_id += 1;
        } else if (line.source[1] == '-') {
            continue;
        } else {
            const x = (try line.takeType(i64, ",")).?;
            const y = (try line.takeType(i64, ",")).?;
            const z = (try line.takeType(i64, "\n")).?;
            (try beacons.addOne()).* = .{
                .x = x,
                .y = y,
                .z = z,
            };
        }
    }
    (try result.addOne()).* = Scanner.init(scanner_id, &beacons);

    return result.toOwnedSlice();
}

fn length_cubed_between(a: V3, b: V3) u64 {
    const x = b.x - a.x;
    const y = b.y - a.y;
    const z = b.z - a.z;
    return @intCast(u64, x * x) + @intCast(u64, y * y) + @intCast(u64, z * z);
}

fn calculateAllDistances(point: V3, scanner: Scanner) BoundedArray(u64, 64) {
    var lengths = BoundedArray(u64, 64).init(0) catch unreachable;
    var seen_zero = false;
    for (scanner.beacons) |beacon| {
        const distance = length_cubed_between(point, beacon);
        if (distance == 0) {
            assert(!seen_zero);
            seen_zero = true;
            continue;
        }

        lengths.append(distance) catch unreachable;
    }

    const slice = lengths.slice();
    sort.sort(u64, slice, {}, comptime sort.asc(u64));
    for (slice) |len, idx| {
        if (idx == 0) continue;
        assert(len != slice[idx - 1]);
    }

    return lengths;
}

fn likelyOffset(comptime min_matches: usize, scanner_a: Scanner, scanner_b: Scanner) ?u64 {
    for (scanner_a.beacons) |a_b| {
        const lengths_a = calculateAllDistances(a_b, scanner_a).slice();

        for (scanner_b.beacons) |b_b| {
            const lengths_b = calculateAllDistances(b_b, scanner_b).slice();

            var matches: u64 = 1; // The "zero" beacon is assumed to be matching a_b == b_b
            var a_idx: usize = 0;
            var b_idx = a_idx;
            while (a_idx < lengths_a.len and b_idx < lengths_b.len) {
                const len_a = lengths_a[a_idx];
                const len_b = lengths_b[b_idx];
                if (len_a == len_b) {
                    matches += 1;
                    a_idx += 1;
                    b_idx += 1;
                } else if (len_a < len_b) {
                    a_idx += 1;
                } else {
                    b_idx += 1;
                }
            }

            if (matches >= min_matches) {
                // print("{} vs {} = {}\n", .{ scanner_a.id, scanner_b.id, matches });
                return matches;
            }
        }
    }

    return null;
}

fn part1(input: *Parser) !u64 {
    var scanners = try parseInput(input);
    defer {
        for (scanners) |r| r.deinit();
        alloc.free(scanners);
    }

    scanners[0].has_offset = true;
    scanners[0].offset = mem.zeroes(V3);

    var to_match: usize = scanners.len - 1;
    while (to_match > 0) {
        for (scanners) |scanner_a| {
            if (!scanner_a.has_offset) continue;

            for (scanners) |*scanner_b| {
                if (scanner_b.has_offset) continue;
                if (scanner_a.id == scanner_b.id) continue;

                const found_match = tryAndFindMatchingBeacons(12, scanner_a, scanner_b);
                if (found_match) to_match -= 1;
            }
        }
    }
    for (scanners) |s| assert(s.has_offset);

    var point_set = V3Set.init(alloc);
    for (scanners) |scanner| {
        // print("{}\n", .{scanner.offset});
        for (scanner.beacons) |beacon| {
            try point_set.put(beacon.plus(scanner.offset), {});
        }
    }
    return point_set.count();
    // return beacons;
    // 366 high
    // 282 low
}

fn tryAndFindMatchingBeacons(comptime matches: usize, scanner_a: Scanner, scanner_b: *Scanner) bool {
    if (likelyOffset(matches, scanner_a, scanner_b.*) == null) return false;

    var rot1: usize = 0;
    while (rot1 < 4) : (rot1 += 1) {
        var rot2: usize = 0;
        while (rot2 < 4) : (rot2 += 1) {
            var rot3: usize = 0;
            while (rot3 < 4) : (rot3 += 1) {
                if (findOffset(matches, scanner_a, scanner_b.*)) |offset| {
                    // print("Found good offset and rotation\n", .{});
                    scanner_b.offset = scanner_a.offset.plus(offset);
                    scanner_b.has_offset = true;
                    return true;
                }

                rotate3(scanner_b.beacons);
            }
            rotate2(scanner_b.beacons);
        }
        rotate1(scanner_b.beacons);
    }

    // print("Did not find good offset\n", .{});
    return false;
}

fn findOffset(comptime matches: usize, scanner_a: Scanner, scanner_b: Scanner) ?V3 {
    for (scanner_a.beacons) |a_b| {
        for (scanner_b.beacons) |b_b| {
            var potential_offset = a_b.minus(b_b);
            assert(meta.eql(b_b.plus(potential_offset), a_b));

            const count_aligned = countAligned(scanner_a.beacons, scanner_b.beacons, potential_offset);
            if (count_aligned >= matches) return potential_offset;
        }
    }

    return null;
}

fn countAligned(fixed: []V3, to_align: []V3, offset: V3) u64 {
    var count_aligned: u64 = 0;

    // We have to check every pair of (A, B) to see which match up the 12 beacons
    // There should be 12 pairs of (A, B) which do this
    for (fixed) |a| {
        for (to_align) |b| {
            const aligned = b.plus(offset);
            if (meta.eql(a, aligned)) {
                count_aligned += 1;
                break;
            }
        }
    }

    assert(count_aligned > 0); // We purposefully aligned one set of points to get the offset.
    return count_aligned;
}

/// Rotates 90 degrees in place along z axis
fn rotate1(points: []V3) void {
    for (points) |*p| {
        const b = p.*;
        p.x = -b.y;
        p.y = b.x;
    }
}

/// Rotates 90 degrees around y axis
fn rotate2(points: []V3) void {
    for (points) |*p| {
        const b = p.*;
        p.x = -b.z;
        p.z = b.x;
    }
}

/// Rotates 90 degrees around x axis
fn rotate3(points: []V3) void {
    for (points) |*p| {
        const b = p.*;
        p.y = -b.z;
        p.z = b.y;
    }
}

fn part2(input: *Parser) !u64 {
    var scanners = try parseInput(input);
    defer {
        for (scanners) |r| r.deinit();
        alloc.free(scanners);
    }

    scanners[0].has_offset = true;
    scanners[0].offset = mem.zeroes(V3);

    var to_match: usize = scanners.len - 1;
    while (to_match > 0) {
        for (scanners) |scanner_a| {
            if (!scanner_a.has_offset) continue;

            for (scanners) |*scanner_b| {
                if (scanner_b.has_offset) continue;
                if (scanner_a.id == scanner_b.id) continue;

                const found_match = tryAndFindMatchingBeacons(12, scanner_a, scanner_b);
                if (found_match) to_match -= 1;
            }
        }
    }
    for (scanners) |s| assert(s.has_offset);

    var largest_distance: i64 = 0;
    for (scanners) |scanner_a| {
        for (scanners) |scanner_b| {
            var this_distance: i64 = 0;
            this_distance += try math.absInt(scanner_a.offset.x - scanner_b.offset.x);
            this_distance += try math.absInt(scanner_a.offset.y - scanner_b.offset.y);
            this_distance += try math.absInt(scanner_a.offset.z - scanner_b.offset.z);

            largest_distance = @maximum(largest_distance, this_distance);
        }
    }
    return @intCast(u64, largest_distance);
}

test "Part 1" {
    try expectEqual(@as(u64, 79), try part1(&Parser.init(
        \\--- scanner 0 ---
        \\404,-588,-901
        \\528,-643,409
        \\-838,591,734
        \\390,-675,-793
        \\-537,-823,-458
        \\-485,-357,347
        \\-345,-311,381
        \\-661,-816,-575
        \\-876,649,763
        \\-618,-824,-621
        \\553,345,-567
        \\474,580,667
        \\-447,-329,318
        \\-584,868,-557
        \\544,-627,-890
        \\564,392,-477
        \\455,729,728
        \\-892,524,684
        \\-689,845,-530
        \\423,-701,434
        \\7,-33,-71
        \\630,319,-379
        \\443,580,662
        \\-789,900,-551
        \\459,-707,401
        \\
        \\--- scanner 1 ---
        \\686,422,578
        \\605,423,415
        \\515,917,-361
        \\-336,658,858
        \\95,138,22
        \\-476,619,847
        \\-340,-569,-846
        \\567,-361,727
        \\-460,603,-452
        \\669,-402,600
        \\729,430,532
        \\-500,-761,534
        \\-322,571,750
        \\-466,-666,-811
        \\-429,-592,574
        \\-355,545,-477
        \\703,-491,-529
        \\-328,-685,520
        \\413,935,-424
        \\-391,539,-444
        \\586,-435,557
        \\-364,-763,-893
        \\807,-499,-711
        \\755,-354,-619
        \\553,889,-390
        \\
        \\--- scanner 2 ---
        \\649,640,665
        \\682,-795,504
        \\-784,533,-524
        \\-644,584,-595
        \\-588,-843,648
        \\-30,6,44
        \\-674,560,763
        \\500,723,-460
        \\609,671,-379
        \\-555,-800,653
        \\-675,-892,-343
        \\697,-426,-610
        \\578,704,681
        \\493,664,-388
        \\-671,-858,530
        \\-667,343,800
        \\571,-461,-707
        \\-138,-166,112
        \\-889,563,-600
        \\646,-828,498
        \\640,759,510
        \\-630,509,768
        \\-681,-892,-333
        \\673,-379,-804
        \\-742,-814,-386
        \\577,-820,562
        \\
        \\--- scanner 3 ---
        \\-589,542,597
        \\605,-692,669
        \\-500,565,-823
        \\-660,373,557
        \\-458,-679,-417
        \\-488,449,543
        \\-626,468,-788
        \\338,-750,-386
        \\528,-832,-391
        \\562,-778,733
        \\-938,-730,414
        \\543,643,-506
        \\-524,371,-870
        \\407,773,750
        \\-104,29,83
        \\378,-903,-323
        \\-778,-728,485
        \\426,699,580
        \\-438,-605,-362
        \\-469,-447,-387
        \\509,732,623
        \\647,635,-688
        \\-868,-804,481
        \\614,-800,639
        \\595,780,-596
        \\
        \\--- scanner 4 ---
        \\727,592,562
        \\-293,-554,779
        \\441,611,-461
        \\-714,465,-776
        \\-743,427,-804
        \\-660,-479,-426
        \\832,-632,460
        \\927,-485,-438
        \\408,393,-506
        \\466,436,-512
        \\110,16,151
        \\-258,-428,682
        \\-393,719,612
        \\-211,-452,876
        \\808,-476,-593
        \\-575,615,604
        \\-485,667,467
        \\-680,325,-822
        \\-627,-443,-432
        \\872,-547,-609
        \\833,512,582
        \\807,604,487
        \\839,-516,451
        \\891,-625,532
        \\-652,-548,-490
        \\30,-46,-14
    )));
}

test "Part 2" {
    try expectEqual(@as(u64, 3621), try part2(&Parser.init(
        \\--- scanner 0 ---
        \\404,-588,-901
        \\528,-643,409
        \\-838,591,734
        \\390,-675,-793
        \\-537,-823,-458
        \\-485,-357,347
        \\-345,-311,381
        \\-661,-816,-575
        \\-876,649,763
        \\-618,-824,-621
        \\553,345,-567
        \\474,580,667
        \\-447,-329,318
        \\-584,868,-557
        \\544,-627,-890
        \\564,392,-477
        \\455,729,728
        \\-892,524,684
        \\-689,845,-530
        \\423,-701,434
        \\7,-33,-71
        \\630,319,-379
        \\443,580,662
        \\-789,900,-551
        \\459,-707,401
        \\
        \\--- scanner 1 ---
        \\686,422,578
        \\605,423,415
        \\515,917,-361
        \\-336,658,858
        \\95,138,22
        \\-476,619,847
        \\-340,-569,-846
        \\567,-361,727
        \\-460,603,-452
        \\669,-402,600
        \\729,430,532
        \\-500,-761,534
        \\-322,571,750
        \\-466,-666,-811
        \\-429,-592,574
        \\-355,545,-477
        \\703,-491,-529
        \\-328,-685,520
        \\413,935,-424
        \\-391,539,-444
        \\586,-435,557
        \\-364,-763,-893
        \\807,-499,-711
        \\755,-354,-619
        \\553,889,-390
        \\
        \\--- scanner 2 ---
        \\649,640,665
        \\682,-795,504
        \\-784,533,-524
        \\-644,584,-595
        \\-588,-843,648
        \\-30,6,44
        \\-674,560,763
        \\500,723,-460
        \\609,671,-379
        \\-555,-800,653
        \\-675,-892,-343
        \\697,-426,-610
        \\578,704,681
        \\493,664,-388
        \\-671,-858,530
        \\-667,343,800
        \\571,-461,-707
        \\-138,-166,112
        \\-889,563,-600
        \\646,-828,498
        \\640,759,510
        \\-630,509,768
        \\-681,-892,-333
        \\673,-379,-804
        \\-742,-814,-386
        \\577,-820,562
        \\
        \\--- scanner 3 ---
        \\-589,542,597
        \\605,-692,669
        \\-500,565,-823
        \\-660,373,557
        \\-458,-679,-417
        \\-488,449,543
        \\-626,468,-788
        \\338,-750,-386
        \\528,-832,-391
        \\562,-778,733
        \\-938,-730,414
        \\543,643,-506
        \\-524,371,-870
        \\407,773,750
        \\-104,29,83
        \\378,-903,-323
        \\-778,-728,485
        \\426,699,580
        \\-438,-605,-362
        \\-469,-447,-387
        \\509,732,623
        \\647,635,-688
        \\-868,-804,481
        \\614,-800,639
        \\595,780,-596
        \\
        \\--- scanner 4 ---
        \\727,592,562
        \\-293,-554,779
        \\441,611,-461
        \\-714,465,-776
        \\-743,427,-804
        \\-660,-479,-426
        \\832,-632,460
        \\927,-485,-438
        \\408,393,-506
        \\466,436,-512
        \\110,16,151
        \\-258,-428,682
        \\-393,719,612
        \\-211,-452,876
        \\808,-476,-593
        \\-575,615,604
        \\-485,667,467
        \\-680,325,-822
        \\-627,-443,-432
        \\872,-547,-609
        \\833,512,582
        \\807,604,487
        \\839,-516,451
        \\891,-625,532
        \\-652,-548,-490
        \\30,-46,-14
    )));
}
