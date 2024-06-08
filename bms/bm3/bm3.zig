const std = @import("std");

const zlibrary = @import("zlibrary");
const ztracy = @import("ztracy");

pub fn main() !void {
    // // for build use `-Doptimize=ReleaseFast`
    // const zone_wait = 1_000_000_000;
    // const zone_warm = 1_000;
    // const zone_runs = 1_000;
    // const zone_nums = 1_000_000;

    // zig build by default has `-Doptimize=Debug`, and lower values ​​for benchmarks
    // parameters are recommended, benchmarks may take too long if values ​​are high
    const zone_wait = 0;
    const zone_warm = 10;
    const zone_runs = 100;
    const zone_nums = 3000;

    std.time.sleep(zone_wait);

    for (0..zone_warm) |_| {
        for (0..zone_nums) |num| {
            _ = zlibrary.add(num, num);
        }
    }

    const zone_main = ztracy.ZoneN(@src(), "main");
    defer zone_main.End();

    for (0..zone_runs) |_| {
        const zone_test = ztracy.ZoneN(@src(), "test");
        defer zone_test.End();

        for (0..zone_nums) |num| {
            _ = zlibrary.add(num, num);
        }
    }
}
