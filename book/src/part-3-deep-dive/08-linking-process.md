# Chapter 8: The Linking Process

## What Actually Happens During Linking

Linking is the final stage of building a Haskell program. It combines compiled object files, libraries, and the runtime system into a single executable.

**This chapter explains what GHC does during linking and why a naive linker cannot do it.**

## Linking Basics

### C Linking (Simple)

```bash
# Compile and link a C program
gcc hello.c -o hello

# gcc automatically adds:
# - C runtime startup code (crt0.o)
# - C standard library (libc)
# - Dynamic linker support
```

**Total**: 3-5 dependencies

### Haskell Linking (Complex)

```bash
# Compile and link a Haskell program
ghc Hello.hs -o hello

# GHC must add:
# - Haskell Runtime System (libHSrts.a)
# - Base library (libHSbase-4.x.x.a)
# - 10+ boot libraries
# - System libraries (gmp, pthread, dl, m, c)
# - Proper initialization code
```

**Total**: 100-200 dependencies!

## What GHC Links

### 1. Your Code

```
Your compiled modules:
├── Main.o
├── MyModule.o
└── Utils.o
```

### 2. The Runtime System

```
RTS Components:
├── libHSrts.a (or libHSrts_thr.a)
├── Garbage collector
├── Thread scheduler
├── Heap management
├── Exception handling
└── FFI support
```

### 3. Haskell Boot Libraries

These are the standard libraries that ship with GHC:

| Library | Purpose | Typical Size |
|---------|---------|--------------|
| **base** | Standard Prelude, I/O | ~10 MB |
| **ghc-prim** | Primitive operations | ~1 MB |
| **integer-gmp** | Arbitrary-precision integers | ~500 KB |
| **array** | Arrays | ~500 KB |
| **bytestring** | Efficient byte arrays | ~1 MB |
| **text** | Unicode text | ~2 MB |
| **containers** | Sets, maps, sequences | ~2 MB |

**Even "Hello, World" needs most of these!**

Example: `putStrLn "Hello"` requires:
- `base` (for `putStrLn` and `IO`)
- `ghc-prim` (for list operations)
- `integer-gmp` (for Int operations)
- `bytestring` (for I/O buffering)

### 4. System Libraries

Platform-specific C libraries:

```bash
# Linux
-lgmp          # GNU Multiple Precision library
-lpthread      # POSIX threads
-ldl           # Dynamic loading
-lm            # Math library
-lc            # C standard library

# macOS
-liconv        # Character encoding
-lSystem       # macOS system library

# Windows
-lkernel32     # Windows kernel
-lws2_32       # Winsock (networking)
```

## The Linking Command

### What GHC Constructs

When you run `ghc Hello.hs -o hello`, GHC constructs a massive linker command:

```bash
/usr/bin/ld \
  # 1. Startup code
  /usr/lib/x86_64-linux-gnu/crt1.o \
  /usr/lib/x86_64-linux-gnu/crti.o \

  # 2. Your code
  Hello.o \

  # 3. Haskell libraries (in dependency order)
  -lHSbase-4.17.2.1 \
  -lHSghc-prim-0.9.1 \
  -lHSinteger-gmp-1.1 \
  # ... (10+ more libraries)

  # 4. Runtime System
  -lHSrts \

  # 5. System libraries
  -lgmp -lm -lpthread -ldl \

  # 6. Shutdown code
  /usr/lib/x86_64-linux-gnu/crtn.o \

  # Output
  -o hello
```

**Total arguments**: 140+ arguments!

### See It Yourself

```bash
# Capture the actual linker command
ghc -v Hello.hs -o hello 2>&1 | grep -A 50 '*** Linker:'
```

## Calling Conventions

### Why This Matters

A **calling convention** defines:
- How arguments are passed
- How return values are returned
- Which registers are preserved
- How the stack is managed

### C Calling Convention

```c
int add(int a, int b) {
    return a + b;
}
```

**Convention**:
- Arguments in registers: `%rdi`, `%rsi`
- Return value in `%rax`
- Simple and standard

### Haskell Calling Convention

```haskell
add :: Int -> Int -> Int
add x y = x + y
```

**Haskell's convention is different**:
- Arguments are **heap-allocated closures**
- Return values are **pointers to closures**
- Every closure has an **info table** (metadata for GC)
- Evaluation is **lazy** (may return a thunk)

**Info Table Structure**:

```c
typedef struct {
    StgFunPtr entry;        // Entry code
    StgInfoTable *layout;   // Heap layout (for GC)
    StgWord type;          // Closure type
    StgWord srt;           // Static reference table
} StgInfoTable;
```

The RTS and all Haskell code must agree on:
1. Closure layout
2. Info table format
3. Stack frame layout
4. Entry points

**GHC ensures consistency** by generating all info tables and linking the matching RTS variant.

**A naive linker has no knowledge of these conventions.**

## Link Order and Dependencies

### Why Order Matters

Linkers process libraries in order. If library A depends on library B, then **A must come before B**:

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
         ├─> integer-gmp
         │    └─> gmp (system library)
         └─> array
              └─> ghc-prim
```

**Topological order required**: `YourCode.o -lHSbase -lHSarray -lHSinteger-gmp -lHSghc-prim -lgmp`

### How GHC Computes Order

1. **Parse your code**: Identify imported modules
2. **Query package database**: `ghc-pkg list`
3. **Build dependency graph**: Traverse imports recursively
4. **Topological sort**: Compute correct link order
5. **Add RTS last**: Runtime system depends on everything

**Only GHC has this information.** A standalone linker cannot reconstruct the dependency graph.

## Dynamic vs Static Linking

### Static Linking (Default)

```bash
ghc -static Hello.hs -o hello
```

**Pros**:
- ✅ Single executable (no external dependencies)
- ✅ Faster startup
- ✅ Easier deployment

**Cons**:
- ❌ Large executable size (10+ MB for "Hello, World")
- ❌ No shared libraries
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
- ❌ Requires GHC libraries on target system
- ❌ Slower startup (dynamic linking overhead)
- ❌ More complex deployment

### Choosing the Right Approach

| Use Case | Recommendation |
|----------|---------------|
| **Development** | Dynamic (faster iteration) |
| **Production server** | Static (easier deployment) |
| **Distributed binary** | Static (no dependencies) |
| **Multiple Haskell programs** | Dynamic (shared memory) |

## Choosing Your System Linker

GHC can use different system linkers:

| Linker | Speed | Compatibility | Notes |
|--------|-------|---------------|-------|
| **GNU ld** | Slow | Universal | Default on most Linux |
| **gold** | Fast | Good | Google's linker |
| **lld** | Very Fast | Excellent | LLVM's linker (recommended) |
| **ld64** | N/A | macOS only | Apple's linker |

```bash
# Use lld (LLVM linker) - recommended
ghc -fuse-ld=lld Hello.hs -o hello

# Use gold
ghc -fuse-ld=gold Hello.hs -o hello
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

## Why GHC Must Orchestrate

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

## Further Reading

For deeper exploration:

- **Full documentation**: [`../../docs/linking-process.md`](../../docs/linking-process.md)
- **GHC User's Guide**: [Linking options](https://downloads.haskell.org/ghc/latest/docs/users_guide/phases.html#options-affecting-linking)

---

## Summary

Key takeaways:

1. ✅ Linking combines **your code + RTS + libraries**
2. ✅ GHC constructs a **140+ argument** linker command
3. ✅ **Dependency order matters** and GHC computes it
4. ✅ **Calling conventions** are Haskell-specific
5. ✅ You can **choose the system linker** but not skip GHC

**Next**: Let's dive into [The FFI Guide →](./09-ffi-guide.md)

---

## Quick Navigation

- **Previous**: [← The Runtime System](./07-runtime-system.md)
- **Next**: [FFI Guide →](./09-ffi-guide.md)
- **Related**: [GHC Architecture →](./06-ghc-architecture.md)
