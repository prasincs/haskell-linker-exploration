# Why Your Linker Can't Link Haskell Code

A deep technical exploration into how Haskell programs are really built, why modern linkers like lld can't link Haskell code on their own, and what makes GHC an indispensable "general contractor" for your Haskell applications.

## About This Book

> **TL;DR**: Even if Haskell compiles to standard object files, you can't link them with `lld` or `ld` directly. GHC must orchestrate linking because it needs to add: (1) the ~5MB Haskell Runtime System (GC, scheduler, lazy evaluation), (2) 10+ boot libraries with complex dependencies, and (3) proper calling conventions for closures and info tables. This book proves it with runnable examples and explains why with comprehensive documentation.

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

### Reading Path Options

**Quick overview** (30 minutes):
1. Read Part I (Understanding the Problem)
2. Skim Part II (just the summaries)
3. Read the decision framework in Part V

**Comprehensive understanding** (3-4 hours):
1. Read straight through Parts I-III
2. Try the PoCs in Part II
3. Review production considerations in Part V

**Deep technical dive** (full day):
- Read everything in order
- Run all the proof-of-concepts
- Explore the appendices and further reading

### Running the Examples

All proof-of-concepts in this book are runnable! You have two options:

**Option 1: Docker (Recommended)**
```bash
# No GHC installation needed!
docker build -t ghc-linker-poc .
docker run --rm ghc-linker-poc ./scripts/run-all-demos.sh
```

**Option 2: Local Installation**
```bash
# Requires GHC ≥9.0, LLVM ≥18
cd poc1-linker-comparison && ./build.sh
cd ../poc2-ffi-integration && ./build.sh
cd ../poc3-grpc-microservices && ./build.sh
```

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

## Repository and Resources

- **GitHub**: [github.com/prasincs/haskell-linker-exploration](https://github.com/prasincs/haskell-linker-exploration)
- **CI/CD**: All examples tested in CI for reproducibility
- **Docker**: Containerized environment for easy experimentation
- **License**: MIT License

If you find this useful, please ⭐ star the repository!

---

## Let's Begin!

Ready to dive in? Start with [Chapter 1: The Original Question](./part-1-understanding/01-original-question.md) to understand what sparked this exploration.

Or jump directly to:
- [PoC 1: Quantifying the Problem](./part-2-proofs/03-poc1-linker-comparison.md) - See the 100+ argument difference
- [PoC 2: FFI Integration](./part-2-proofs/04-poc2-ffi-integration.md) - Call Haskell from C
- [PoC 3: gRPC Alternative](./part-2-proofs/05-poc3-grpc-alternative.md) - Modern microservices approach
- [GHC Architecture](./part-3-deep-dive/06-ghc-architecture.md) - Deep dive into GHC internals
