# Chapter 5: PoC 3 - Modern Alternative: gRPC Microservices

## Overview

In [PoC 2](./04-poc2-ffi-integration.md), we saw how to call Haskell from C using FFI. But it came with complexities:
- Must use GHC as the linker
- Manual RTS management (`hs_init`/`hs_exit`)
- Tight coupling between build systems
- Single binary deployment

**What if there's a better way?**

This proof-of-concept demonstrates a **modern alternative**: using **gRPC** to enable communication between C++ and Haskell programs as separate, independent services.

## The Problem With FFI Linking

Let's recap the challenges from PoC 2:

### FFI Approach
```
┌────────────────────────────────────────────┐
│         Single Binary                      │
│  ┌──────────────┐   ┌─────────────────┐   │
│  │  C++ Code    │ → │  Haskell Code   │   │
│  │  (main.cpp)  │   │  (MyLib.hs)     │   │
│  └──────────────┘   └─────────────────┘   │
│         │                    │             │
│         └────────┬───────────┘             │
│                  ▼                         │
│  ┌────────────────────────────────────┐   │
│  │    Haskell Runtime System (RTS)    │   │
│  │  ┌─────┬──────────┬──────┐        │   │
│  │  │ GC  │Scheduler │ Heap │        │   │
│  │  └─────┴──────────┴──────┘        │   │
│  └────────────────────────────────────┘   │
└────────────────────────────────────────────┘
     Built with: ghc -no-hs-main
```

**Trade-offs:**
- ✅ Low latency (nanoseconds)
- ✅ Single deployment artifact
- ❌ Complex build system (must use GHC for linking)
- ❌ Tight coupling
- ❌ Hard to scale independently
- ❌ Must restart entire process for updates

## The gRPC Solution

Instead, we deploy two **separate services**:

```
┌─────────────────────┐         ┌─────────────────────┐
│   C++ Client        │         │  Haskell Service    │
│                     │         │                     │
│  Built with clang++ │  gRPC   │  Built with GHC     │
│  Uses lld linker    │ <-----> │  Uses GHC linker    │
│                     │  HTTP/2 │                     │
│  Own binary         │         │  Own binary         │
│  Own runtime        │         │  Own runtime        │
└─────────────────────┘         └─────────────────────┘
```

**Trade-offs:**
- ✅ **Independent builds**: Each uses its native toolchain
- ✅ **Independent deployment**: Update Haskell without recompiling C++
- ✅ **Independent scaling**: Run multiple Haskell instances
- ✅ **Language agnostic**: Could add Python, Rust, etc.
- ✅ **No linker complexity**: GHC links only Haskell, clang++ links only C++
- ❌ Network latency (typically ~100μs on localhost, vs ~10ns for FFI)
- ❌ Two deployment artifacts
- ❌ More operational complexity (service discovery, monitoring)

## The Example: Fibonacci Service

Let's build the same Fibonacci calculator, but as a gRPC service!

### Step 1: Protocol Definition (proto/fibonacci.proto)

gRPC uses **Protocol Buffers** to define language-agnostic interfaces:

```protobuf
syntax = "proto3";

package fibonacci;

service FibonacciService {
  rpc Calculate (FibRequest) returns (FibResponse);
  rpc CalculateBatch (BatchRequest) returns (BatchResponse);
}

message FibRequest {
  int32 n = 1;
}

message FibResponse {
  int32 n = 1;
  int64 result = 2;
  double computation_time_ms = 3;
}

message BatchRequest {
  repeated int32 numbers = 1;
}

message BatchResponse {
  repeated FibResponse results = 1;
}
```

**Key points:**
- ✅ Single source of truth for the API
- ✅ Generates code for both Haskell and C++
- ✅ Strongly typed across languages
- ✅ Versioning and evolution built-in

### Step 2: Haskell Server

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Network.GRPC.HighLevel.Server
import Data.ProtoLens (defMessage)
import Lens.Micro
import qualified Proto.Fibonacci as Fib
import qualified Proto.Fibonacci_Fields as Fib

-- Pure Haskell implementation (same as PoC 2!)
fibonacci :: Int -> Integer
fibonacci 0 = 0
fibonacci 1 = 1
fibonacci n = fibonacci (n-1) + fibonacci (n-2)

-- gRPC handler
handleCalculate :: ServerRequest 'Normal Fib.FibRequest Fib.FibResponse
                -> IO (ServerResponse 'Normal Fib.FibResponse)
handleCalculate (ServerNormalRequest _metadata req) = do
    let n = req ^. Fib.n
    let result = fibonacci (fromIntegral n)

    let response = defMessage
                 & Fib.n .~ n
                 & Fib.result .~ fromIntegral result

    return $ ServerNormalResponse response [] StatusOk ""

main :: IO ()
main = do
    putStrLn "Starting Haskell Fibonacci gRPC server on port 50051..."
    runServer $ ServerConfig
        { serverHost = "0.0.0.0"
        , serverPort = 50051
        , serverHandlers =
            [ ServiceHandler Fib.fibonacciServiceMethods
                [ MethodHandler Fib.calculate handleCalculate
                ]
            ]
        }
```

**Build with native Haskell tools:**
```bash
cd haskell-service
cabal build
./dist/build/fib-server/fib-server
```

✅ **No special linking!** Just normal GHC.

### Step 3: C++ Client

```cpp
#include <iostream>
#include <memory>
#include <string>
#include <grpcpp/grpcpp.h>
#include "fibonacci.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using fibonacci::FibonacciService;
using fibonacci::FibRequest;
using fibonacci::FibResponse;

class FibonacciClient {
public:
    FibonacciClient(std::shared_ptr<Channel> channel)
        : stub_(FibonacciService::NewStub(channel)) {}

    int64_t Calculate(int32_t n) {
        FibRequest request;
        request.set_n(n);

        FibResponse response;
        ClientContext context;

        Status status = stub_->Calculate(&context, request, &response);

        if (status.ok()) {
            std::cout << "fib(" << response.n() << ") = "
                      << response.result() << std::endl;
            return response.result();
        } else {
            std::cout << "RPC failed: " << status.error_message() << std::endl;
            return -1;
        }
    }

private:
    std::unique_ptr<FibonacciService::Stub> stub_;
};

int main(int argc, char** argv) {
    // Connect to Haskell service
    std::string server_address("localhost:50051");

    FibonacciClient client(
        grpc::CreateChannel(server_address,
                          grpc::InsecureChannelCredentials())
    );

    // Call Haskell function via gRPC
    std::cout << "C++ client calling Haskell service..." << std::endl;

    for (int i = 1; i <= 10; i++) {
        client.Calculate(i);
    }

    return 0;
}
```

**Build with native C++ tools:**
```bash
cd cpp-client
mkdir build && cd build
cmake -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_LINKER=lld ..
make
./fib-client
```

✅ **Can use clang++ and lld!** No GHC required.

## Build System Comparison

### FFI Approach (Complex, GHC-dependent)

```bash
# Build Haskell library
$ ghc -c MyLib.hs -o MyLib.o

# Build C++ code (must know GHC paths!)
$ g++ -c main.cpp -o main.o -I/usr/lib/ghc-9.4.8/include

# Link (MUST use GHC!)
$ ghc -no-hs-main -o program main.o MyLib.o -lstdc++
```

**Problems:**
- ❌ Must use GHC for final link
- ❌ C++ build must know about GHC include paths
- ❌ Tight coupling between build systems
- ❌ Hard to integrate with CMake/Make/Bazel

### gRPC Approach (Independent, Native)

**Haskell Service:**
```bash
cd haskell-service
cabal build            # Pure Haskell tooling
cabal run fib-server   # Run directly
```

**C++ Client:**
```bash
cd cpp-client
mkdir build && cd build
cmake -DCMAKE_CXX_COMPILER=clang++ ..
make                   # Pure C++ tooling
./fib-client
```

**Benefits:**
- ✅ Each uses its **native build system**
- ✅ **No cross-language build dependencies**
- ✅ Can use **different compilers**, flags, optimizations
- ✅ Easy **CI/CD**: build in separate pipelines

## Deployment Comparison

### FFI: Single Binary

```bash
# Deploy
$ scp program server:/opt/app/program
$ ssh server "systemctl restart app"

# Update Haskell code? Rebuild and redeploy EVERYTHING
$ ghc -no-hs-main -o program main.o MyLib.o
$ scp program server:/opt/app/program
$ ssh server "systemctl restart app"  # Full restart!
```

### gRPC: Independent Services

```bash
# Deploy both
$ docker-compose up -d

# Update only Haskell service
$ cd haskell-service
$ cabal build
$ docker build -t fib-server:v2 .
$ kubectl set image deployment/fib-server fib-server=fib-server:v2

# C++ client keeps running! No downtime, no rebuild of C++ code
```

## Performance Comparison

### Latency

| Approach | Latency | Notes |
|----------|---------|-------|
| **FFI** | ~10ns | Direct function call (in-process) |
| **gRPC (localhost)** | ~100μs | Network stack overhead |
| **gRPC (same datacenter)** | ~1ms | Real network |
| **gRPC (cross-region)** | ~50ms | Geographic distance |

### Throughput

**FFI:**
- Can handle millions of calls per second
- Limited by single process/machine

**gRPC:**
- Thousands to tens of thousands of calls per second per instance
- But can scale horizontally! Run 100 instances → 1M calls/sec

### When FFI Still Makes Sense

Use FFI when:
- ✅ Need **microsecond-level latency**
- ✅ Calling functions **millions of times per second**
- ✅ **Single deployment** artifact required
- ✅ Build complexity is acceptable

**Example use cases:**
- High-frequency trading systems (every nanosecond counts)
- Game engines (calling Haskell for AI/logic in hot loop)
- Embedded systems (limited resources, can't run multiple processes)
- Signal processing (real-time audio/video)

### When gRPC Makes More Sense

Use gRPC when:
- ✅ Services can **scale independently**
- ✅ **Multiple teams** working on different components
- ✅ Need **language flexibility** (more than 2 languages)
- ✅ Latency requirements are **> 1ms**
- ✅ **Deployment flexibility** is important
- ✅ Want **independent release cycles**

**Example use cases:**
- Microservices architecture
- Machine learning inference servers
- Business logic services
- Multi-language platforms
- APIs with multiple clients

## Code Maintenance Comparison

### FFI Challenges

```cpp
// main.cpp
#include "HsFFI.h"
#include "MyLib_stub.h"  // Must regenerate when MyLib.hs changes!

int main(int argc, char** argv) {
    hs_init(&argc, &argv);  // Easy to forget!

    int result = hs_fib(10);

    hs_exit();  // Easy to forget! Memory leaks if missed
    return 0;
}
```

**Maintenance issues:**
- ⚠️ Regenerate stub headers when Haskell API changes
- ⚠️ Remember to call `hs_init`/`hs_exit`
- ⚠️ Memory management across FFI boundary is tricky
- ⚠️ Debugging requires understanding both runtimes
- ⚠️ Version skew between generated stubs and implementations

### gRPC Benefits

```cpp
// client.cpp
#include "fibonacci.grpc.pb.h"  // Auto-generated from .proto

int main() {
    FibonacciClient client("localhost:50051");

    // Type-safe, auto-generated API
    int64_t result = client.Calculate(10);

    // No manual resource management!
    return 0;
}
```

**Maintenance benefits:**
- ✅ Change `.proto` file, regenerate both sides automatically
- ✅ No manual resource management (gRPC handles connections)
- ✅ Type-safe API in both languages
- ✅ Each service can be tested independently
- ✅ Can mock the other service for testing
- ✅ Versioning and compatibility built into protocol

## Running This PoC

### Prerequisites

```bash
# Install gRPC and Protocol Buffers
$ apt-get install -y protobuf-compiler libgrpc++-dev

# Install Haskell gRPC library
$ cabal install proto-lens-protoc grpc-haskell
```

### Build and Run

**Terminal 1: Start Haskell server**
```bash
$ cd poc3-grpc-microservices/haskell-service
$ cabal run fib-server
Starting Haskell Fibonacci gRPC server on port 50051...
```

**Terminal 2: Run C++ client**
```bash
$ cd poc3-grpc-microservices/cpp-client
$ mkdir build && cd build
$ cmake ..
$ make
$ ./fib-client
C++ client calling Haskell service...
fib(1) = 1
fib(2) = 1
fib(3) = 2
...
fib(10) = 55
```

### With Docker Compose

```bash
$ cd poc3-grpc-microservices
$ docker-compose up

# In another terminal
$ docker-compose exec cpp-client ./fib-client
```

## When to Use Each Approach

### Decision Matrix

| Criteria | Use FFI (PoC 2) | Use gRPC (PoC 3) |
|----------|----------------|------------------|
| **Latency requirement** | < 1μs | > 100μs |
| **Call frequency** | Millions/sec | Thousands/sec |
| **Team structure** | Small, integrated | Multiple teams |
| **Deployment model** | Single binary | Microservices |
| **Language diversity** | 2 languages | 3+ languages |
| **Build complexity tolerance** | High | Low |
| **Scaling needs** | Vertical only | Horizontal scaling |
| **Update frequency** | Rare | Frequent |
| **Operational complexity** | Low | Medium-High |

### Real-World Decision Tree

```
Need to integrate Haskell with another language?
│
├─ Is latency critical (< 1ms)?
│  ├─ YES → Consider FFI
│  │   └─ Can you tolerate complex builds?
│  │      ├─ YES → Use FFI
│  │      └─ NO → Use gRPC, optimize network
│  │
│  └─ NO → Consider gRPC
│      └─ Need to scale independently?
│         ├─ YES → Use gRPC
│         └─ NO → Either works, gRPC is simpler
│
└─ Multiple languages (3+)?
   └─ YES → Definitely use gRPC
```

## Real-World Examples

### Companies Using gRPC for Multi-Language Services

1. **Google** - Internal services (invented gRPC!)
   - C++ core services
   - Go, Java, Python for applications
   - Language-agnostic APIs

2. **Netflix** - Polyglot microservices
   - Java/Kotlin for most services
   - C++ for encoding
   - Node.js for UI services

3. **Square** - Payment processing
   - Go for core services
   - Ruby for web applications
   - C++ for cryptography

## Files in This Directory

```
poc3-grpc-microservices/
├── README.md
├── proto/
│   └── fibonacci.proto       # Protocol definition
├── haskell-service/
│   ├── Server.hs
│   ├── fib-server.cabal
│   └── Dockerfile
├── cpp-client/
│   ├── client.cpp
│   ├── CMakeLists.txt
│   └── Dockerfile
└── docker-compose.yml
```

## Exercises

### Exercise 1: Add a New RPC Method

Add a method to sum an array of Fibonacci numbers:

```protobuf
rpc SumBatch (BatchRequest) returns (SumResponse);

message SumResponse {
  int64 total = 1;
}
```

Implement it in both Haskell and C++!

### Exercise 2: Benchmark the Difference

Measure the performance difference:

```cpp
// FFI: 1 million calls
for (int i = 0; i < 1000000; i++) {
    hs_fib(10);
}

// gRPC: 1000 calls
for (int i = 0; i < 1000; i++) {
    client.Calculate(10);
}
```

How much slower is gRPC? Is it acceptable for your use case?

### Exercise 3: Error Handling

What happens if the Haskell server crashes? Add error handling:

```cpp
grpc::ClientContext context;
context.set_deadline(std::chrono::system_clock::now() +
                     std::chrono::seconds(1));

Status status = stub_->Calculate(&context, request, &response);
if (!status.ok()) {
    // Handle error, retry, failover, etc.
}
```

---

## Summary

| Aspect | FFI (PoC 2) | gRPC (PoC 3) |
|--------|-------------|--------------|
| **Build** | ⚠️ Complex | ✅ Simple |
| **Deployment** | ✅ Single binary | ⚠️ Multiple services |
| **Latency** | ✅ 10ns | ⚠️ 100μs |
| **Scaling** | ⚠️ Vertical | ✅ Horizontal |
| **Maintenance** | ⚠️ Coupled | ✅ Independent |
| **Teams** | ⚠️ Shared | ✅ Autonomous |

**Conclusion**: FFI isn't the only way! For many modern applications, gRPC offers a better trade-off between performance and maintainability.

---

## Next Steps

Now that we've explored all three proof-of-concepts, let's dive deeper into how GHC actually works.

**Next part**: [Part III: Deep Dive →](../part-3-deep-dive/06-ghc-architecture.md)

---

## Quick Navigation

- **Previous**: [← PoC 2: FFI Integration](./04-poc2-ffi-integration.md)
- **Next**: [GHC Architecture →](../part-3-deep-dive/06-ghc-architecture.md)
- **Compare**: [Decision Framework →](../part-5-production/12-decision-framework.md)
