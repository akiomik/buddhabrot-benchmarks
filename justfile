# Variables and constants
LANGUAGES := "odin roc rust zig"
BINARY_NAME := "buddhabrot"
BUILD_EMOJI := "🔧"
RUN_EMOJI := "🚀"

# Binary paths for each language
ODIN_BIN := "odin/" + BINARY_NAME
ROC_BIN := "roc/" + BINARY_NAME
RUST_BIN := "rust/target/release/" + BINARY_NAME
ZIG_BIN := "zig/zig-out/bin/" + BINARY_NAME

# Default recipe - show available commands
default:
    @just --list

# Build all implementations
build-all:
    #!/usr/bin/env bash
    for lang in {{LANGUAGES}}; do
        just build-$lang
    done

# Build Odin implementation
build-odin:
    @echo "{{BUILD_EMOJI}} Building Odin..."
    cd odin && odin build . -out={{BINARY_NAME}} -o:speed -microarch:native

# Build Roc implementation
build-roc:
    @echo "{{BUILD_EMOJI}} Building Roc..."
    cd roc && roc build --output {{BINARY_NAME}} --optimize

# Build Rust implementation
build-rust:
    @echo "{{BUILD_EMOJI}} Building Rust..."
    cd rust && RUSTFLAGS="-C target-cpu=native" cargo build --profile release

# Build Zig implementation
build-zig:
    @echo "{{BUILD_EMOJI}} Building Zig..."
    cd zig && zig build --release=fast -Dcpu=native

# Run Odin implementation
run-odin: build-odin
    @echo "{{RUN_EMOJI}} Running Odin..."
    ./{{ODIN_BIN}}

# Run Roc implementation
run-roc: build-roc
    @echo "{{RUN_EMOJI}} Running Roc..."
    ./{{ROC_BIN}}

# Run Rust implementation
run-rust: build-rust
    @echo "{{RUN_EMOJI}} Running Rust..."
    ./{{RUST_BIN}}

# Run Zig implementation
run-zig: build-zig
    @echo "{{RUN_EMOJI}} Running Zig..."
    ./{{ZIG_BIN}}

# Clean all build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    -rm -f {{ODIN_BIN}}
    -rm -f {{ROC_BIN}}
    -rm -rf rust/target
    -rm -rf zig/zig-out
    -rm -f */{{BINARY_NAME}}.pgm
    -rm -f *_profile.trace
    @echo "✅ Clean completed!"

# Collect language versions
lang-info:
    @echo "🔧 Collecting language versions..."
    @echo "**Language Versions:**"
    @odin version 2>/dev/null | head -1 | sed 's/^/- Odin: /' || echo "- Odin: unknown"
    @roc version 2>/dev/null | head -1 | sed 's/^/- Roc: /' || echo "- Roc: unknown" 
    @rustc --version 2>/dev/null | sed 's/^/- Rust: /' || echo "- Rust: unknown"
    @zig version 2>/dev/null | sed 's/^/- Zig: /' || echo "- Zig: unknown"

# Show executable file sizes
file-sizes:
    #!/usr/bin/env bash
    echo "📏 Executable file sizes:"
    echo "**Binary Sizes:**"
    
    declare -A paths=(
        ["odin"]="./{{ODIN_BIN}}"
        ["roc"]="./{{ROC_BIN}}"
        ["rust"]="./{{RUST_BIN}}"
        ["zig"]="./{{ZIG_BIN}}"
    )
    
    for lang in {{LANGUAGES}}; do
        if [ -f "${paths[$lang]}" ]; then
            size=$(ls -lh "${paths[$lang]}" | awk '{print $5}')
            echo "- $(echo $lang | tr '[:lower:]' '[:upper:]' | head -c 1)$(echo $lang | tail -c +2): $size"
        else
            echo "- $(echo $lang | tr '[:lower:]' '[:upper:]' | head -c 1)$(echo $lang | tail -c +2): not built"
        fi
    done

# Run benchmark
bench: build-all
    #!/usr/bin/env bash
    echo "📊 Running benchmark..."
    if command -v hyperfine >/dev/null 2>&1; then
        declare -A paths=(
            ["odin"]="./{{ODIN_BIN}}"
            ["roc"]="./{{ROC_BIN}}"
            ["rust"]="./{{RUST_BIN}}"
            ["zig"]="./{{ZIG_BIN}}"
        )
        
        cmd_args=""
        for lang in {{LANGUAGES}}; do
            name="$(echo $lang | tr '[:lower:]' '[:upper:]' | head -c 1)$(echo $lang | tail -c +2)"
            cmd_args="$cmd_args --command-name \"$name\" \"${paths[$lang]}\""
        done
        
        eval "hyperfine --warmup 1 --runs 3 --export-markdown benchmark_results.md $cmd_args"
        echo ""
        echo "📋 Results saved to benchmark_results.md"
    else
        echo "❌ hyperfine not found."
        exit 1
    fi

# Development mode - rebuild and run a specific implementation
dev lang: (build lang) (run lang)

# Build a specific language (helper for dev mode)
build lang:
    @just build-{{lang}}

# Run a specific language (helper for dev mode)  
run lang:
    @just run-{{lang}}

# Profile with macOS Instruments Time Profiler (macOS only)
[macos]
profile lang: (build lang)
    @just profile-{{lang}}

# Profile Odin implementation with Time Profiler (macOS only)
[macos]
profile-odin:
    @echo "🔍 Starting Time Profiler for Odin..."
    @echo "Profile will be saved to: odin_profile.trace"
    xcrun xctrace record --template "Time Profiler" --output odin_profile.trace --launch ./{{ODIN_BIN}}

# Profile Roc implementation with Time Profiler (macOS only)
[macos]
profile-roc:
    @echo "🔍 Starting Time Profiler for Roc..."
    @echo "Profile will be saved to: roc_profile.trace"
    xcrun xctrace record --template "Time Profiler" --output roc_profile.trace --launch ./{{ROC_BIN}}

# Profile Rust implementation with Time Profiler (macOS only)
[macos]
profile-rust:
    @echo "🔍 Starting Time Profiler for Rust..."
    @echo "Profile will be saved to: rust_profile.trace"
    xcrun xctrace record --template "Time Profiler" --output rust_profile.trace --launch ./{{RUST_BIN}}

# Profile Zig implementation with Time Profiler (macOS only)
[macos]
profile-zig:
    @echo "🔍 Starting Time Profiler for Zig..."
    @echo "Profile will be saved to: zig_profile.trace"
    xcrun xctrace record --template "Time Profiler" --output zig_profile.trace --launch ./{{ZIG_BIN}}
