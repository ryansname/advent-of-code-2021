const std = @import("std");

const print = std.debug.print;

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;

const fmt = std.fmt;
const mem = std.mem;
const math = std.math;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const alloc = std.heap.page_allocator;

const Parser = @import("lib/parse3.zig").Parser;
const REAL_INPUT = @embedFile("inputs/day16.txt");

pub fn main() !void {
    print("Part 1: {}\n", .{try part1(&Parser.init(REAL_INPUT))});
    print("Part 2: {}\n", .{try part2(&Parser.init(REAL_INPUT))});
}

const PacketType = enum(u8) {
    sum = 0,
    product = 1,
    minimum = 2,
    maximum = 3,
    literal = 4,
    greater = 5,
    less = 6,
    equal = 7,
};

const Packet = struct {
    version: u8,
    packet_type: PacketType,
    encoded_length: u64,
    data: union(enum) {
        literal: u64,
        operator: []Packet,
    },

    fn sumVersionNumbers(self: Packet) u64 {
        var sum: u64 = self.version;

        switch (self.data) {
            .literal => {},
            .operator => |ops| {
                for (ops) |op| sum += op.sumVersionNumbers(); 
            }
        }

        return sum;
    }

    fn evaluate(self: Packet) u64 {
        switch (self.data) {
            .literal => |l| {
                assert(self.packet_type == .literal);
                return l;
            },
            .operator => |operands| {
                var result: u64 = undefined;
                switch (self.packet_type) {
                    .sum => {
                        result = 0;
                        for (operands) |op| result += op.evaluate();
                    },
                    .product => {
                        result = 1;
                        for (operands) |op| result *= op.evaluate();
                    },
                    .minimum => {
                        result = operands[0].evaluate();
                        for (operands[1..]) |op| result = math.min(result, op.evaluate());
                    },
                    .maximum => {
                        result = operands[0].evaluate();
                        for (operands[1..]) |op| result = math.max(result, op.evaluate());    
                    },
                    .literal => unreachable,  // Handled already
                    .greater => {
                        assert(operands.len == 2);
                        result = @boolToInt(operands[0].evaluate() > operands[1].evaluate());
                    },
                    .less => {
                        assert(operands.len == 2);
                        result = @boolToInt(operands[0].evaluate() < operands[1].evaluate());
                    },
                    .equal => {
                        assert(operands.len == 2);
                        result = @boolToInt(operands[0].evaluate() == operands[1].evaluate());
                    },
                }
                return result;
            }
        }
    }
};

const ParsePacketError = error {
    Overflow,
    InvalidCharacter,
    OutOfMemory,
};
fn parse_packet(source: []u8) ParsePacketError!Packet {
    const version = try fmt.parseInt(u8, source[0..3], 2);
    const packet_type = @intToEnum(PacketType, try fmt.parseInt(u8, source[3..6], 2));
    // print("Version = {}\n", .{version});
    // print("Packet Type = {}\n", .{packet_type});

    var index: usize = 6;
    if (packet_type == .literal) {
        var literal_value: u64 = 0;
        while (source[index] == '1') {
            literal_value += try fmt.parseInt(u8, source[index + 1..index + 5], 2);
            literal_value <<= 4;
            index += 5;
        }
        literal_value += try fmt.parseInt(u8, source[index + 1..index + 5], 2);
        index += 5;
        // print("Literal = {}\n", .{literal_value});
        return Packet{
            .version = version,
            .packet_type = packet_type,
            .encoded_length = index,
            .data = .{ .literal = literal_value },
        };
    } else {
        const length_type_id = source[index]; index += 1;
        var operands: []Packet = undefined;
        if (length_type_id == '0') {
            const total_length = try fmt.parseInt(u15, source[index..index + 15], 2); index += 15;

            const index_start: usize = index;
            var operand_list = ArrayList(Packet).init(alloc);
            while (total_length > index - index_start) {
                // print("Parsing subpacket, so far = {}, total = {}\n", .{index - index_start, total_length});
                const new_packet = try operand_list.addOne();
                new_packet.* = try parse_packet(source[index..]);
                index += new_packet.encoded_length;
            }

            operands = operand_list.toOwnedSlice();
        } else {
            const subpacket_count = try fmt.parseInt(u11, source[index..index + 11], 2); index += 11;
            operands = try alloc.alloc(Packet, subpacket_count);

            var idx: usize = 0;
            while (idx < subpacket_count) : (idx += 1) {
                // print("Parsing subpacket, {} of {}\n", .{idx, subpacket_count});
                const new_packet = &operands[idx];
                new_packet.* = try parse_packet(source[index..]);
                index += new_packet.encoded_length;
            }
        }

        return Packet{
            .version = version,
            .packet_type = packet_type,
            .encoded_length = index,
            .data = .{ .operator = operands }
        };
    }
    unreachable;
}

fn part1(input: *Parser) !u64 {
    var input_binary = try BoundedArray(u4, 5000).init(0);
    for (input.source) |c| try input_binary.append(try fmt.parseInt(u4, &[_]u8 {c}, 16));

    var binary = [_]u8 {0} ** (5000 * 4);
    for (input_binary.slice()) |b, i| _ = try fmt.bufPrint(binary[i * 4..], "{b:0>4}", .{b});

    const packet = try parse_packet(&binary);

    return packet.sumVersionNumbers();
}

fn part2(input: *Parser) !u64 {
    var input_binary = try BoundedArray(u4, 5000).init(0);
    for (input.source) |c| try input_binary.append(try fmt.parseInt(u4, &[_]u8 {c}, 16));

    var binary = [_]u8 {0} ** (5000 * 4);
    for (input_binary.slice()) |b, i| _ = try fmt.bufPrint(binary[i * 4..], "{b:0>4}", .{b});

    const packet = try parse_packet(&binary);

    return packet.evaluate();
}

test "Part 1" {
    try expectEqual(@as(u64, 6), try part1(&Parser.init("D2FE28")));
    try expectEqual(@as(u64, 16), try part1(&Parser.init("8A004A801A8002F478")));
    try expectEqual(@as(u64, 12), try part1(&Parser.init("620080001611562C8802118E34")));
    try expectEqual(@as(u64, 23), try part1(&Parser.init("C0015000016115A2E0802F182340")));
    try expectEqual(@as(u64, 31), try part1(&Parser.init("A0016C880162017C3686B18A3D4780")));
}

test "Part 2" {
    try expectEqual(@as(u64, 3), try part2(&Parser.init("C200B40A82")));
    try expectEqual(@as(u64, 54), try part2(&Parser.init("04005AC33890")));
    try expectEqual(@as(u64, 7), try part2(&Parser.init("880086C3E88112")));
    try expectEqual(@as(u64, 9), try part2(&Parser.init("CE00C43D881120")));
    try expectEqual(@as(u64, 1), try part2(&Parser.init("D8005AC2A8F0")));
    try expectEqual(@as(u64, 0), try part2(&Parser.init("F600BC2D8F")));
    try expectEqual(@as(u64, 0), try part2(&Parser.init("9C005AC2F8F0")));
    try expectEqual(@as(u64, 1), try part2(&Parser.init("9C0141080250320F1802104A08")));
}
