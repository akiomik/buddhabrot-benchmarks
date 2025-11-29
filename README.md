# buddhabrot-benchmarks

Buddhabrot fractal implementations in Odin, Roc, Rust, and Zig with benchmarking.

## Benchmark Results

### System Information

- Machine: Apple M1 Max
- OS: macOS Tahoe 26.1
- Memory: 64GB

### Language Versions

- Odin `dev-2025-11:e5153a937` with `-o:speed`
- Roc `d73ea109cc2 on Tue Sep 9 10:23:53 UTC 2025` with `--optimize`
- Rust `1.91.1 (ed61e7d7e 2025-11-07)` with `--profile release`
- Zig `0.15.2` with `--release=fast`

### Results (1000×1000px, 1M samples)

| Command | Mean [ms]    | Min [ms] | Max [ms] | Relative    |
|:--------|-------------:|---------:|---------:|------------:|
| `Odin`  | 684.3 ± 13.9 | 674.1    | 700.2    | 1.00        |
| `Zig`   | 724.0 ± 5.3  | 718.7    | 729.4    | 1.06 ± 0.02 |
| `Roc`   | 857.5 ± 11.8 | 848.0    | 870.7    | 1.25 ± 0.03 |
| `Rust`  | 857.6 ± 13.6 | 842.4    | 868.6    | 1.25 ± 0.03 |

## Quick Start

### Prerequisites

* `just` (Task runner)
* `hyperfine` (Benchmarking)
* `mise` (Version manager - optional, for managing language versions)

### Basic Usage

```bash
# Build all implementations
just build-all

# Run comprehensive benchmark
just bench

# Build and test a specific implementation
just dev odin    # or rust, zig, roc

# See all available commands
just --list
```

## Available Commands

### Benchmarking

```bash
just bench       # Full benchmark with statistics
just bench-quick # Quick single-run benchmark
```

### Building & Running

```bash
# All languages
just build-all   # Build all implementations
just clean       # Clean all build artifacts

# Individual languages
just build-odin  # Build Odin implementation
just run-odin    # Run Odin implementation
just dev odin    # Build and run Odin

just build-roc   # Build Roc implementation  
just run-roc     # Run Roc implementation
just dev roc     # Build and run Roc

just build-rust  # Build Rust implementation
just run-rust    # Run Rust implementation  
just dev rust    # Build and run Rust

just build-zig   # Build Zig implementation
just run-zig     # Run Zig implementation
just dev zig     # Build and run Zig
```
