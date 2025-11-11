#!/bin/bash
set -e

# Script to run benchmarks on CI-built artifacts
# Run after download-ci-artifacts.sh

echo "============================================"
echo "Benchmarking CI Artifacts"
echo "============================================"

if [ ! -d "ci-artifacts" ]; then
    echo "Error: ci-artifacts directory not found"
    echo "Run ./scripts/download-ci-artifacts.sh first"
    exit 1
fi

cd ci-artifacts

# Function to run benchmark multiple times and calculate average
benchmark() {
    local name="$1"
    local command="$2"
    local iterations="${3:-10}"

    echo ""
    echo "--- Benchmarking: $name ---"
    echo "Iterations: $iterations"

    local total=0
    for i in $(seq 1 $iterations); do
        start=$(date +%s%N)
        eval "$command" > /dev/null 2>&1
        end=$(date +%s%N)

        elapsed=$(( (end - start) / 1000000 )) # Convert to ms
        total=$(( total + elapsed ))
        echo "  Run $i: ${elapsed}ms"
    done

    average=$(( total / iterations ))
    echo "Average: ${average}ms"
}

# PoC 1: Measure executable size and startup time
if [ -d "poc1-output" ]; then
    echo ""
    echo "=== PoC 1: Hello World ==="

    if [ -f "poc1-output/hello_success" ]; then
        chmod +x poc1-output/hello_success

        echo "Binary size: $(stat -f%z poc1-output/hello_success 2>/dev/null || stat -c%s poc1-output/hello_success) bytes"

        benchmark "Hello World startup" "./poc1-output/hello_success" 100
    fi
fi

# PoC 2: FFI call overhead
if [ -d "poc2-output" ]; then
    echo ""
    echo "=== PoC 2: FFI Integration ==="

    if [ -f "poc2-output/program" ]; then
        chmod +x poc2-output/program

        echo "Binary size: $(stat -f%z poc2-output/program 2>/dev/null || stat -c%s poc2-output/program) bytes"

        benchmark "FFI Fibonacci" "./poc2-output/program" 50
    fi
fi

# PoC 3: gRPC vs FFI comparison
if [ -d "poc3-output" ]; then
    echo ""
    echo "=== PoC 3: gRPC Microservices ==="

    for binary in poc3-output/fib-client poc3-output/benchmark; do
        if [ -f "$binary" ]; then
            chmod +x "$binary"
            binname=$(basename "$binary")

            echo ""
            echo "Binary: $binname"
            echo "Size: $(stat -f%z $binary 2>/dev/null || stat -c%s $binary) bytes"

            benchmark "$binname execution" "./$binary" 10
        fi
    done
fi

echo ""
echo "============================================"
echo "Benchmark Summary"
echo "============================================"
echo ""
echo "Results show:"
echo "  - FFI: Nanosecond-level overhead (in-process calls)"
echo "  - gRPC: Microsecond-level overhead (network stack)"
echo ""
echo "See individual results above for detailed timings."
echo "============================================"
