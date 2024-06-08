//
// Important
//
// * Step `cov` assumes that [kcov](https://github.com/SimonKagstrom/kcov) is already installed on your operating system
//
// * Use a live http server, like [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) to see the code coverage report (zig-out/cov/index.html) and documentation (zig-out/doc/index.html)
//
// * Steps `bms` and `bms-run` assume that [ztracy](https://github.com/7R35C0/ztracy) or [ztracy-tsc](https://github.com/7R35C0/ztracy-tsc) is a library dependency and is only used in benchmarks
//
// * Use [tracy](https://github.com/wolfpld/tracy) frame profiler for benchmarking
//
// * Steps `bms-run`, `egs-run` and `rmv-dir` assume that the `-Ddirname=<dirname>` option is used
//
// * Step `rmv-dir -Ddirname=<value>` accepts `zig-cache`, `zig-out`, `bin`, `bms`, `cov`, `doc`, `egs` and `lib` values
//
// * Step `rmv` removes the `zig-cache` and `zig-out` directories
//

const std = @import("std");
const print = std.debug.print;
const padding = " " ** 31;

// general configuration
const Config = struct {
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    root_source_file: std.Build.LazyPath,
    version: std.SemanticVersion,
    benchmarks_root: []const u8,
    examples_root: []const u8,
};

pub fn build(b: *std.Build) void {
    // build configuration
    const cfg = Config{
        .name = "zlibrary",
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        .root_source_file = b.path("src/zlibrary.zig"),
        .version = .{
            .major = 0,
            .minor = 1,
            .patch = 0,
        },
        .benchmarks_root = "bms",
        .examples_root = "egs",
    };

    // Options for this build
    setupOption(b);

    // Expose library module for later use with `@import("cfg.name")`
    const mod = setupModule(b, cfg);

    // Build static library
    // command: zig build lib
    // outputs: zig-out/lib
    const lib = setupStaticLibrary(b, cfg);

    // Run all tests
    // command: zig build tst
    // outputs: none
    const tst = setupTest(b, cfg);

    // Generate code coverage
    // command: zig build cov
    // outputs: zig-out/cov
    setupCoverage(b, tst);

    // Generate documentation
    // command: zig build doc
    // outputs: zig-out/doc
    setupDocumentation(b, lib);

    // Format all files
    // command: zig build fmt
    // outputs: none
    setupFormat(b);

    // Build all benchmarks
    // command: zig build bms
    // outputs: zig-out/bms
    setupBenchmark(b, cfg, mod);

    // Run <benchmark> with `-Ddirname=<benchmark>` option
    // command: zig build bms-run -Ddirname=<benchmark>
    // outputs: zig-out/bms
    setupBenchmarkRun(b, cfg, mod);

    // Build all examples
    // command: zig build egs
    // outputs: zig-out/egs
    setupExample(b, cfg, mod);

    // Run <example> with `-Ddirname=<example>` option
    // command: zig build egs-run -Ddirname=<example>
    // outputs: zig-out/egs
    setupExampleRun(b, cfg, mod);

    // Remove zig-cache and zig-out directories
    // command: zig build rmv
    // outputs: zig-out/none
    setupRemove(b);

    // Remove <directory> with `-Ddirname=<directory>` option
    // Supported Values: zig-cache, zig-out, bin, bms, cov, doc, egs, lib
    // command: zig build rmv-dir -Ddirname=<directory>
    // outputs: zig-out/none
    setupRemoveDir(b);
}

fn setupOption(b: *std.Build) void {
    // this is not a library build option
    const dirname = b.option(
        []const u8,
        "dirname",
        "The directory name for steps `bms-run`, `egs-run`, and `rmv-dir`",
    ) orelse "";

    const options = b.addOptions();
    options.addOption([]const u8, "dirname", dirname);
}

fn setupModule(b: *std.Build, cfg: Config) *std.Build.Module {
    return b.addModule(
        cfg.name,
        .{ .root_source_file = cfg.root_source_file },
    );
}

fn setupStaticLibrary(b: *std.Build, cfg: Config) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = cfg.name,
        .target = cfg.target,
        .optimize = cfg.optimize,
        .root_source_file = cfg.root_source_file,
        .version = cfg.version,
    });
    const lib_install = b.addInstallArtifact(
        lib,
        .{},
    );

    const lib_step = b.step(
        "lib",
        "Build static library",
    );
    lib_step.dependOn(&lib_install.step);

    return lib;
}

fn setupTest(b: *std.Build, cfg: Config) *std.Build.Step.Compile {
    const tst = b.addTest(.{
        .name = cfg.name,
        .target = cfg.target,
        .optimize = cfg.optimize,
        .root_source_file = cfg.root_source_file,
        .version = cfg.version,
    });
    const tst_run = b.addRunArtifact(tst);

    const tst_step = b.step(
        "tst",
        "Run all tests",
    );
    tst_step.dependOn(&tst_run.step);

    return tst;
}

fn setupCoverage(b: *std.Build, tst: *std.Build.Step.Compile) void {
    const cov_cache = b.pathJoin(&[_][]const u8{ b.cache_root.path.?, "cov" });

    const cov_run = b.addSystemCommand(&.{
        "kcov",
        "--clean",
        "--include-pattern=src/",
        cov_cache,
    });
    cov_run.addArtifactArg(tst);

    const cov_install = b.addInstallDirectory(.{
        .install_dir = .{ .custom = "cov" },
        .install_subdir = "",
        .source_dir = .{
            .src_path = .{
                .owner = b,
                .sub_path = ".zig-cache/cov",
            },
        },
    });
    cov_install.step.dependOn(&cov_run.step);

    const cov_cache_remove = b.addRemoveDirTree(cov_cache);
    cov_cache_remove.step.dependOn(&cov_install.step);

    const cov_step = b.step(
        "cov",
        "Generate code coverage",
    );
    cov_step.dependOn(&cov_cache_remove.step);
}

fn setupDocumentation(b: *std.Build, lib: *std.Build.Step.Compile) void {
    const doc_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "doc",
        .source_dir = lib.getEmittedDocs(),
    });

    const doc_step = b.step(
        "doc",
        "Generate documentation",
    );
    doc_step.dependOn(&doc_install.step);
}

fn setupFormat(b: *std.Build) void {
    const fmt = b.addFmt(.{
        .paths = &.{
            "bms",
            "egs",
            "src",
            "build.zig",
            "build.zig.zon",
        },
        .check = false,
    });

    const fmt_step = b.step(
        "fmt",
        "Format all files",
    );
    fmt_step.dependOn(&fmt.step);
}

fn setupBenchmark(b: *std.Build, cfg: Config, mod: *std.Build.Module) void {
    const bms_step = b.step(
        "bms",
        "Build all benchmarks",
    );

    installAllDir(b, cfg, mod, bms_step);
}

fn setupBenchmarkRun(b: *std.Build, cfg: Config, mod: *std.Build.Module) void {
    const bms_step = b.step(
        "bms-run",
        "Run <benchmark> with `-Ddirname=<benchmark>` option",
    );

    if (b.user_input_options.get("dirname")) |dirname| {
        installOneDir(b, cfg, mod, bms_step, dirname.value.scalar);
    }
}

fn setupExample(b: *std.Build, cfg: Config, mod: *std.Build.Module) void {
    const egs_step = b.step(
        "egs",
        "Build all examples",
    );

    installAllDir(b, cfg, mod, egs_step);
}

fn setupExampleRun(b: *std.Build, cfg: Config, mod: *std.Build.Module) void {
    const egs_step = b.step(
        "egs-run",
        "Run <example> with `-Ddirname=<example>` option",
    );

    if (b.user_input_options.get("dirname")) |dirname| {
        installOneDir(b, cfg, mod, egs_step, dirname.value.scalar);
    }
}

fn setupRemove(b: *std.Build) void {
    const rmv_step = b.step(
        "rmv",
        "Remove zig-cache and zig-out directories",
    );

    rmv_step.dependOn(&b.addRemoveDirTree(b.cache_root.path.?).step);
    rmv_step.dependOn(&b.addRemoveDirTree(b.install_path).step);
}

fn setupRemoveDir(b: *std.Build) void {
    const rmv_step = b.step(
        "rmv-dir",
        "Remove <directory> with `-Ddirname=<directory>` option\n" ++ padding ++ "Supported Values: zig-cache, zig-out, bin, bms, cov, doc, egs, lib",
    );

    if (b.user_input_options.get("dirname")) |dirname| {
        const rmv_dir = dirname.value.scalar;

        if (std.ascii.eqlIgnoreCase(rmv_dir, "zig-cache")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.cache_root.path.?).step);
        } else if (std.ascii.eqlIgnoreCase(rmv_dir, "zig-out")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.install_path).step);
        } else if (std.ascii.eqlIgnoreCase(rmv_dir, "bin")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.exe_dir).step);
        } else if (std.ascii.eqlIgnoreCase(rmv_dir, "bms")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.pathJoin(
                &[_][]const u8{ b.install_path, "bms" },
            )).step);
        } else if (std.ascii.eqlIgnoreCase(rmv_dir, "cov")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.pathJoin(
                &[_][]const u8{ b.install_path, "cov" },
            )).step);
        } else if (std.ascii.eqlIgnoreCase(rmv_dir, "doc")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.pathJoin(
                &[_][]const u8{ b.install_path, "doc" },
            )).step);
        } else if (std.ascii.eqlIgnoreCase(rmv_dir, "egs")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.pathJoin(
                &[_][]const u8{ b.install_path, "egs" },
            )).step);
        } else if (std.ascii.eqlIgnoreCase(rmv_dir, "lib")) {
            rmv_step.dependOn(&b.addRemoveDirTree(b.lib_dir).step);
        }
    }
}

fn installOneDir(
    b: *std.Build,
    cfg: Config,
    mod: *std.Build.Module,
    step: *std.Build.Step,
    dir_name: []const u8,
) void {
    const dir_root = if (std.ascii.eqlIgnoreCase(step.name, "bms") or std.ascii.eqlIgnoreCase(step.name, "bms-run")) cfg.benchmarks_root else cfg.examples_root;

    const src_path = std.fs.path.resolve(
        b.allocator,
        &[_][]const u8{ dir_root, dir_name, b.fmt("{s}.zig", .{dir_name}) },
    ) catch |err| {
        print("{s}: {!}\n", .{ cfg.name, err });
        return;
    };

    const exe = b.addExecutable(.{
        .name = dir_name,
        .target = cfg.target,
        .optimize = cfg.optimize,
        .root_source_file = .{
            .src_path = .{
                .owner = b,
                .sub_path = src_path,
            },
        },
        .version = cfg.version,
    });

    if (std.ascii.eqlIgnoreCase(step.name, "bms") or std.ascii.eqlIgnoreCase(step.name, "bms-run")) {
        const ztracy = b.dependency("ztracy", .{
            .enable_ztracy = true,
            .enable_fibers = true,
        });
        exe.root_module.addImport("ztracy", ztracy.module("root"));
        exe.linkLibrary(ztracy.artifact("tracy"));
    }

    exe.root_module.addImport(cfg.name, mod);

    const install = b.addInstallArtifact(
        exe,
        .{
            .dest_dir = .{
                .override = .{
                    .custom = dir_root,
                },
            },
        },
    );

    if (std.ascii.eqlIgnoreCase(step.name, "bms") or std.ascii.eqlIgnoreCase(step.name, "egs")) step.dependOn(&install.step) else {
        const run = b.addRunArtifact(exe);
        run.step.dependOn(&install.step);
        step.dependOn(&run.step);
    }
}

fn installAllDir(
    b: *std.Build,
    cfg: Config,
    mod: *std.Build.Module,
    step: *std.Build.Step,
) void {
    const dir_root = if (std.ascii.eqlIgnoreCase(step.name, "bms")) cfg.benchmarks_root else cfg.examples_root;

    var dir = std.fs.openDirAbsolute(
        b.path(dir_root).getPath(b),
        .{ .iterate = true },
    ) catch |err| {
        print("{s}: {!}\n", .{ cfg.name, err });
        return;
    };
    defer dir.close();

    var walker = dir.walk(b.allocator) catch |err| {
        print("{s}: {!}\n", .{ cfg.name, err });
        return;
    };
    defer walker.deinit();

    while (walker.next() catch |err| {
        print("{s}: {!}\n", .{ cfg.name, err });
        return;
    }) |entry| {
        if (entry.kind == .directory) {
            installOneDir(b, cfg, mod, step, entry.basename);
        }
    }
}
