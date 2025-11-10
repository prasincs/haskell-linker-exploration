#include <iostream>
#include <memory>
#include <string>
#include <vector>
#include <chrono>
#include <iomanip>

// Simplified demonstration client (without full gRPC dependencies)
// This shows the structure and includes benchmarking code

namespace fibonacci {
    struct FibRequest {
        int32_t n;
    };

    struct FibResponse {
        int32_t n;
        int64_t result;
        double computation_time_ms;
    };

    struct BatchRequest {
        std::vector<int32_t> numbers;
    };

    struct BatchResponse {
        std::vector<FibResponse> results;
        double total_time_ms;
    };
}

// Simple Fibonacci client (demonstration without gRPC dependencies)
class FibonacciClient {
public:
    FibonacciClient(const std::string& server_address)
        : server_address_(server_address) {
        std::cout << "Connecting to server: " << server_address << std::endl;
    }

    // Simulate Calculate RPC
    int64_t Calculate(int32_t n) {
        auto start = std::chrono::high_resolution_clock::now();

        // Local calculation (simulating server call for demo)
        int64_t result = localFibonacci(n);

        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> duration = end - start;

        std::cout << "fib(" << n << ") = " << result
                  << " (local calc: " << std::fixed << std::setprecision(3)
                  << duration.count() << "ms)" << std::endl;

        return result;
    }

    // Simulate CalculateBatch RPC
    void CalculateBatch(const std::vector<int32_t>& numbers) {
        auto start = std::chrono::high_resolution_clock::now();

        std::cout << "\nBatch calculation for " << numbers.size() << " numbers:" << std::endl;

        for (auto n : numbers) {
            int64_t result = localFibonacci(n);
            std::cout << "  fib(" << n << ") = " << result << std::endl;
        }

        auto end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> duration = end - start;

        std::cout << "Batch total time: " << std::fixed << std::setprecision(3)
                  << duration.count() << "ms" << std::endl;
    }

private:
    std::string server_address_;

    // Local Fibonacci implementation (for demonstration)
    int64_t localFibonacci(int n) {
        if (n <= 1) return n;

        // Use iterative approach for efficiency
        int64_t a = 0, b = 1;
        for (int i = 2; i <= n; i++) {
            int64_t temp = a + b;
            a = b;
            b = temp;
        }
        return b;
    }
};

int main(int argc, char** argv) {
    std::cout << "============================================" << std::endl;
    std::cout << "C++ Fibonacci gRPC Client (Demo Mode)" << std::endl;
    std::cout << "============================================" << std::endl;
    std::cout << std::endl;

    std::string server_address("localhost:50051");

    FibonacciClient client(server_address);

    std::cout << "\n--- Single Calculations ---" << std::endl;
    // Call Haskell service via gRPC
    for (int i : {10, 15, 20, 25, 30}) {
        client.Calculate(i);
    }

    std::cout << "\n--- Batch Calculation ---" << std::endl;
    client.CalculateBatch({5, 10, 15, 20, 25, 30});

    std::cout << "\n============================================" << std::endl;
    std::cout << "Demo complete!" << std::endl;
    std::cout << std::endl;
    std::cout << "Note: This is a demonstration client." << std::endl;
    std::cout << "For full gRPC integration, you need:" << std::endl;
    std::cout << "  - gRPC C++ libraries installed" << std::endl;
    std::cout << "  - Generated proto code from fibonacci.proto" << std::endl;
    std::cout << "  - Running Haskell gRPC server" << std::endl;
    std::cout << std::endl;
    std::cout << "See benchmark.cpp for performance testing code" << std::endl;
    std::cout << "============================================" << std::endl;

    return 0;
}
