const std = @import("std");

const print = std.debug.print;

const zlibrary = @import("zlibrary");

pub fn main() !void {
    print("Example 2: {d} + {d} = {d}\n", .{ 200, 22, zlibrary.add(200, 22) });
}
