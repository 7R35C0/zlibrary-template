const std = @import("std");

const print = std.debug.print;

const zlibrary = @import("zlibrary");

pub fn main() !void {
    print("Example 3: {d} + {d} = {d}\n", .{ 300, 33, zlibrary.add(300, 33) });
}
