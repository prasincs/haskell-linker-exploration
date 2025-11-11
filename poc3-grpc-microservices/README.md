# PoC 3: Modern Alternative - gRPC Microservices

## Overview

This proof-of-concept demonstrates a **modern alternative** to FFI linking: using **gRPC** to enable communication between C++ and Haskell programs as separate services.

Instead of fighting with linkers, each language runs in its own process with its own runtime, and they communicate over a well-defined protocol.

## The Problem With FFI Linking

From PoC 2, we learned that calling Haskell from C requires:
- Using GHC as the linker
- Manually managing the Haskell RTS (`hs_init`/`hs_exit`)
- A **single binary** that contains both C and Haskell code
- Complex build system integration

**Trade-offs:**
- ✅ Low latency (in-process calls)
- ✅ Single deployment artifact
- ❌ Complex build system
- ❌ Tight coupling
- ❌ Hard to scale independently
- ❌ Must restart entire process for updates

## The gRPC Solution

Instead, we deploy two separate services:

```
┌─────────────────────┐         ┌─────────────────────┐
│   C++ Client        │         │  Haskell Service    │
│                     │         │                     │
│  Built with g++/    │  gRPC   │  Built with GHC     │
│  clang/CMake        │ <-----> │  and cabal/stack    │
│                     │  HTTP/2 │                     │
│  Own binary         │         │  Own binary         │
│  Own runtime        │         │  Own runtime        │
└─────────────────────┘         └─────────────────────┘
```

**Trade-offs:**
- ✅ **Independent builds**: Each service uses its native toolchain
- ✅ **Independent deployment**: Update Haskell without recompiling C++
- ✅ **Independent scaling**: Run multiple Haskell instances
- ✅ **Language agnostic**: Could add Python, Rust, etc.
- ✅ **No linker complexity**: GHC links only Haskell, g++ links only C++
- ❌ Network latency (typically <1ms on localhost)
- ❌ Two deployment artifacts
- ❌ More operational complexity

## Architecture Comparison

### FFI Approach (PoC 2)

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

### gRPC Approach (PoC 3)

```
┌────────────────────┐           ┌────────────────────┐
│  C++ Client Binary │           │ Haskell Server     │
│                    │           │     Binary         │
│  ┌──────────────┐  │   HTTP/2  │  ┌──────────────┐  │
│  │ C++ Code     │  │  (gRPC)   │  │ Haskell Code │  │
│  │ (client.cpp) │  │◄─────────►│  │ (server.hs)  │  │
│  └──────────────┘  │   Proto   │  └──────────────┘  │
│         │          │   Buffer  │         │          │
│         ▼          │           │         ▼          │
│  ┌──────────────┐  │           │  ┌──────────────┐  │
│  │ gRPC C++     │  │           │  │ gRPC Haskell │  │
│  │ Runtime      │  │           │  │ Runtime      │  │
│  └──────────────┘  │           │  └──────────────┘  │
│         │          │           │         │          │
│         ▼          │           │         ▼          │
│  ┌──────────────┐  │           │  ┌──────────────┐  │
│  │ C++ Stdlib   │  │           │  │ Haskell RTS  │  │
│  └──────────────┘  │           │  └──────────────┘  │
└────────────────────┘           └────────────────────┘
    Built with: g++                Built with: ghc
    Deployed: anywhere             Deployed: anywhere
```

## The Example: Fibonacci Service

### Protocol Definition (proto/fibonacci.proto)

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

### Haskell Server (haskell-service/Server.hs)

```haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Network.GRPC.HighLevel.Server
import Data.ProtoLens (defMessage)
import Lens.Micro
import qualified Proto.Fibonacci as Fib
import qualified Proto.Fibonacci_Fields as Fib

-- Pure Haskell implementation
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

### C++ Client (cpp-client/client.cpp)

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

## Build System Comparison

### FFI Approach (Complex, GHC-dependent)

```bash
# Build Haskell library
ghc -c MyLib.hs -o MyLib.o

# Build C++ code
g++ -c main.cpp -o main.o -I/usr/lib/ghc-9.4.8/include

# Link (MUST use GHC!)
ghc -no-hs-main -o program main.o MyLib.o -lstdc++
```

**Problems:**
- Must use GHC for final link
- C++ build must know about GHC include paths
- Tight coupling between build systems
- Hard to integrate with CMake/Make/Bazel

### gRPC Approach (Independent, Native)

**Haskell Service:**
```bash
# Build with cabal (native Haskell tooling)
cd haskell-service
cabal build
./dist/build/fib-server/fib-server
```

**C++ Client:**
```bash
# Build with CMake and clang (native C++ tooling)
cd cpp-client
mkdir build && cd build
cmake -DCMAKE_CXX_COMPILER=clang++ ..
make
./fib-client

# Or build directly with clang
clang++ -std=c++17 -O2 -fuse-ld=lld client.cpp -o fib-client -pthread
```

**Completely independent!**
- Each uses its native build system
- No cross-language build dependencies
- Can use different compilers (GHC vs clang), flags, optimizations
- Easy CI/CD: build in separate pipelines

## Deployment Comparison

### FFI: Single Binary

```bash
# Deploy
scp program server:/opt/app/program
ssh server "systemctl restart app"

# Update Haskell code? Rebuild and redeploy EVERYTHING
ghc -no-hs-main -o program main.o MyLib.o
scp program server:/opt/app/program
ssh server "systemctl restart app"
```

### gRPC: Independent Services

```bash
# Deploy both
docker-compose up -d

# Update only Haskell service
cd haskell-service
cabal build
docker build -t fib-server:v2 .
kubectl set image deployment/fib-server fib-server=fib-server:v2

# C++ client keeps running!
# No downtime, no rebuild of C++ code
```

## Performance Comparison

### Latency

| Approach | Latency | Notes |
|----------|---------|-------|
| **FFI** | ~10ns | Direct function call |
| **gRPC (localhost)** | ~100μs | Network stack overhead |
| **gRPC (same datacenter)** | ~1ms | Real network |
| **gRPC (cross-region)** | ~50ms | Geographic distance |

### When FFI Still Makes Sense

Use FFI when:
- ✅ Need microsecond-level latency
- ✅ Calling Haskell functions millions of times per second
- ✅ Single deployment is required
- ✅ Build complexity is acceptable

**Example use cases:**
- High-frequency trading systems
- Game engines (calling Haskell for AI/logic)
- Embedded systems with limited resources

### When gRPC Makes More Sense

Use gRPC when:
- ✅ Services can scale independently
- ✅ Teams work on different parts
- ✅ Need language flexibility
- ✅ Latency requirements are >1ms
- ✅ Deployment flexibility is important

**Example use cases:**
- Microservices architecture
- Machine learning inference servers
- Business logic services
- Multi-language platforms

## Code Maintenance Comparison

### FFI Challenges

```c++
// main.cpp
#include "HsFFI.h"
#include "MyLib_stub.h"  // Must regenerate when MyLib.hs changes

int main(int argc, char** argv) {
    hs_init(&argc, &argv);  // Easy to forget!

    // Call Haskell
    int result = hs_fib(10);

    hs_exit();  // Easy to forget!
    return 0;
}
```

**Maintenance issues:**
- Regenerate stub headers when Haskell API changes
- Remember to call `hs_init`/`hs_exit`
- Memory management across FFI boundary is tricky
- Debugging requires understanding both runtimes

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
- ✅ No manual resource management
- ✅ Type-safe API in both languages
- ✅ Each service can be tested independently
- ✅ Can mock the other service for testing

## Running This PoC

### Prerequisites

```bash
# Install gRPC and Protocol Buffers
apt-get install -y protobuf-compiler libgrpc++-dev

# Install Haskell gRPC library
cabal install proto-lens-protoc grpc-haskell
```

### Build and Run

```bash
# Terminal 1: Start Haskell server
cd poc3-grpc-microservices/haskell-service
cabal run fib-server

# Terminal 2: Run C++ client
cd poc3-grpc-microservices/cpp-client
mkdir build && cd build
cmake ..
make
./fib-client
```

### With Docker Compose

```bash
cd poc3-grpc-microservices
docker-compose up

# In another terminal
docker-compose exec cpp-client ./fib-client
```

## When to Use Each Approach

### Decision Matrix

| Criteria | Use FFI (PoC 2) | Use gRPC (PoC 3) |
|----------|----------------|------------------|
| Latency requirement | < 1μs | > 100μs |
| Call frequency | Millions/sec | Thousands/sec |
| Team structure | Small, integrated | Multiple teams |
| Deployment model | Single binary | Microservices |
| Language diversity | 2 languages | 3+ languages |
| Build complexity tolerance | High | Low |
| Scaling needs | Vertical only | Horizontal scaling |
| Update frequency | Rare | Frequent |

## Real-World Examples

### Companies Using gRPC for Multi-Language Services

1. **Google** - Internal services (invented gRPC)
   - C++ core services
   - Go, Java, Python for applications
   - Haskell for specific business logic

2. **Netflix** - Polyglot microservices
   - Java/Kotlin for most services
   - C++ for encoding
   - Node.js for UI services

3. **Square** - Payment processing
   - Go for core services
   - Ruby for web applications
   - C++ for cryptography

## Conclusion

**FFI is not the only way** to integrate Haskell with other languages. For many modern applications, **gRPC microservices** offer a better trade-off:

| Aspect | FFI | gRPC |
|--------|-----|------|
| Build complexity | ⚠️ High | ✅ Low |
| Deployment | ✅ Simple | ⚠️ Complex |
| Latency | ✅ Nanoseconds | ⚠️ Microseconds |
| Scaling | ⚠️ Vertical | ✅ Horizontal |
| Team autonomy | ❌ Low | ✅ High |
| Language flexibility | ⚠️ Limited | ✅ Unlimited |

**Choose FFI when:** You need extreme performance and can tolerate build complexity.

**Choose gRPC when:** You need flexibility, maintainability, and independent deployment.

## Files in This Directory

- `proto/fibonacci.proto` - Protocol definition (language-agnostic)
- `haskell-service/` - Haskell gRPC server
  - `Server.hs` - Service implementation
  - `fib-server.cabal` - Build configuration
  - `Dockerfile` - Container image
- `cpp-client/` - C++ gRPC client
  - `client.cpp` - Client implementation
  - `CMakeLists.txt` - Build configuration
  - `Dockerfile` - Container image
- `docker-compose.yml` - Run both services together
- `README.md` - This file

## Further Reading

- [gRPC Official Documentation](https://grpc.io/docs/)
- [Protocol Buffers](https://protobuf.dev/)
- [Microservices Patterns](https://microservices.io/patterns/index.html)
- [gRPC vs REST Performance](https://grpc.io/docs/guides/performance/)
- Main repository: [../README.md](../README.md)
