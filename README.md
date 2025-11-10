# Why Your Linker Can't Link Haskell Code (And Why GHC Isn't Just a Compiler)

A deep technical exploration into how Haskell programs are really built, why modern linkers like lld can't link Haskell code on their own, and what makes GHC an indispensable "general contractor" for your Haskell applications.

---

## Table of Contents

- [The Original Question](#the-original-question)
- [Two Critical Misconceptions](#two-critical-misconceptions)
- [PoC 1: Quantifying the Problem](#poc-1-quantifying-the-problem)
- [The Two Requirements](#the-two-requirements)
- [PoC 2: FFI and the "Manual Life Support"](#poc-2-ffi-and-the-manual-life-support)
- [GHC: A 30-Year Architectural Marvel](#ghc-a-30-year-architectural-marvel)
- [Running the Examples](#running-the-examples)
- [Deep Dive Documentation](#deep-dive-documentation)
- [Key Takeaways](#key-takeaways)

---

## The Original Question

A while ago, I had a conversation that kicked off this deep dive into how Haskell is *actually* put together:

> *"Since many modern languages (like Rust and Haskell) can use an LLVM backend, shouldn't they all just compile down to a common format? And if they do, can't we just use a fast, modern linker like lld to link them all together?"*

My assumption was simple: **Haskell Source → LLVM IR → Object File (.o)**. If that's true, I should be able to just grab all my `.o` files and feed them to lld.

**This assumption is wrong in two different and important ways.** And digging into *why* reveals the secret role of the Glasgow Haskell Compiler (GHC) and the "special sauce" that makes a Haskell program run.

---

## Two Critical Misconceptions

### Misconception 1: GHC = LLVM

First, GHC's *default* backend is **not** LLVM. GHC has its own highly-optimized **Native Code Generator (NCG)** that it uses for most common architectures (like x86-64 and AArch64). The LLVM backend (`-fllvm`) is an *option* that can provide extra optimizations or target platforms the NCG doesn't support.

But this just leads to the next, more important question:

### Misconception 2: Object Files Are All You Need

*Even if I use `-fllvm`, why can't I just link the resulting object files myself?*

The answer reveals something fundamental about what GHC really does.

---

## PoC 1: Quantifying the Problem

Instead of just talking about it, let's **measure** it. I created a simple proof-of-concept that compares a naive linking attempt with what GHC actually does.

### The Setup

1. **Simple Haskell program** ([Hello.hs](./Hello.hs)):
   ```haskell
   main :: IO ()
   main = putStrLn "Hello, Haskell!"
   ```

2. **Compile to object file** using LLVM backend:
   ```bash
   ghc -fllvm -c Hello.hs -o Hello.o
   ```

3. **Attempt 1 (Naive)**: Try linking with lld directly
   ```bash
   lld -o hello_fail Hello.o -lc -lpthread -ldl
   ```

### The Result: Spectacular Failure

```
undefined reference: base_GHCziTopHandler_flushStdHandles_closure
undefined reference: base_GHCziIOziHandleziFD_stdout_closure
undefined reference: ghczmprim_GHCziTypes_True_closure
undefined reference: base_GHCziShow_zdfShowChar_closure
undefined reference: stg_ap_0_fast
[... and many, many more]
```

The linker is missing:
- All Haskell **base library** functions
- The **STG** (Spineless Tagless G-machine) implementation
- The entire **Runtime System (RTS)**

### Attempt 2: The GHC Way

```bash
ghc -v -fllvm Hello.hs -o hello_success
```

**GHC succeeds** by constructing a *massive* linker command. In my test:
- **Naive command**: 7 arguments
- **GHC's command**: **140+ arguments**

Here's what GHC is actually linking (abbreviated):

```bash
/usr/bin/ld -o hello_success
  /usr/lib/ghc-9.4.8/rts/lib/crt0.o                          # Startup code
  ... [tons of .o files] ...
  Hello.o                                                     # Your code
  ... [~20 more .o files] ...
  /usr/lib/ghc-9.4.8/base-4.17.2.1/libHSbase-4.17.2.1.a      # Standard library
  /usr/lib/ghc-9.4.8/integer-gmp-1.1.2.0/libHSinteger-gmp-1.1.2.0.a
  /usr/lib/ghc-9.4.8/ghc-prim-0.9.1/libHSghc-prim-0.9.1.a
  ... [10+ more Haskell libraries] ...
  /usr/lib/ghc-9.4.8/rts/lib/libHSrts.a                      # The Runtime System!
  ... [15+ more RTS files] ...
  -lgmp -ldl -lpthread -lm -lc                               # System libraries
```

**See it for yourself**: [poc1-linker-comparison/](./poc1-linker-comparison/)

---

## The Two Requirements

GHC's massive linker command provides two categories of "secret ingredients" that a naive linker knows nothing about:

### Requirement 1: The "Life Support" (Runtime System)

A C function is simple: you call it, it runs on the stack, it returns.

A **Haskell function is a managed entity**. It needs an entire ecosystem:

| Component | Purpose |
|-----------|---------|
| **Garbage Collector** | Manages memory automatically |
| **Scheduler** | Manages lightweight green threads |
| **Heap** | Manages lazy evaluation and thunks |
| **Exception Handler** | Implements Haskell's exception model |
| **FFI Support** | Bridges Haskell and C code |

This entire ecosystem is the **Haskell Runtime System (RTS)**, found in `libHSrts.a` and its helper files. Without it, no Haskell code can execute.

```
┌─────────────────────────────────────┐
│        Your Haskell Code            │
├─────────────────────────────────────┤
│     Haskell Runtime System (RTS)    │
│  ┌─────────┬─────────┬──────────┐  │
│  │   GC    │Scheduler│   Heap   │  │
│  └─────────┴─────────┴──────────┘  │
├─────────────────────────────────────┤
│          Operating System           │
└─────────────────────────────────────┘
```

### Requirement 2: The "Package Army" (Dependencies)

**C "Hello, World"**: Links against `libc`. Done.

**Haskell "Hello, World"**: Links against a *massive* dependency tree:

- `base` (The standard Prelude)
- `ghc-prim` (Compiler primitives)
- `integer-gmp` (Arbitrary-precision integers)
- `array`, `deepseq`, `template-haskell`, and [many more](./docs/linking-process.md#haskell-boot-packages)

GHC's second job as a driver is to be your **package manager**. It tracks this entire dependency graph and passes it to the linker in the correct topological order.

---

## PoC 2: FFI and the "Manual Life Support"

This context *finally* explains the weird parts of Haskell's **Foreign Function Interface (FFI)** when calling Haskell from C.

### The Question

If Haskell compiles to object files, why can't I just link them with my C program using gcc or clang?

### The Example

**Haskell Library** ([MyLib.hs](./poc2-ffi-integration/MyLib.hs)):
```haskell
{-# LANGUAGE ForeignFunctionInterface #-}

foreign export ccall hs_fib :: CInt -> CInt

hs_fib :: CInt -> CInt
hs_fib n = fromIntegral $ fibonacci (fromIntegral n)
```

**C Program** ([main.c](./poc2-ffi-integration/main.c)):
```c
#include "HsFFI.h"
#include "MyLib_stub.h"

int main(int argc, char *argv[]) {
    hs_init(&argc, &argv);     // Start the RTS!

    int result = hs_fib(10);
    printf("fib(10) = %d\n", result);

    hs_exit();                 // Stop the RTS!
    return 0;
}
```

### Compilation: Both Work Fine

```bash
ghc -c MyLib.hs     # Creates MyLib.o, MyLib_stub.h
cc -c main.c        # Creates main.o
```

### Linking: Only GHC Works

**Attempt with cc/lld** (FAILS):
```bash
cc -o program main.o MyLib.o -lpthread -ldl
# undefined reference to `stg_split_marker'
# undefined reference to `base_GHCziIOziHandleziFD_stdout_closure'
# [... hundreds more errors]
```

**Attempt with GHC** (SUCCEEDS):
```bash
ghc -no-hs-main -o program main.o MyLib.o
./program
# Haskell calculated fib(10) = 55
```

### Why This Makes Sense Now

When you link a Haskell library, it **still needs its "life support"**—the RTS. Since there's no Haskell `main` function to start it automatically, you (the C programmer) must:

1. **Manually start the RTS**: `hs_init(&argc, &argv)`
2. **Call your Haskell functions**: `hs_fib(10)`
3. **Manually stop the RTS**: `hs_exit()`

And you **still use GHC as the linker** because:
- GHC knows where to find `libHSrts.a`
- GHC knows all 100+ dependencies of `MyLib`
- GHC can construct the proper 140-argument linker command

The `-no-hs-main` flag tells GHC: *"I'm providing my own C `main()`, but please find all the Haskell materials and link them correctly."*

**See it for yourself**: [poc2-ffi-integration/](./poc2-ffi-integration/)

---

## GHC: A 30-Year Architectural Marvel

Part of the confusion stems from GHC's sheer scale and history. **GHC is not a new, sleek compiler** built from scratch in the last decade. It's a massive, **30+ year-old research project** that has evolved into a production-grade industrial compiler.

### The Pipeline

A fantastic snapshot of its internal architecture is in [*The Architecture of Open Source Applications, Vol. 2*](https://aosabook.org/en/v2/ghc.html). The core pipeline:

```
Source Code
    ↓
Parser → Renamer → Typechecker
    ↓
Core IR (desugaring)
    ↓
Core-to-Core Optimizations (10+ passes)
    ↓
STG (Spineless Tagless G-machine)
    ↓
C-- (Low-level IR)
    ↓
Backend (NCG or LLVM) → Assembly/Object Code
    ↓
Linker Driver (GHC orchestrates ld/lld/gold)
    ↓
Executable
```

### Why GHC Is a "Driver"

GHC was designed long before LLVM was a standard. It had to manage *everything* itself:
- Compilation
- Optimization
- Code generation
- **Linking with the RTS and all dependencies**

This "monolithic-by-design" approach is why GHC can't be easily replaced. It's not just a compiler—it's the **general contractor** that understands the complex blueprints of a Haskell application.

For more details, see [docs/ghc-architecture.md](./docs/ghc-architecture.md)

---

## Running the Examples

### Quick Start with Docker (No GHC Installation Required)

```bash
# 1. Clone this repository
git clone https://github.com/yourusername/haskell-linker-exploration.git
cd haskell-linker-exploration

# 2. Build the Docker image (takes a few minutes)
docker build -t ghc-linker-poc .

# 3. Run PoC 1: Linker Command Comparison
docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh

# 4. Run PoC 2: FFI Integration (interactive)
docker run --rm -it ghc-linker-poc ./poc2-ffi-integration/build.sh

# 5. Or run all demos
docker run --rm ghc-linker-poc ./scripts/run-all-demos.sh
```

### With Docker Compose

```bash
# Run specific PoC
docker-compose run poc1
docker-compose run poc2

# Run all
docker-compose run all-demos
```

### Local Installation

If you have GHC (≥9.0), LLVM, and lld installed:

```bash
# PoC 1
cd poc1-linker-comparison
./build.sh

# PoC 2
cd poc2-ffi-integration
./build.sh
```

---

## Deep Dive Documentation

This repository includes comprehensive technical documentation:

### Architecture & Internals
- **[GHC Architecture](./docs/ghc-architecture.md)**: Deep dive into GHC's compilation pipeline, Core IR, and backends
- **[Runtime System Explained](./docs/rts-explained.md)**: How the garbage collector, scheduler, and heap management work
- **[The Linking Process](./docs/linking-process.md)**: What actually happens when GHC links your program

### Practical Guides
- **[FFI Guide](./docs/ffi-guide.md)**: Complete guide to the Foreign Function Interface
- **[Calling Conventions](./docs/linking-process.md#calling-conventions)**: How Haskell functions interact with C

### Visual Explanations
- **[GHC Pipeline Diagram](./diagrams/ghc-pipeline.md)**: Mermaid flowchart of compilation stages
- **[Linking Comparison](./diagrams/linking-comparison.md)**: Visual comparison of naive vs. GHC linking
- **[RTS Architecture](./diagrams/rts-architecture.md)**: Component diagram of the Runtime System

---

## Key Takeaways

### 1. GHC Is More Than a Compiler

GHC is a **compiler driver** and **build orchestrator**. It:
- Compiles your source code
- Manages the entire dependency graph
- Links the Runtime System
- Constructs the proper linker command
- Delegates to a system linker (ld, gold, or lld)

### 2. You Can Choose Your Linker, Not Replace GHC

You **can** (and should!) tell GHC to use a faster linker:
```bash
ghc -fllvm -pgml=lld MyProgram.hs  # Use lld as the sub-contractor
```

You **cannot** skip GHC entirely:
```bash
lld -o MyProgram Hello.o  # Missing RTS, base, primitives, etc.
```

### 3. The Haskell Runtime System Is Essential

Every Haskell program needs:
- **Garbage collection** for memory management
- **Green thread scheduler** for lightweight concurrency
- **Lazy evaluation heap** for thunks and closures
- **Exception handling** infrastructure
- **FFI bridge** for C interop

This is all in `libHSrts.a`, which weighs several megabytes and is the "life support" for your code.

### 4. Boot Libraries Are a Massive Dependency

A minimal "Hello, World" links against:
- `base` (700+ modules)
- `ghc-prim` (primitive operations)
- `integer-gmp` (arbitrary-precision math)
- Plus: `array`, `deepseq`, `template-haskell`, and more

GHC tracks all of this automatically. A naive linker doesn't even know these exist.

### 5. FFI Reveals the Truth

The Foreign Function Interface makes this crystal clear:
- `hs_init()` and `hs_exit()` manually start/stop the RTS
- You still use `ghc -no-hs-main` to link, even with a C `main()`
- This is because GHC is the only tool that knows where all the Haskell "materials" are

---

## Contributing

Found an error? Have a suggestion? **Pull requests and issues welcome!**

This repository is meant to be an educational resource. If you have ideas for additional PoCs, better explanations, or more visualizations, please contribute.

---

## Further Reading

### Official Documentation
- [GHC User's Guide](https://downloads.haskell.org/ghc/latest/docs/users_guide/)
- [GHC Commentary](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary)
- [The Architecture of Open Source Applications: GHC](https://aosabook.org/en/v2/ghc.html)

### Academic Papers
- [The Spineless Tagless G-machine](https://www.microsoft.com/en-us/research/wp-content/uploads/1992/04/spineless-tagless-gmachine.pdf) (Simon Peyton Jones, 1992)
- [A History of Haskell: Being Lazy With Class](https://www.microsoft.com/en-us/research/publication/a-history-of-haskell-being-lazy-with-class/) (2007)
- [Implementing Lazy Functional Languages on Stock Hardware](https://www.microsoft.com/en-us/research/publication/implementing-lazy-functional-languages-on-stock-hardware-the-spineless-tagless-g-machine/) (1992)

### Related Projects
- [LLVM](https://llvm.org/) - The optional backend GHC can use
- [lld](https://lld.llvm.org/) - The LLVM linker
- [Cabal](https://www.haskell.org/cabal/) - Haskell's build system and package manager

---

## License

This repository is released under the MIT License. See [LICENSE](./LICENSE) for details.

---

## Acknowledgments

Thanks to:
- The GHC team for 30+ years of incredible work
- Dmitrii Kovanikov and others who helped clarify these concepts
- The Haskell community for their patience with my questions

---

**Author**: Prasanna
**Repository**: https://github.com/yourusername/haskell-linker-exploration
**Blog Post Date**: 2025

If you found this useful, please star the repository and share it with others learning about compilers and linkers!
