const std = @import("std");
const zap = @import("zap");

const User = struct {
    first_name: ?[]const u8 = null,
    last_name: ?[]const u8 = null,
};

fn on_request(r: zap.Request) void {
    if (r.methodAsEnum() != .GET) return;

    if (r.path) |path| {
        if (path.len < 7 or !std.mem.startsWith(u8, path, "/user/"))
            return;

        const user_id: usize = @as(usize, @intCast(path[6] - 0x30));
        const user = users.get(user_id);

        var buf: [100]u8 = undefined;
        var json_to_send: []const u8 = undefined;
        if (zap.stringifyBuf(&buf, user, .{})) |json| {
            json_to_send = json;
        } else {
            json_to_send = "null";
        }
        std.debug.print("<< json: {s}\n", .{json_to_send});
        r.setContentType(.JSON) catch return;
        r.setContentTypeFromFilename("test.json") catch return;
        r.sendBody(json_to_send) catch return;
    }
}

const UserMap = std.AutoHashMap(usize, User);

var users: UserMap = undefined;
fn setupUserData(a: std.mem.Allocator) !void {
    users = UserMap.init(a);
    try users.put(1, .{ .first_name = "Foo", .last_name = "Bar" });
    try users.put(2, .{ .first_name = "Baz", .last_name = "Pub" });
}

pub fn main() !void {
    const a = std.heap.page_allocator;
    try setupUserData(a);
    var listener = zap.HttpListener.init(.{
        .port = 8070,
        .on_request = on_request,
        .log = false,
    });
    try listener.listen();

    std.debug.print(
        \\ Listening on 0.0.0.0:3000
        \\
        \\ Check out:
        \\ http://localhost:3000/user/1   # -- first user
        \\ http://localhost:3000/user/2   # -- second user
        \\ http://localhost:3000/user/3   # -- non-existing user
        \\
    , .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 1, // user map cannot be shared among multiple worker processes
    });
}
