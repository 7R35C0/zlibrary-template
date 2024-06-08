//!
//! Tested only with zig version 0.12.0 (0.13.0-dev.351+64ef45eb0) on Linux Fedora 39.
//!

const std = @import("std");
const testing = std.testing;

pub fn add(a: u64, b: u64) u64 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
