# Chapter 6: GHC Architecture

## A 30-Year Architectural Marvel

Part of the confusion about why GHC must control linking stems from GHC's sheer scale and history. **GHC is not a new, sleek compiler** built from scratch in the last decade. It's a massive, **30+ year-old research project** that has evolved into a production-grade industrial compiler.

## Historical Timeline

| Year | Milestone |
|------|-----------|
| **1989** | GHC project begins at University of Glasgow |
| **1992** | First public release (v0.10) + STG machine paper |
| **1998** | GHC 4.0: Major rewrite with Core IR |
| **2010** | LLVM backend added as alternative to NCG |
| **2014** | GHC 7.8: Major RTS improvements for parallelism |
| **2021** | GHC 9.0: Module hierarchy and Apple Silicon support |
| **2024** | GHC 9.10: Continued evolution |

### Why History Matters

GHC was **designed before**:
- LLVM existed (GHC: 1989, LLVM: 2003)
- Modern linkers like lld (2011)
- Package managers were mature
- Cross-compilation was common

As a result, GHC had to build **all** infrastructure itself:
- Its own intermediate representations
- Its own code generator
- Its own package database
- Its own linker orchestration

This isn't technical debt—it's a **feature**. GHC's control over the entire pipeline enables optimizations that would be impossible otherwise.

## The Compilation Pipeline

### High-Level Overview

```
Source Code (.hs)
    │
    ▼
┌─────────────────────────┐
│  FRONT END              │
│  Parser → Renamer →     │
│  Typechecker            │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  MIDDLE END (Core IR)   │
│  Desugaring →           │
│  Simplification →       │
│  Optimization (10+      │
│  passes)                │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  BACK END               │
│  STG → C-- →            │
│  NCG or LLVM            │
└──────────┬──────────────┘
           │
           ▼
┌─────────────────────────┐
│  LINKING                │
│  GHC Driver orchestrates│
│  ld/lld/gold            │
└─────────────────────────┘
           │
           ▼
        Executable
```

Let's explore each stage!

## Front End: Parsing and Type Checking

### Parser

Converts source code to an Abstract Syntax Tree (AST):

```haskell
-- Source
fibonacci :: Int -> Int
fibonacci 0 = 0
fibonacci 1 = 1
fibonacci n = fibonacci (n-1) + fibonacci (n-2)

-- AST (simplified)
FunBind { fun_id = "fibonacci"
        , fun_matches = [
            Match { pattern = [LitPat 0]
                  , rhs = LitExpr 0 }
          , Match { pattern = [LitPat 1]
                  , rhs = LitExpr 1 }
          , Match { pattern = [VarPat "n"]
                  , rhs = App (App (Var "+")
                                   (App (Var "fibonacci")
                                        (App (App (Var "-") (Var "n"))
                                             (LitExpr 1))))
                              (App (Var "fibonacci")
                                   (App (App (Var "-") (Var "n"))
                                        (LitExpr 2))))
          }
        ]
        }
```

### Renamer

Resolves names and scope:
- Converts user-written names to unique identifiers
- Resolves imports and exports
- Catches name errors

### Typechecker

Performs **type inference** and **type checking**:
- Uses Hindley-Milner with extensions
- Resolves type classes
- Generates type constraints
- Reports type errors

This is where GHC's famous type errors come from!

## Middle End: Core IR

### What Is Core?

**Core** is GHC's primary intermediate representation. It's a small, explicitly-typed functional language based on System FC (a variant of System F).

**Key properties:**
- ✅ Explicitly typed (no type inference needed)
- ✅ Small language (~10 constructors)
- ✅ Easy to analyze and transform
- ✅ Preserves type information

### Example: Desugaring to Core

```haskell
-- Original Haskell
map f [] = []
map f (x:xs) = f x : map f xs

-- Desugared to Core (simplified)
map :: forall a b. (a -> b) -> [a] -> [b]
map = /\a b -> \f xs ->
  case xs of
    [] -> []
    : x xs' -> : @b (f @a x) (map @a @b f xs')
```

Note:
- `/\a b` is type abstraction (type lambda)
- `@a` is type application
- Constructors like `:` and `[]` are explicit

### Core-to-Core Transformations

GHC performs **10+ optimization passes** on Core:

| Pass | Purpose |
|------|---------|
| **Inlining** | Replace function calls with function bodies |
| **Specialization** | Create specialized versions for specific types |
| **Strictness analysis** | Determine which arguments are always evaluated |
| **Worker-wrapper** | Split functions into strict worker + lazy wrapper |
| **Common subexpression elimination** | Share computation |
| **Float out/in** | Move expressions for better optimization |
| **Demand analysis** | Determine which values are needed |

These transformations are **why GHC produces fast code**.

## Back End: Code Generation

### Step 1: STG (Spineless Tagless G-machine)

Core is converted to **STG**, a lower-level representation designed for lazy evaluation:

```
STG is the "abstract machine" for Haskell
┌────────────────────────────────────┐
│  STG Machine                       │
│  ┌──────────┐  ┌──────────┐       │
│  │  Code    │  │   Heap   │       │
│  │  (thunks)│  │(closures)│       │
│  └──────────┘  └──────────┘       │
│        │              │            │
│        └──────┬───────┘            │
│               ▼                    │
│         ┌──────────┐               │
│         │ Stack    │               │
│         └──────────┘               │
└────────────────────────────────────┘
```

**STG features:**
- Closure representation
- Thunks (unevaluated expressions)
- Strict vs lazy evaluation
- Info tables (metadata about heap objects)

This is where Haskell's lazy evaluation semantics are made explicit!

### Step 2: C-- (C minus minus)

STG is converted to **C--**, a low-level imperative language:

```c
// C-- (simplified)
fibonacci_info:
    if (R1 == 0) {
        R1 = 0;
        return;
    }
    if (R1 == 1) {
        R1 = 1;
        return;
    }
    // Allocate closure for fibonacci(n-1)
    Hp = Hp + 16;
    ...
```

**C-- features:**
- Registers (R1, R2, ...)
- Heap pointer (Hp)
- Stack pointer (Sp)
- Explicit heap allocation
- Jumps (no calls!)

This is the last portable IR. After this, we go to machine code.

### Step 3: Backend Selection

GHC has **two backends**:

#### Native Code Generator (NCG) - Default

```
C-- → Assembly (x86-64, AArch64, etc.)
```

**Pros:**
- ✅ Fast compilation
- ✅ Good code quality
- ✅ No external dependencies

**Cons:**
- ⚠️ Limited platform support
- ⚠️ Fewer optimizations than LLVM

#### LLVM Backend - Optional (`-fllvm`)

```
C-- → LLVM IR → LLVM optimizations → Assembly
```

**Pros:**
- ✅ LLVM's powerful optimizations
- ✅ More platform targets

**Cons:**
- ⚠️ Slower compilation
- ⚠️ Requires LLVM installed
- ⚠️ Sometimes worse code than NCG!

## The Driver Model

### GHC as an Orchestrator

GHC isn't just a compiler—it's a **driver** that orchestrates multiple tools:

```
┌──────────────────────────────────────┐
│         GHC Driver                   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 1. Compile .hs → .o          │   │
│  │    - Parser                  │   │
│  │    - Typechecker             │   │
│  │    - Optimizer               │   │
│  │    - Code generator          │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 2. Find Dependencies         │   │
│  │    - Read package database   │   │
│  │    - Resolve imports         │   │
│  │    - Topological sort        │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 3. Construct Link Command    │   │
│  │    - Add RTS libraries       │   │
│  │    - Add boot packages       │   │
│  │    - Add user packages       │   │
│  │    - Set linker flags        │   │
│  └──────────────────────────────┘   │
│                                      │
│  ┌──────────────────────────────┐   │
│  │ 4. Invoke System Linker      │   │
│  │    - ld (default on Linux)   │   │
│  │    - gold                    │   │
│  │    - lld                     │   │
│  └──────────────────────────────┘   │
└──────────────────────────────────────┘
```

You **can** tell GHC which linker to use:

```bash
$ ghc -fuse-ld=lld Hello.hs   # Use lld
$ ghc -fuse-ld=gold Hello.hs  # Use gold
```

But you **cannot** skip GHC's orchestration!

## Why GHC Must Control Linking

### 1. Package Database

GHC maintains a **package database** that tracks:
- All installed packages
- Their dependencies
- Where their libraries are located
- What flags they need

```bash
$ ghc-pkg list
/usr/lib/ghc-9.4.8/package.conf.d
    array-0.5.4.0
    base-4.17.2.1
    deepseq-1.4.8.0
    ghc-prim-0.9.1
    integer-gmp-1.1.2.0
    ...
```

A naive linker doesn't know this database exists!

### 2. Complex Dependencies

Even a simple program has a complex dependency graph:

```
Main.o
 ├─ base
 │   ├─ ghc-prim
 │   ├─ integer-gmp
 │   │   └─ gmp (C library)
 │   └─ deepseq
 ├─ array
 └─ RTS
     ├─ libHSrts.a
     ├─ libffi
     ├─ libpthread
     ├─ libdl
     └─ libm
```

GHC knows this graph and can generate the correct linker command.

### 3. Platform-Specific Handling

Different platforms need different flags:

| Platform | Requirements |
|----------|--------------|
| **Linux** | `-ldl -lpthread` |
| **macOS** | `-framework CoreFoundation` |
| **Windows** | `-lkernel32 -lmsvcrt` |
| **FreeBSD** | `-lexecinfo` |

GHC handles all of this automatically.

### 4. RTS Variants

The RTS comes in multiple variants:

| Variant | Flag | Use Case |
|---------|------|----------|
| **Default** | (none) | Single-threaded |
| **Threaded** | `-threaded` | Parallel/concurrent programs |
| **Profiling** | `-prof` | Performance profiling |
| **Dynamic** | `-dynamic` | Shared libraries |
| **Debug** | `-debug` | Debugging |

Each needs different linking! GHC selects the right one based on your flags.

## Comparison: GHC vs Other Compilers

| Compiler | Pipeline Control | Linking |
|----------|-----------------|---------|
| **GHC** | Full (parser to linker) | Must orchestrate |
| **rustc** | Full (parser to linker) | Can use system linker |
| **clang** | Full (parser to linker) | Can use system linker |
| **ghc** | Full (parser to linker) | **Must use GHC driver** |

**Why is Haskell different?**
- Requires Runtime System (~5MB)
- Complex package dependencies
- Multiple RTS variants
- FFI support infrastructure

## Further Reading

This chapter provides an overview. For deeper exploration:

- **The Architecture of Open Source Applications: GHC** - [https://aosabook.org/en/v2/ghc.html](https://aosabook.org/en/v2/ghc.html)
- **GHC Commentary** - Official internal documentation
- **Full documentation**: [`../../docs/ghc-architecture.md`](../../docs/ghc-architecture.md)

---

## Summary

Key takeaways:
1. ✅ GHC is a **30+ year old** architectural marvel
2. ✅ Uses multiple **intermediate representations** (Core, STG, C--)
3. ✅ Has **two backends** (NCG default, LLVM optional)
4. ✅ Acts as a **driver** that orchestrates the entire build
5. ✅ Must control linking due to **RTS, packages, and platform specifics**

**Next**: Let's dive into the [Runtime System →](./07-runtime-system.md)

---

## Quick Navigation

- **Previous**: [← PoC 3: gRPC Alternative](../part-2-proofs/05-poc3-grpc-alternative.md)
- **Next**: [The Runtime System →](./07-runtime-system.md)
- **Related**: [The Linking Process →](./08-linking-process.md)
