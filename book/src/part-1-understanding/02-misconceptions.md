# Chapter 2: Two Critical Misconceptions

The [original question](./01-original-question.md) contained two separate misconceptions that, when combined, led to the wrong conclusion. Let's break them down.

## Misconception 1: GHC = LLVM

### The Misconception
*"Haskell uses the LLVM backend, so it compiles through LLVM like Rust does."*

### The Reality

**GHC's *default* backend is NOT LLVM.**

GHC has its own highly-optimized **Native Code Generator (NCG)** that it uses for most common architectures (like x86-64 and AArch64). The LLVM backend (`-fllvm`) is an *option* that can provide:

- Extra optimizations for certain code patterns
- Support for platforms the NCG doesn't target
- Alternative optimization strategies

### Why This Matters

When you run:

```bash
$ ghc Hello.hs
```

By default, GHC:
1. Parses and type-checks your code
2. Desugars to Core IR
3. Optimizes Core (multiple passes)
4. Converts to STG (Spineless Tagless G-machine)
5. Converts to C-- (low-level IR)
6. **Uses NCG** to generate assembly
7. Assembles to object file
8. **Links using GHC as driver**

With `-fllvm`:

```bash
$ ghc -fllvm Hello.hs
```

Steps 1-5 are the same, but then:
6. **Emits LLVM IR** instead of assembly
7. Passes to LLVM for optimization and code generation
8. LLVM produces object file
9. **Still links using GHC as driver**

**Key insight**: Using LLVM doesn't change the linking requirements at all!

---

## Misconception 2: Object Files Are All You Need

### The Misconception
*"If Haskell compiles to `.o` files (even via LLVM), I should be able to link them with any linker like lld or gold."*

### The Reality

**Object files are necessary but not sufficient.**

Let's compare what different languages need at link time:

### C "Hello, World"

**Source code**:
```c
#include <stdio.h>

int main() {
    printf("Hello, World!\n");
    return 0;
}
```

**What the linker needs**:
- Your object file: `main.o`
- C standard library: `libc` (already known to the system linker)
- Startup code: `crt0.o` (already known to the system linker)

**Link command**:
```bash
$ ld -o hello main.o -lc
# Simple! About 5-7 arguments
```

### Haskell "Hello, World"

**Source code**:
```haskell
main :: IO ()
main = putStrLn "Hello, Haskell!"
```

**What the linker needs**:
1. **Your object file**: `Main.o`
2. **Haskell Runtime System** (~5MB):
   - Garbage collector
   - Green thread scheduler
   - Heap manager
   - Exception handler
   - FFI support
3. **Boot libraries** (10+ packages):
   - `base` (700+ modules)
   - `ghc-prim` (primitive operations)
   - `integer-gmp` (big integers)
   - `array`, `deepseq`, `template-haskell`, etc.
4. **Startup code**:
   - RTS initialization
   - Haskell calling convention setup
   - Exception handler registration

**Link command**:
```bash
$ ld -o hello Main.o ???
# WHERE ARE ALL THESE LIBRARIES?
# WHAT ORDER DO THEY GO IN?
# WHICH RTS VARIANT (threaded? profiling? dynamic?)?
```

A naive linker has no idea!

---

## The Two Requirements

This reveals that GHC's massive linker command provides two categories of "secret ingredients":

### Requirement 1: The "Life Support" (Runtime System)

| Component | Purpose | Size |
|-----------|---------|------|
| **Garbage Collector** | Manages memory automatically | ~1.5 MB |
| **Scheduler** | Manages lightweight green threads | ~1 MB |
| **Heap Manager** | Manages lazy evaluation and thunks | ~1 MB |
| **Exception Handler** | Implements Haskell's exception model | ~500 KB |
| **FFI Support** | Bridges Haskell and C code | ~500 KB |
| **Other** | Profiling, debugging, etc. | ~500 KB |
| **Total** | Complete Runtime System | **~5 MB** |

This is all in `libHSrts.a` and its helper files. **Without it, no Haskell code can execute.**

### Requirement 2: The "Package Army" (Dependencies)

**C "Hello, World"** dependency tree:
```
main.o
└── libc
    └── kernel syscalls
```

**Haskell "Hello, World"** dependency tree:
```
Main.o
├── base (standard library)
│   ├── ghc-prim (primitives)
│   ├── integer-gmp (big integers)
│   └── deepseq (strictness)
├── array (arrays)
├── bytestring (efficient strings)
└── ... (10+ more packages)
    └── libHSrts.a (Runtime System)
        └── libc, libm, libpthread, libgmp
            └── kernel syscalls
```

GHC's job as a driver is to be your **package manager** at link time. It:
1. Tracks this entire dependency graph
2. Finds all the libraries on your system
3. Passes them to the linker in the **correct topological order**
4. Adds platform-specific flags and calling conventions

---

## Visual Comparison

Let's visualize the architecture:

### C Program Structure
```
┌────────────────────────────────────┐
│         Your C Program             │
│         (main.c)                   │
├────────────────────────────────────┤
│      C Standard Library (libc)     │
├────────────────────────────────────┤
│      Operating System              │
└────────────────────────────────────┘

Linking: ld main.o -lc
```

### Haskell Program Structure
```
┌────────────────────────────────────┐
│      Your Haskell Code             │
│      (Main.hs)                     │
├────────────────────────────────────┤
│   Haskell Standard Library (base)  │
│   ├─ ghc-prim                      │
│   ├─ integer-gmp                   │
│   └─ ... (10+ packages)            │
├────────────────────────────────────┤
│   Haskell Runtime System (RTS)     │
│   ┌──────────┬──────────┬────────┐ │
│   │    GC    │Scheduler │  Heap  │ │
│   └──────────┴──────────┴────────┘ │
├────────────────────────────────────┤
│      C Standard Library (libc)     │
├────────────────────────────────────┤
│      Operating System              │
└────────────────────────────────────┘

Linking: ghc Main.o [... 140+ arguments ...]
```

---

## Why This Matters

Understanding these two misconceptions is crucial because:

1. **You can't skip GHC at link time** - even if you use LLVM
2. **You can't treat Haskell like C** - the runtime requirements are fundamentally different
3. **FFI still requires GHC** - calling Haskell from C still needs the RTS
4. **Modern alternatives exist** - gRPC microservices can avoid these complexities

---

## Next Steps

Now that we understand *why* naive linking fails, let's see it in action!

In the next chapter, we'll:
- **Quantify** the difference (7 arguments vs 140+ arguments)
- **See** the 100+ undefined reference errors
- **Understand** what GHC is actually doing

Ready? Let's move to [PoC 1: Quantifying the Problem →](../part-2-proofs/03-poc1-linker-comparison.md)

---

## Quick Navigation

- **Previous**: [← The Original Question](./01-original-question.md)
- **Next**: [PoC 1: Quantifying the Problem →](../part-2-proofs/03-poc1-linker-comparison.md)
- **Deep Dive**: [GHC Architecture →](../part-3-deep-dive/06-ghc-architecture.md)
