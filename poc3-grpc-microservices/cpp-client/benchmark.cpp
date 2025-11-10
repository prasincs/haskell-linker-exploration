#include <iostream>
#include <vector>
#include <chrono>
#include <numeric>
#include <cmath>
#include <algorithm>
#include <iomanip>

// Benchmarking utilities for gRPC + FFI performance comparison

struct BenchmarkResult {
    std::string name;
    double mean_ms;
    double median_ms;
    double stddev_ms;
    double min_ms;
    double max_ms;
    size_t iterations;
};

class Benchmark {
public:
    static BenchmarkResult run(const std::string& name,
                              std::function<void()> func,
                              size_t iterations = 100) {
        std::vector<double> times;
        times.reserve(iterations);

        // Warmup
        for (size_t i = 0; i < 5; i++) {
            func();
        }

        // Actual benchmark
        for (size_t i = 0; i < iterations; i++) {
            auto start = std::chrono::high_resolution_clock::now();
            func();
            auto end = std::chrono::high_resolution_clock::now();

            std::chrono::duration<double, std::milli> duration = end - start;
            times.push_back(duration.count());
        }

        return analyze(name, times);
    }

    static void printResult(const BenchmarkResult& result) {
        std::cout << "\n--- Benchmark: " << result.name << " ---" << std::endl;
        std::cout << std::fixed << std::setprecision(3);
        std::cout << "Iterations: " << result.iterations << std::endl;
        std::cout << "Mean:       " << result.mean_ms << " ms" << std::endl;
        std::cout << "Median:     " << result.median_ms << " ms" << std::endl;
        std::cout << "Std Dev:    " << result.stddev_ms << " ms" << std::endl;
        std::cout << "Min:        " << result.min_ms << " ms" << std::endl;
        std::cout << "Max:        " << result.max_ms << " ms" << std::endl;
    }

    static void compareResults(const BenchmarkResult& baseline,
                              const BenchmarkResult& comparison) {
        std::cout << "\n=== Comparison: " << baseline.name
                  << " vs " << comparison.name << " ===" << std::endl;
        std::cout << std::fixed << std::setprecision(2);

        double speedup = baseline.mean_ms / comparison.mean_ms;
        std::cout << "Speedup: " << speedup << "x ";
        if (speedup > 1.0) {
            std::cout << "(" << comparison.name << " is faster)" << std::endl;
        } else {
            std::cout << "(" << baseline.name << " is faster)" << std::endl;
        }

        double overhead_ms = comparison.mean_ms - baseline.mean_ms;
        double overhead_pct = (overhead_ms / baseline.mean_ms) * 100;
        std::cout << "Overhead: " << overhead_ms << " ms ("
                  << overhead_pct << "%)" << std::endl;
    }

private:
    static BenchmarkResult analyze(const std::string& name,
                                   const std::vector<double>& times) {
        BenchmarkResult result;
        result.name = name;
        result.iterations = times.size();

        // Mean
        result.mean_ms = std::accumulate(times.begin(), times.end(), 0.0) / times.size();

        // Median
        std::vector<double> sorted_times = times;
        std::sort(sorted_times.begin(), sorted_times.end());
        size_t mid = sorted_times.size() / 2;
        if (sorted_times.size() % 2 == 0) {
            result.median_ms = (sorted_times[mid - 1] + sorted_times[mid]) / 2.0;
        } else {
            result.median_ms = sorted_times[mid];
        }

        // Standard deviation
        double variance = 0.0;
        for (double time : times) {
            variance += (time - result.mean_ms) * (time - result.mean_ms);
        }
        variance /= times.size();
        result.stddev_ms = std::sqrt(variance);

        // Min/Max
        result.min_ms = *std::min_element(times.begin(), times.end());
        result.max_ms = *std::max_element(times.begin(), times.end());

        return result;
    }
};

// Example usage (to be integrated with actual gRPC client)
int main() {
    std::cout << "============================================" << std::endl;
    std::cout << "gRPC + FFI Benchmark Suite" << std::endl;
    std::cout << "============================================" << std::endl;

    // Example: Benchmark local function call
    auto localResult = Benchmark::run("Local C++ Function", []() {
        volatile int64_t result = 0;
        for (int i = 0; i < 1000; i++) {
            result += i;
        }
    }, 1000);

    Benchmark::printResult(localResult);

    std::cout << "\n============================================" << std::endl;
    std::cout << "Benchmark framework ready!" << std::endl;
    std::cout << "\nTo benchmark gRPC calls:" << std::endl;
    std::cout << "  1. Connect to Haskell gRPC server" << std::endl;
    std::cout << "  2. Use Benchmark::run() with RPC calls" << std::endl;
    std::cout << "  3. Compare with FFI (PoC 2) performance" << std::endl;
    std::cout << "\nExpected results:" << std::endl;
    std::cout << "  - FFI calls:       ~10-100 nanoseconds" << std::endl;
    std::cout << "  - gRPC localhost:  ~100-500 microseconds" << std::endl;
    std::cout << "  - Network gRPC:    ~1-50 milliseconds" << std::endl;
    std::cout << "============================================" << std::endl;

    return 0;
}
