# Default recipe - show available commands
default:
    @just --list

# Build all implementations
build-all: build-odin build-roc build-rust build-zig

# Build Odin implementation
build-odin:
    @echo "🔧 Building Odin..."
    cd odin && odin build . -out=buddhabrot -o:speed

# Build Roc implementation
build-roc:
    @echo "🔧 Building Roc..."
    cd roc && roc build --output buddhabrot --optimize

# Build Rust implementation
build-rust:
    @echo "🔧 Building Rust..."
    cd rust && cargo build --profile release

# Build Zig implementation
build-zig:
    @echo "🔧 Building Zig..."
    cd zig && zig build --release=fast

# Run Odin implementation
run-odin: build-odin
    @echo "🚀 Running Odin..."
    ./odin/buddhabrot

# Run Roc implementation
run-roc: build-roc
    @echo "🚀 Running Roc..."
    ./roc/buddhabrot

# Run Rust implementation
run-rust: build-rust
    @echo "🚀 Running Rust..."
    ./rust/target/release/buddhabrot

# Run Zig implementation
run-zig: build-zig
    @echo "🚀 Running Zig..."
    ./zig/zig-out/bin/buddhabrot

# Clean all build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    -rm -f odin/buddhabrot
    -rm -f roc/buddhabrot
    -rm -rf rust/target
    -rm -rf zig/zig-out
    -rm -f */buddhabrot.pgm
    @echo "✅ Clean completed!"

# Collect language versions
lang-info:
    @echo "🔧 Collecting language versions..."
    @echo "**Language Versions:**"
    @odin version 2>/dev/null | head -1 | sed 's/^/- Odin: /' || echo "- Odin: unknown"
    @roc version 2>/dev/null | head -1 | sed 's/^/- Roc: /' || echo "- Roc: unknown" 
    @rustc --version 2>/dev/null | sed 's/^/- Rust: /' || echo "- Rust: unknown"
    @zig version 2>/dev/null | sed 's/^/- Zig: /' || echo "- Zig: unknown"

# Run benchmark
bench: build-all
    @echo "📊 Running benchmark..."
    @if command -v hyperfine >/dev/null 2>&1; then \
        hyperfine --warmup 1 --runs 3 \
            --export-markdown benchmark_results.md \
            --command-name "Odin" "./odin/buddhabrot" \
            --command-name "Roc" "./roc/buddhabrot" \
            --command-name "Rust" "./rust/target/release/buddhabrot" \
            --command-name "Zig" "./zig/zig-out/bin/buddhabrot"; \
        echo ""; \
        echo "📋 Results saved to benchmark_results.md"; \
    else \
        echo "❌ hyperfine not found."; \
        exit 1; \
    fi

# Development mode - rebuild and run a specific implementation
dev lang: (build lang) (run lang)

# Build a specific language (helper for dev mode)
build lang:
    @just build-{{lang}}

# Run a specific language (helper for dev mode)  
run lang:
    @just run-{{lang}}
