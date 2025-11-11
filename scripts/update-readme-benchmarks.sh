#!/bin/bash
set -e

# Script to update README.md with real benchmark results from CI artifacts
# Run after benchmark-artifacts.sh

echo "============================================"
echo "Updating README with Benchmark Results"
echo "============================================"

BENCHMARK_OUTPUT="benchmark-results.txt"

if [ ! -f "$BENCHMARK_OUTPUT" ]; then
    echo "Error: $BENCHMARK_OUTPUT not found"
    echo "Run ./scripts/benchmark-artifacts.sh > benchmark-results.txt first"
    exit 1
fi

echo "Parsing benchmark results..."

# Extract key metrics
FFI_TIME=$(grep "FFI Fibonacci" -A 1 $BENCHMARK_OUTPUT | grep "Average:" | awk '{print $2}')
GRPC_TIME=$(grep "fib-client execution" -A 1 $BENCHMARK_OUTPUT | grep "Average:" | awk '{print $2}')

echo "FFI average: $FFI_TIME"
echo "gRPC average: $GRPC_TIME"

# TODO: Update README.md with these values
# For now, just display them

echo ""
echo "============================================"
echo "Benchmark Summary for README:"
echo "============================================"
echo ""
echo "| Approach | Latency | Notes |"
echo "|----------|---------|-------|"
echo "| FFI | $FFI_TIME | Direct function call (measured) |"
echo "| gRPC | $GRPC_TIME | Network stack overhead (measured) |"
echo ""
echo "Copy this table into README.md Performance Comparison section"
echo "============================================"
