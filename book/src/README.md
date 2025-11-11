# Why Your Linker Can't Link Haskell Code

A deep technical exploration into how Haskell programs are really built, why modern linkers like lld can't link Haskell code on their own, and what makes GHC an indispensable "general contractor" for your Haskell applications.

> **TL;DR**: Even if Haskell compiles to standard object files, you can't link them with `lld` or `ld` directly. GHC must orchestrate linking because it needs to add: (1) the ~5MB Haskell Runtime System (GC, scheduler, lazy evaluation), (2) 10+ boot libraries with complex dependencies, and (3) proper calling conventions for closures and info tables. This book proves it with runnable examples and explains why with comprehensive documentation.

## Repository and Getting Started

**GitHub Repository**: [github.com/prasincs/haskell-linker-exploration](https://github.com/prasincs/haskell-linker-exploration)

```bash
# Clone the repository
git clone https://github.com/prasincs/haskell-linker-exploration.git
cd haskell-linker-exploration
```

**License**: MIT License
**CI/CD**: All examples are tested in continuous integration for reproducibility

If you find this useful, please ⭐ star the repository!

## Prerequisites

This book includes runnable proof-of-concepts. To run them, you'll need one of the following setups:

### Option 1: Docker (Recommended - No Local Installation Required)

**Requirements**:
- Docker installed on your system
- No Haskell or GHC installation needed!

This is the easiest way to get started. The Docker container includes all necessary dependencies pre-configured.

### Option 2: Local Installation

**Requirements**:
- GHC ≥ 9.0
- LLVM ≥ 18
- Standard build tools (make, gcc/clang)
- For PoC 3: Go compiler and Protocol Buffers

**Reading Only**: If you just want to read the book without running examples, no installation is required.

## Running the Examples

All proof-of-concepts in this book are runnable! Choose your preferred method:

### Using Docker (Recommended)

```bash
# Build the Docker image
docker build -t ghc-linker-poc .

# Run all demonstrations
docker run --rm ghc-linker-poc ./scripts/run-all-demos.sh

# Or run individual PoCs
docker run --rm ghc-linker-poc bash -c "cd poc1-linker-comparison && ./build.sh"
```

### Using Local Installation

```bash
# Run all examples
./scripts/run-all-demos.sh

# Or run individual PoCs
cd poc1-linker-comparison && ./build.sh
cd ../poc2-ffi-integration && ./build.sh
cd ../poc3-grpc-microservices && ./build.sh
```

## About This Book

This book takes you on a journey from a simple question about linkers to a deep understanding of how Haskell programs are built, linked, and executed. Along the way, you'll:

- ✅ Run **working proof-of-concept examples** that demonstrate the concepts
- ✅ Explore the **GHC architecture** and understand its 30-year evolution
- ✅ Learn about the **Runtime System** (RTS) and why it's essential
- ✅ Understand **FFI** (Foreign Function Interface) and when to use it
- ✅ Compare **FFI vs gRPC** approaches for multi-language integration
- ✅ Get **practical guidance** for production deployments

## What You'll Learn

### Part I: Understanding the Problem
Start with the original question and uncover the fundamental misconceptions about how Haskell compilation works.

### Part II: Proof of Concepts
Three working demonstrations that prove the concepts:
1. **PoC 1**: Comparing naive linking vs GHC's approach (100+ argument difference!)
2. **PoC 2**: Calling Haskell from C using FFI
3. **PoC 3**: Modern alternative with gRPC microservices

### Part III: Deep Dive
Comprehensive technical explanations:
- GHC's compilation pipeline and architecture
- The Runtime System: GC, scheduler, heap management
- The linking process and why GHC orchestrates it
- Foreign Function Interface in detail

### Part IV: Interactive Explorations
- Browser-based WebAssembly demos
- Performance benchmarks (FFI vs gRPC)
- Interactive visualizations

### Part V: Production Considerations
- Decision frameworks for choosing approaches
- Best practices and patterns
- Troubleshooting common issues

## Who This Book Is For

This book is designed for:

- **Systems programmers** curious about Haskell's internals
- **Haskell developers** wanting to understand what GHC does under the hood
- **Engineers** integrating Haskell with other languages
- **Anyone** interested in compiler design and runtime systems

**Prerequisites**: Basic understanding of compilation (source → object files → executable) and some familiarity with either Haskell or systems programming.

## How to Use This Book

**Current content** (~30-60 minutes):
1. Start with [Part I: Understanding the Problem](./part-1-understanding/01-original-question.md)
2. Explore the working proof-of-concepts in the repository
3. Check back for updates as new chapters are added

**Coming soon**: Deep dives into GHC architecture, runtime system, FFI patterns, and production best practices.


## Key Takeaways

By the end of this book, you'll understand:

1. **GHC is more than a compiler** - it's a build orchestrator and driver
2. **The Runtime System is essential** - every Haskell program needs GC, scheduler, heap management
3. **Boot libraries are massive** - even "Hello, World" links 10+ packages
4. **FFI reveals the truth** - `hs_init()`/`hs_exit()` show the RTS dependency
5. **Modern alternatives exist** - gRPC microservices can be better than FFI for many use cases

## About the Author and Methodology

**Primary Author:** Prasanna - Research, code development, technical insights, verification

**AI Assistance:** Claude (Anthropic) - Documentation structure, diagram generation, expansion of explanations

> **Methodology Note**: This book combines original research and working code by Prasanna with AI-assisted documentation. All technical claims are verified against official sources. See the [Methodology appendix](./appendices/e-methodology.md) for full transparency.

---

## Let's Begin!

Ready to dive in? Start with [Chapter 1: The Original Question](./part-1-understanding/01-original-question.md) to understand what sparked this exploration.

> **Note**: This book is actively being developed. Currently, Part I (Understanding the Problem) is complete. Additional parts covering proof-of-concepts, deep dives, and production considerations are coming soon!
