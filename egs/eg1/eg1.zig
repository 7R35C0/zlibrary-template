const std = @import("std");

const print = std.debug.print;

const zlibrary = @import("zlibrary");

pub fn main() !void {
    print("Example 1: {d} + {d} = {d}\n", .{ 100, 11, zlibrary.add(100, 11) });
}
