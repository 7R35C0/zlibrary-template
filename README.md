## README

A simple zig library template that can be used in development.

Tested with zig version 0.12.0 (0.13.0-dev.351+64ef45eb0) on Linux Fedora 39.

### 📌 About

The template can handle next steps via `zig build` command:

```txt
zlibrary-template$ zig build -l
  install (default)            Copy build artifacts to prefix path
  uninstall                    Remove build artifacts from prefix path
  lib                          Build static library
  tst                          Run all tests
  cov                          Generate code coverage
  doc                          Generate documentation
  fmt                          Format all files
  bms                          Build all benchmarks
  bms-run                      Run <benchmark> with `-Ddirname=<benchmark>` option
  egs                          Build all examples
  egs-run                      Run <example> with `-Ddirname=<example>` option
  rmv                          Remove zig-cache and zig-out directories
  rmv-dir                      Remove <directory> with `-Ddirname=<directory>` option
                               Supported Values: zig-cache, zig-out, bin, bms, cov, doc, egs, lib
```

### 📌 Important

* Step `cov` assumes that [kcov](https://github.com/SimonKagstrom/kcov) is already installed on your operating system

* Use a live http server, like [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) to see the code coverage report (zig-out/cov/index.html) and documentation (zig-out/doc/index.html)

* Steps `bms` and `bms-run` assume that [ztracy](https://github.com/7R35C0/ztracy) or [ztracy-tsc](https://github.com/7R35C0/ztracy-tsc) is a library dependency and is only used in benchmarks

* Use [tracy](https://github.com/wolfpld/tracy) frame profiler for benchmarking

* Steps `bms-run`, `egs-run` and `rmv-dir` assume that the `-Ddirname=<dirname>` option is used

* Step `rmv-dir -Ddirname=<value>` accepts `zig-cache`, `zig-out`, `bin`, `bms`, `cov`, `doc`, `egs` and `lib` values

* Step `rmv` removes the `zig-cache` and `zig-out` directories

### 📌 Final Note

For VS Code users are some useful tasks and debug launchers in `.vscode/tasks.json` and `.vscode/launch.json` files.

There are two main types of tasks, `debug` and `release`, the difference is that the latter uses `-Doptimize=ReleaseFast`.

🔔 Some tasks require a file open and active in the VS Code editor, usually tasks specific to a file, such as "Run example". These tasks will display an error message if they cannot run.

🔔 Note that the main entry point for an `example_name` is `example_name.zig` file (same for benchmarks). This is important to have a proper connection between builds, tasks and launchers.

Debug launchers require [CodeLLDB](https://marketplace.visualstudio.com/items?itemName=vadimcn.vscode-lldb) extension.

Task management can be easily done with [Task Explorer](https://marketplace.visualstudio.com/items?itemName=spmeesseman.vscode-taskexplorer) extension.

That's all about this repo.

All the best!
