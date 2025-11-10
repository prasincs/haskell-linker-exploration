# The GHC Linking Process: A Deep Dive

## Overview

Linking is the final stage of building a Haskell program. It combines compiled object files, libraries, and the runtime system into a single executable. This document explains what happens during linking, why GHC must orchestrate it, and what makes Haskell linking different from C/C++.

## Table of Contents

- [Linking Basics](#linking-basics)
- [What GHC Links](#what-ghc-links)
- [The Linking Command](#the-linking-command)
- [Haskell Boot Packages](#haskell-boot-packages)
- [Calling Conventions](#calling-conventions)
- [Link Order and Dependencies](#link-order-and-dependencies)
- [Dynamic vs Static Linking](#dynamic-vs-static-linking)
- [Choosing Your System Linker](#choosing-your-system-linker)

---

## Linking Basics

### What Is Linking?

**Linking** is the process of combining multiple object files (`.o`) and libraries (`.a` or `.so`) into a single executable program. The linker:

1. **Resolves symbols**: Matches function calls to their definitions
2. **Combines sections**: Merges code and data sections from different files
3. **Relocates addresses**: Adjusts addresses to final memory locations
4. **Generates executable**: Creates the final binary file

### C Linking (Simple)

```bash
# Compile C source to object file
gcc -c hello.c -o hello.o

# Link object file to executable
gcc hello.o -o hello
# The gcc driver automatically adds:
# - C runtime startup code (crt0.o, crti.o, crtn.o)
# - C standard library (libc)
# - Dynamic linker support
```

**Result**: A working C program with minimal dependencies.

### Haskell Linking (Complex)

```bash
# Compile Haskell source to object file
ghc -c Hello.hs -o Hello.o

# Link object file to executable
ghc Hello.o -o hello
# GHC must add:
# - Haskell Runtime System (libHSrts.a)
# - Base library (libHSbase-4.x.x.a)
# - GHC primitives (libHSghc-prim-0.x.x.a)
# - Integer library (libHSinteger-gmp-1.x.x.a)
# - 10+ more boot libraries
# - System libraries (libgmp, libm, libc, libpthread, libdl)
# - Proper initialization code
```

**Result**: A working Haskell program with a complex dependency graph.

---

## What GHC Links

### 1. Your Code

```
Your compiled modules:
├── Main.o
├── MyModule.o
└── Utils.o
```

### 2. The Runtime System (RTS)

The RTS is the foundation of every Haskell program:

```
RTS Components:
├── libHSrts.a (or libHSrts_thr.a, etc.)
├── Garbage collector
├── Thread scheduler
├── Heap management
├── Exception handling
├── FFI support
└── Profiling infrastructure
```

**RTS Variants**:
- `libHSrts.a` - Single-threaded (default)
- `libHSrts_thr.a` - Multi-threaded (`-threaded`)
- `libHSrts_p.a` - Profiling (`-prof`)
- `libHSrts_debug.a` - Debug (`-debug`)
- `libHSrts_l.a` - Event logging (`-eventlog`)

### 3. Haskell Boot Libraries

These are the standard libraries that ship with GHC:

| Library | Purpose | Typical Size |
|---------|---------|--------------|
| **base** | Standard Prelude, I/O, data structures | ~10 MB |
| **ghc-prim** | Primitive operations, unboxed types | ~1 MB |
| **integer-gmp** | Arbitrary-precision integers | ~500 KB |
| **array** | Mutable and immutable arrays | ~500 KB |
| **deepseq** | Deep evaluation strategies | ~100 KB |
| **bytestring** | Efficient byte arrays | ~1 MB |
| **text** | Unicode text | ~2 MB |
| **containers** | Sets, maps, sequences | ~2 MB |
| **template-haskell** | Compile-time metaprogramming | ~5 MB |
| **ghc-boot** | GHC-specific utilities | ~1 MB |

**Even "Hello, World" needs most of these!**

### 4. System Libraries

Platform-specific C libraries:

```bash
# Linux
-lgmp          # GNU Multiple Precision library (for integer-gmp)
-lpthread      # POSIX threads (for RTS scheduler)
-ldl           # Dynamic loading (for FFI)
-lm            # Math library
-lrt           # Real-time extensions
-lc            # C standard library

# macOS
-liconv        # Character encoding
-lSystem       # macOS system library

# Windows
-lkernel32     # Windows kernel
-lws2_32       # Winsock (networking)
-lmsvcrt       # Microsoft Visual C Runtime
```

---

## The Linking Command

### Anatomy of a GHC Link Command

When you run `ghc Hello.hs -o hello`, GHC constructs a command like this:

```bash
/usr/bin/ld \
  # 1. Startup code
  -dynamic-linker /lib64/ld-linux-x86-64.so.2 \
  /usr/lib/x86_64-linux-gnu/crt1.o \
  /usr/lib/x86_64-linux-gnu/crti.o \
  /usr/lib/ghc-9.4.8/rts/Start.o \

  # 2. Your code
  Hello.o \

  # 3. Haskell libraries (in dependency order)
  -L/usr/lib/ghc-9.4.8/base-4.17.2.1 \
  -lHSbase-4.17.2.1 \
  -L/usr/lib/ghc-9.4.8/ghc-prim-0.9.1 \
  -lHSghc-prim-0.9.1 \
  -L/usr/lib/ghc-9.4.8/integer-gmp-1.1 \
  -lHSinteger-gmp-1.1 \
  # ... (10+ more Haskell libraries)

  # 4. Runtime System
  -L/usr/lib/ghc-9.4.8/rts \
  -lHSrts \

  # 5. System libraries
  -lgmp -lm -lrt -ldl -lpthread \

  # 6. Shutdown code
  /usr/lib/x86_64-linux-gnu/crtn.o \

  # Output
  -o hello
```

**Total arguments**: 100-200 depending on your dependencies!

### Capturing the Real Command

To see what GHC actually does:

```bash
ghc -v Hello.hs -o hello 2>&1 | grep -A 50 '*** Linker:'
```

Or save to a file:

```bash
ghc -v Hello.hs -o hello &> build.log
```

---

## Haskell Boot Packages

GHC ships with a set of "boot packages" that are considered part of the base system. Even a minimal Haskell program depends on many of these.

### Complete List (GHC 9.4)

```
base                  # The Prelude and standard library
ghc-prim              # Primitive operations
integer-gmp           # Arbitrary-precision arithmetic
ghc-bignum           # New integer library (GHC 9.0+)
array                 # Mutable and immutable arrays
deepseq               # Deep evaluation
bytestring            # Efficient byte strings
containers            # Data structures (Map, Set, etc.)
text                  # Unicode text
binary                # Binary serialization
parsec                # Parser combinators
mtl                   # Monad transformer library
transformers          # Monad transformers
template-haskell      # Metaprogramming
ghc-boot              # GHC internals
ghc-boot-th           # Template Haskell support
pretty                # Pretty-printing library
directory             # File system operations
process               # Running external processes
filepath              # File path manipulation
time                  # Date and time
unix                  # Unix-specific operations (Linux/macOS)
Win32                 # Windows-specific operations
stm                   # Software transactional memory
```

### Why So Many?

**Dependency cascade**: Even simple operations pull in many libraries.

Example: `putStrLn "Hello"` requires:
- `base` (for `putStrLn` and `IO`)
- `ghc-prim` (for `String` = `[Char]`, which uses primitive list operations)
- `integer-gmp` (for `Int` operations used internally)
- `bytestring` (for efficient I/O buffering)

---

## Calling Conventions

### What Is a Calling Convention?

A **calling convention** defines:
- How arguments are passed (registers vs. stack)
- How return values are returned
- Which registers are preserved
- How the stack is managed

### C Calling Convention (cdecl/System V AMD64 ABI)

```c
int add(int a, int b) {
    return a + b;
}
```

**Calling convention**:
- Arguments in registers: `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9`
- Return value in `%rax`
- Stack grows downward
- Caller cleans up stack

### Haskell Calling Convention (Custom)

```haskell
add :: Int -> Int -> Int
add x y = x + y
```

**Haskell's convention** is different:
- Arguments are **heap-allocated closures**
- Return values are **pointers to closures**
- Every closure has an **info table** (metadata for GC)
- Evaluation is **lazy** (may return a thunk)
- Stack contains **update frames** for memoization

**Info Table Structure**:
```c
typedef struct {
    StgFunPtr entry;        // Entry code
    StgInfoTable *layout;   // Heap layout (for GC)
    StgWord type;          // Closure type
    StgWord srt;           // Static reference table
} StgInfoTable;
```

### Why This Matters for Linking

The RTS and all Haskell code must agree on:
1. **Closure layout**: How objects are structured in memory
2. **Info table format**: Metadata for garbage collection
3. **Stack frame layout**: How to walk the stack
4. **Entry points**: How to call functions

**GHC ensures consistency** by:
- Generating all info tables itself
- Linking the matching RTS variant
- Using a unified calling convention throughout

**A naive linker has no knowledge of these conventions.**

---

## Link Order and Dependencies

### Why Order Matters

Linkers process libraries in order. If library A depends on library B, then **A must come before B** on the command line:

```bash
# Correct
ld YourCode.o -lA -lB -lsystem

# Wrong (unresolved symbols)
ld YourCode.o -lB -lA -lsystem
```

### Haskell Dependency Graph

```
Your Code
    └─> base
         ├─> ghc-prim
         │    └─> (no dependencies)
         ├─> integer-gmp
         │    └─> gmp (system library)
         └─> array
              └─> ghc-prim
```

**Topological order**: `YourCode.o -lHSbase -lHSarray -lHSinteger-gmp -lHSghc-prim -lgmp`

### How GHC Computes Order

1. **Parse your code**: Identify imported modules
2. **Query package database**: `ghc-pkg list`
3. **Build dependency graph**: Traverse imports recursively
4. **Topological sort**: Compute correct link order
5. **Add RTS last**: Runtime system depends on everything

**Only GHC has this information.** A standalone linker cannot reconstruct the dependency graph.

---

## Dynamic vs Static Linking

### Static Linking (Default)

```bash
ghc -static Hello.hs -o hello
```

**Pros**:
- ✅ Single executable (no external dependencies)
- ✅ Faster startup (no dynamic loading)
- ✅ Easier deployment

**Cons**:
- ❌ Large executable size (10+ MB for "Hello, World")
- ❌ No shared libraries (wastes memory if running multiple Haskell programs)
- ❌ Must recompile to update libraries

### Dynamic Linking

```bash
ghc -dynamic Hello.hs -o hello
```

**Pros**:
- ✅ Smaller executable (~50 KB)
- ✅ Shared libraries (saves memory)
- ✅ Can update libraries without recompiling

**Cons**:
- ❌ Requires GHC libraries to be installed on target system
- ❌ Slower startup (dynamic linking overhead)
- ❌ More complex deployment

### Choosing the Right Approach

| Use Case | Recommendation |
|----------|---------------|
| **Development** | Dynamic (faster iteration) |
| **Production server** | Static (easier deployment) |
| **Distributed binary** | Static (no dependencies) |
| **Multiple Haskell programs** | Dynamic (shared memory) |
| **Embedded system** | Static (no dynamic linker) |

---

## Choosing Your System Linker

GHC can use different system linkers as "sub-contractors."

### Available Linkers

| Linker | Speed | Compatibility | Notes |
|--------|-------|---------------|-------|
| **GNU ld** | Slow | Universal | Default on most Linux systems |
| **gold** | Fast | Good | Google's linker, faster than ld |
| **lld** | Very Fast | Excellent | LLVM's linker, recommended |
| **ld64** | N/A | macOS only | Apple's linker |

### Using a Different Linker

```bash
# Use lld (LLVM linker)
ghc -pgml ld.lld Hello.hs -o hello

# Use gold
ghc -pgml ld.gold Hello.hs -o hello

# Use GNU ld (default)
ghc -pgml ld Hello.hs -o hello
```

**Note**: You're still using **GHC as the driver**. You're just changing which tool GHC delegates to.

### Performance Comparison

Linking time for a medium project (100 modules):

```
GNU ld:   12.3 seconds
gold:      4.8 seconds
lld:       2.1 seconds
```

**Recommendation**: Use `lld` for faster builds.

```bash
# Add to your cabal.project or stack.yaml
ghc-options: -pgml=ld.lld
```

---

## Conclusion

GHC's linking process is complex because Haskell programs have complex requirements:

1. **Runtime System**: Every program needs GC, scheduler, heap management
2. **Boot Libraries**: Even "Hello, World" uses 10+ libraries
3. **Custom Calling Convention**: Closures, info tables, lazy evaluation
4. **Dependency Management**: Topological ordering of 100+ libraries
5. **Platform Specifics**: Different systems, different requirements

**You cannot bypass GHC** because only GHC knows:
- Where all the Haskell libraries are installed
- Which RTS variant to use
- The correct dependency order
- How to maintain calling convention consistency

**You can choose your system linker** (`ld`, `gold`, `lld`), but **GHC must orchestrate** the linking process.

---

## Further Reading

- [GHC Architecture](./ghc-architecture.md): How GHC compiles code
- [Runtime System Explained](./rts-explained.md): What the RTS does
- [GHC User's Guide: Linking](https://downloads.haskell.org/ghc/latest/docs/users_guide/phases.html#options-affecting-linking)
- [GHC Commentary: Linker](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/rts/interpreter/linker)

---

**Back to:** [Main README](../README.md)
