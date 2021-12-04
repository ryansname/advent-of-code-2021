const std = @import("std");

const mem = std.mem;
const eql = std.mem.eql;

pub const Parser = struct {
    source: []const u8,
    index: usize,

    pub fn init(source: []const u8) Parser {
        return .{
            .source = source,
            .index = 0,
        };
    }

    pub fn skipNewLine(self: *Parser) !void {
        if (self.source[self.index] == ' ') return error.NotAtSpace;
        self.index += 1;
    }

    pub fn takeDelimiter(self: *Parser, needles: []const u8) !u8 {
        const delimiter = self.source[self.index];
        if (mem.indexOfScalar(u8, needles, delimiter) == null) return error.NotAtDelimiter;
        self.index += 1;
        return delimiter;
    }

    pub fn takeUntil(self: *Parser, needles: []const u8) ![]const u8 {
        const start = self.index;
        self.index = mem.indexOfAnyPos(u8, self.source, self.index, needles) orelse self.source.len;
        return self.source[start..self.index];
    }

    pub fn takeType(self: *Parser, comptime T: type, needles: []const u8) !T {
        const result_string = try self.takeUntil(needles);
        switch (@typeInfo(T)) {
            .Int => return std.fmt.parseInt(T, result_string, 10),
            .Float => return try std.fmt.parseFloat(T, result_string),
            else => return error.UnsupportedType,
        }
    }
};

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualStrings = std.testing.expectEqualStrings;
test "parser expect family" {
    var parser = Parser.init(
        \\test,1234
        \\3.1415 ryan was here
        \\
    );

    const delimiter = ",\n";
    try expectEqualSlices(u8, "test", try parser.takeUntil(delimiter));
    try expectEqual(@as(u8, ','), try parser.takeDelimiter(delimiter));
    try expectEqual(@as(u64, 1234), try parser.takeType(u64, delimiter));
    try expectEqual(@as(u8, '\n'), try parser.takeDelimiter(delimiter));
    try expectEqual(@as(f64, 3.1415), try parser.takeType(f64, delimiter ++ " "));
    try expectEqual(@as(u8, ' '), try parser.takeDelimiter(delimiter ++ " "));
    try expectEqualSlices(u8, "ryan was here", try parser.takeUntil(delimiter));
    try parser.skipNewLine();
}
