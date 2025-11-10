# GHC Architecture: A Deep Dive

## Overview

The Glasgow Haskell Compiler (GHC) is one of the most sophisticated production compilers in existence. This document explores its architecture, compilation pipeline, and why it can't be easily replaced or bypassed.

## Table of Contents

- [History and Evolution](#history-and-evolution)
- [The Compilation Pipeline](#the-compilation-pipeline)
- [Intermediate Representations](#intermediate-representations)
- [Backends: NCG vs LLVM](#backends-ncg-vs-llvm)
- [The Driver Model](#the-driver-model)
- [Why GHC Must Control Linking](#why-ghc-must-control-linking)

---

## History and Evolution

### Timeline

| Year | Milestone |
|------|-----------|
| 1989 | GHC project begins at University of Glasgow |
| 1992 | First public release (v0.10) |
| 1992 | Spineless Tagless G-machine paper published |
| 1998 | GHC 4.0: Major rewrite with Core IR |
| 2010 | LLVM backend added as alternative to NCG |
| 2014 | GHC 7.8: Major RTS improvements |
| 2021 | GHC 9.0: ModuleHierarchy and native Apple Silicon support |
| 2024 | GHC 9.10: Continued evolution |

### Why the History Matters

GHC was **designed before**:
- LLVM existed (1989 vs 2003)
- Modern linkers like lld (2011)
- Package managers like Cabal were mature
- Cross-compilation was common

As a result, GHC had to build **all** infrastructure itself:
- Its own intermediate representations
- Its own code generator
- Its own package database
- Its own linker orchestration

This isn't technical debt—it's a **feature**. GHC's control over the entire pipeline enables optimizations that would be impossible otherwise.

---

## The Compilation Pipeline

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                       Source Code (.hs)                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  FRONT END                                                      │
│  ┌────────┐    ┌─────────┐    ┌────────────┐                  │
│  │ Parser │ -> │ Renamer │ -> │ Typechecker│                  │
│  └────────┘    └─────────┘    └────────────┘                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  MIDDLE END (Core IR)                                           │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │  Desugarer   │ -> │ Simplifier   │ -> │  Optimizer   │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                 │
│  Core-to-Core transformations (10+ passes):                    │
│  - Inlining, specialization, strictness analysis               │
│  - Demand analysis, worker-wrapper transformation              │
│  - Common subexpression elimination, constant folding          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  BACK END                                                       │
│  ┌────────┐    ┌──────┐    ┌─────────────────────┐            │
│  │  STG   │ -> │ Cmm  │ -> │ NCG or LLVM Backend │            │
│  └────────┘    └──────┘    └─────────────────────┘            │
│                                    │                            │
│                            ┌───────┴───────┐                   │
│                            ▼               ▼                   │
│                     ┌──────────┐    ┌──────────┐              │
│                     │ Assembly │    │ LLVM IR  │              │
│                     └──────────┘    └──────────┘              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  LINKING                                                        │
│  ┌────────────┐    ┌─────────────────┐    ┌────────────┐      │
│  │ Assembler  │ -> │  GHC Driver     │ -> │  ld/lld    │      │
│  │ (as/llvm)  │    │ (orchestrator)  │    │ (linker)   │      │
│  └────────────┘    └─────────────────┘    └────────────┘      │
└─────────────────────────────────────────────────────────────────┘
```

### Detailed Pipeline Stages

#### 1. Front End: Source to Core

**Parser** (`Parser.y`)
- Reads Haskell source code
- Generates Abstract Syntax Tree (AST)
- Uses Alex/Happy (lexer/parser generators)
- Output: `HsSyn` (Haskell Syntax tree)

**Renamer** (`RnSource.hs`)
- Resolves names and imports
- Builds scope information
- Handles qualified names
- Output: Renamed `HsSyn`

**Typechecker** (`TcModule.hs`)
- Performs type inference (Hindley-Milner + extensions)
- Resolves type classes and instances
- Checks for type errors
- Desugars syntactic sugar
- Output: Typed `HsSyn`

#### 2. Middle End: Core IR

**Core Language**

Core is GHC's central intermediate representation. It's a **tiny, explicitly-typed lambda calculus**:

```haskell
-- Example: map function in Core
map :: forall a b. (a -> b) -> [a] -> [b]
map = \ @a @b (f :: a -> b) (xs :: [a]) ->
  case xs of
    [] -> []
    (:) y ys -> (:) @b (f y) (map @a @b f ys)
```

Core properties:
- **Small**: Only ~10 constructs (lambda, application, case, let, etc.)
- **Explicitly typed**: All types are visible
- **No syntactic sugar**: Everything is desugared
- **Stable**: Optimizer can reason about it easily

**Core-to-Core Optimizations** (10+ passes)

| Pass | Purpose |
|------|---------|
| **Simplifier** | Inlining, beta-reduction, case-of-case |
| **Specializer** | Monomorphizes overloaded functions |
| **Float Out/In** | Moves let-bindings for CSE opportunities |
| **Strictness Analyzer** | Identifies strict functions for unboxing |
| **Demand Analyzer** | Determines which arguments are used |
| **Worker-Wrapper** | Splits functions for better calling conventions |
| **Call Arity** | Optimizes partial applications |
| **CSE** | Common subexpression elimination |
| **Let-floating** | Moves allocations out of loops |

Each pass runs multiple times until a fixed point is reached.

#### 3. Back End: Code Generation

**STG (Spineless Tagless G-machine)**

Core is converted to STG, which is closer to executable code:

```haskell
-- STG version of map
map f xs = case xs of
             []     -> []
             (y:ys) -> let h = f y
                           t = map f ys
                       in h : t
```

STG properties:
- **Explicit closures**: Shows what's captured
- **Lazy by default**: Explicit evaluation with `case`
- **Memory layout**: Represents actual heap objects

**C-- (Cmm)**

STG is converted to C--, a portable assembly language:

```c
// C-- snippet (simplified)
I64[Sp - 8] = stg_upd_frame_info;
I64[Sp - 16] = R1;
Sp = Sp - 16;
R1 = R1 + 16;  // Follow indirection
jump (I64[R1]) [R1];
```

C-- is GHC's lowest-level IR before actual assembly.

**Backends: NCG or LLVM**

From C--, two paths:

1. **Native Code Generator (NCG)** - Default
   - GHC's hand-written code generator
   - Fast compilation
   - Supports x86, x86-64, ARM, AArch64, PowerPC
   - Generates assembly directly

2. **LLVM Backend** - Optional (`-fllvm`)
   - Converts C-- to LLVM IR
   - Slower compilation, better optimization
   - Supports any LLVM target
   - Can use LLVM's optimization passes

---

## Intermediate Representations

### Comparison Table

| IR | Level | Typed? | Purpose |
|----|-------|--------|---------|
| **HsSyn** | High | Yes | Preserve source structure |
| **Core** | High | Explicitly | Optimization, transformation |
| **STG** | Mid | No | Lazy evaluation, closures |
| **C--** | Low | No | Portable assembly |
| **Assembly** | Low | No | Machine code |

### Why Multiple IRs?

Each IR is optimized for different tasks:

- **Core**: High-level transformations (inlining, specialization)
- **STG**: Lazy evaluation and closure conversion
- **C--**: Low-level optimizations and calling conventions
- **Assembly**: Final machine code

This separation of concerns allows GHC to:
- Optimize at multiple levels
- Support multiple backends
- Maintain a stable internal API

---

## Backends: NCG vs LLVM

### Native Code Generator (NCG)

**Pros:**
- ✅ Fast compilation times
- ✅ No external dependencies
- ✅ GHC has full control
- ✅ Better debug info integration
- ✅ Optimized for Haskell's calling conventions

**Cons:**
- ❌ Limited architecture support
- ❌ Fewer low-level optimizations
- ❌ Not as many SIMD optimizations

**When to use:**
- Development builds (fast iteration)
- Common architectures (x86-64, ARM)
- When you need fast compile times

### LLVM Backend

**Pros:**
- ✅ Excellent optimization
- ✅ Supports all LLVM targets
- ✅ SIMD and vectorization
- ✅ Well-maintained by large community

**Cons:**
- ❌ Slower compilation (2-3x)
- ❌ External dependency (requires LLVM toolchain)
- ❌ Sometimes worse for Haskell's calling conventions
- ❌ Larger binaries

**When to use:**
- Production builds (optimize for performance)
- Uncommon architectures (RISC-V, WebAssembly)
- Compute-heavy code (numeric, crypto)

### Benchmarks

Typical compilation time comparison:

```
NCG:  ghc -O2 MyProgram.hs         # 10 seconds
LLVM: ghc -O2 -fllvm MyProgram.hs  # 25 seconds
```

Typical runtime performance:

```
NCG:  ./MyProgram   # 1.00x (baseline)
LLVM: ./MyProgram   # 0.85x (15% faster for numeric code)
```

---

## The Driver Model

### What Is the Driver?

The **GHC driver** (`ghc` executable) orchestrates the entire compilation process:

```
┌──────────────────────────────────────────────┐
│         GHC Driver (ghc command)             │
│                                              │
│  ┌─────────────────────────────────────┐    │
│  │ 1. Parse command-line flags         │    │
│  └─────────────────────────────────────┘    │
│                   │                          │
│                   ▼                          │
│  ┌─────────────────────────────────────┐    │
│  │ 2. Determine module dependencies    │    │
│  └─────────────────────────────────────┘    │
│                   │                          │
│                   ▼                          │
│  ┌─────────────────────────────────────┐    │
│  │ 3. Compile each module              │    │
│  │    (call GHC library)               │    │
│  └─────────────────────────────────────┘    │
│                   │                          │
│                   ▼                          │
│  ┌─────────────────────────────────────┐    │
│  │ 4. Find all package dependencies    │    │
│  │    (query package database)         │    │
│  └─────────────────────────────────────┘    │
│                   │                          │
│                   ▼                          │
│  ┌─────────────────────────────────────┐    │
│  │ 5. Construct linker command         │    │
│  │    - Add RTS libraries              │    │
│  │    - Add package libraries          │    │
│  │    - Add system libraries           │    │
│  │    - Set correct order              │    │
│  └─────────────────────────────────────┘    │
│                   │                          │
│                   ▼                          │
│  ┌─────────────────────────────────────┐    │
│  │ 6. Invoke system linker             │    │
│  │    (ld, gold, lld, etc.)            │    │
│  └─────────────────────────────────────┘    │
└──────────────────────────────────────────────┘
```

### Driver Responsibilities

1. **Dependency Resolution**
   - Parse module imports
   - Build dependency graph
   - Compile in correct order

2. **Package Management**
   - Query package database (`ghc-pkg`)
   - Find installed packages
   - Resolve version constraints

3. **Compilation Orchestration**
   - Call compiler for each module
   - Manage interface files (`.hi`)
   - Handle recompilation checking

4. **Linker Command Construction**
   - Select RTS variant (vanilla, threaded, profiling)
   - Find all package libraries (`.a` or `.so`)
   - Determine link order
   - Add system libraries

5. **External Tool Invocation**
   - Call assembler (`as` or `llc`)
   - Call linker (`ld`, `gold`, `lld`)
   - Handle platform differences

---

## Why GHC Must Control Linking

### The Package Database

GHC maintains a **package database** that tracks:

```haskell
-- Simplified representation
data Package = Package
  { pkgName         :: String
  , pkgVersion      :: Version
  , pkgDependencies :: [PackageId]
  , pkgLibraries    :: [FilePath]      -- .a or .so files
  , pkgIncludeDirs  :: [FilePath]
  , pkgLibDirs      :: [FilePath]
  }
```

Example package entry:

```
name: base
version: 4.17.2.1
depends: ghc-prim-0.9.1, integer-gmp-1.1.2.0
library-dirs: /usr/lib/ghc-9.4.8/base-4.17.2.1
hs-libraries: HSbase-4.17.2.1
```

**Only GHC knows**:
- Where packages are installed
- Which version to use
- What dependencies each package has
- The correct link order

### The Runtime System (RTS)

GHC must link the appropriate RTS variant:

| Variant | Flag | Use Case |
|---------|------|----------|
| Vanilla | (default) | Single-threaded |
| Threaded | `-threaded` | Multi-core parallelism |
| Profiling | `-prof` | Performance profiling |
| Debugging | `-debug` | RTS debugging |
| Dynamic | `-dynamic` | Shared libraries |
| Event log | `-eventlog` | ThreadScope analysis |

Each variant is a **completely different library**. GHC must choose the correct one based on compilation flags.

### Calling Conventions

Haskell uses a **custom calling convention** designed for garbage collection:

```
┌──────────────────────────────────────┐
│     Stack                            │
│  ┌────────────────────┐              │
│  │ Return address     │              │
│  ├────────────────────┤              │
│  │ Info table pointer │ <- Critical! │
│  ├────────────────────┤              │
│  │ Live pointers      │ <- GC needs  │
│  └────────────────────┘              │
└──────────────────────────────────────┘
```

**Info tables** contain metadata for garbage collection:
- Layout of the stack frame
- Which slots contain pointers
- Entry code for the function

The RTS and all Haskell code must agree on this layout. GHC ensures this by:
1. Generating consistent info tables
2. Linking the matching RTS
3. Using the correct calling convention throughout

### Topological Ordering

Dependencies must be linked in the correct order:

```
Your Code
    └─> base
         ├─> ghc-prim
         │    └─> (no deps)
         └─> integer-gmp
              └─> gmp (system)
```

Link order: `YourCode.o base ghc-prim integer-gmp -lgmp`

**Incorrect order causes:**
- Undefined symbol errors
- Duplicate symbol errors
- Incorrect symbol resolution

Only GHC has the full dependency graph to compute this order.

---

## Conclusion

GHC's architecture is the result of 30+ years of evolution and optimization. It's not just a compiler—it's a complete **build system** that:

- Manages dependencies
- Orchestrates compilation
- Selects the appropriate runtime
- Constructs precise linker commands
- Ensures calling convention consistency

This is why you can't just use `lld` to link Haskell code. GHC is the indispensable "general contractor" that knows where all the pieces are and how they fit together.

---

## Further Reading

- [GHC Commentary](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary): Official wiki with implementation details
- [The Architecture of Open Source Applications: GHC](https://aosabook.org/en/v2/ghc.html): High-level architecture overview
- [Core Specification](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler/core-syn-type): Formal specification of Core IR
- [STG Machine Paper](https://www.microsoft.com/en-us/research/publication/implementing-lazy-functional-languages-on-stock-hardware-the-spineless-tagless-g-machine/): Original STG paper
