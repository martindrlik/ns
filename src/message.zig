const std = @import("std");
const Allocator = std.mem.Allocator;
const ParseError = std.json.ParseError;
const Parsed = std.json.Parsed;
const Scanner = std.json.Scanner;
const eql = std.mem.eql;
const expect = std.testing.expect;

const Payload = struct { message: Message };
const Message = struct { data: Data };
const Data = struct {
    constant_delay: []u8,
    message: []u8,
    title: []u8,
};

pub fn parsePayload(s: []const u8) ParseError(Scanner)!Parsed(Payload) {
    var buffer: [2000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    return try std.json.parseFromSlice(Payload, allocator, s, .{ .ignore_unknown_fields = true });
}

test "parse payload" {
    const parsed = try parsePayload(
        \\{
        \\  "message": {
        \\      "data": {
        \\          "checksum": "994496331",
        \\          "constant_delay": "100ms",
        \\          "message": "A longer message.",
        \\          "notificationToken": "47947c2d-ef31-4081-8346-3d4081cdfe960",
        \\          "title": "Hello"
        \\      }
        \\  },
        \\  "android": { "ttl": "2419200s" }
        \\}
    );
    defer parsed.deinit();

    const payload = parsed.value;

    try expect(eql(u8, payload.message.data.constant_delay, "100ms"));
    try expect(eql(u8, payload.message.data.title, "Hello"));
}
