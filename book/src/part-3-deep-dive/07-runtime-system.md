# Chapter 7: The Haskell Runtime System

## The "Life Support" for Haskell Programs

Without the Runtime System (RTS), no Haskell code can execute. It's the foundation that makes Haskell's unique features possible.

The RTS is approximately **50,000 lines of C code** (about 5 MB compiled) that provides essential services:

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

## Core Components

### 1. The Garbage Collector

Haskell uses **automatic memory management** via a generational copying garbage collector.

**Why it matters**: In Haskell, you never call `free()` or `delete`. The GC handles all memory management automatically.

#### Generational GC Strategy

```
┌──────────────────────────────────────────────────────────┐
│                    Haskell Heap                          │
├──────────────────────────────────────────────────────────┤
│  Generation 0 (Nursery) - Young objects                 │
│  ┌────┬────┬────┬────┬────┐                             │
│  │ A  │ B  │ C  │ D  │ E  │  <- Most die quickly        │
│  └────┴────┴────┴────┴────┘                             │
├──────────────────────────────────────────────────────────┤
│  Generation 1 (Mature) - Survivors                      │
│  ┌────┬────┬────┐                                        │
│  │ F  │ G  │ H  │  <- Long-lived objects                │
│  └────┴────┴────┘                                        │
└──────────────────────────────────────────────────────────┘
```

**Key insight**: Most objects die young, so the GC focuses on Gen 0 (fast) and rarely scans Gen 1 (slow).

#### Tuning the GC

```bash
# Set heap size and allocation area
./program +RTS -H512m -A128m

# -H: Initial heap size (suggestion)
# -A: Nursery size (larger = fewer minor GCs)

# See GC statistics
./program +RTS -s
```

### 2. The Scheduler

Haskell uses **green threads** (lightweight, user-space threads):

| Property | OS Thread | Haskell Thread |
|----------|-----------|----------------|
| Stack size | ~1-8 MB | ~1 KB (grows dynamically) |
| Creation time | ~1ms | ~1μs |
| Context switch | ~1-10μs | ~100ns |
| Max count | ~1,000-10,000 | ~1,000,000+ |

**This enables millions of concurrent threads!**

#### Capabilities

A **capability** is a "virtual CPU":

```bash
# Run with 4 cores
./program +RTS -N4
```

Each capability:
- Has its own run queue
- Maps to one OS thread
- Can steal work from other capabilities (work-stealing scheduler)

### 3. Lazy Evaluation

The RTS makes lazy evaluation possible through **thunks** (suspended computations):

```haskell
-- Define expensive computation
let x = sum [1..1000000]

-- x is NOT evaluated yet - it's a thunk!
-- Only evaluated when needed:
print x  -- Now it evaluates
```

**After first evaluation, the result is cached** (update in place):

```
Before:                  After:
┌─────────────┐          ┌─────────────┐
│ THUNK       │          │ VALUE       │
│ code: sum.. │   --->   │ 500000500000│
└─────────────┘          └─────────────┘
```

This ensures **sharing**: the expensive computation runs only once, no matter how many times you use `x`.

### 4. FFI Support

The RTS provides the bridge between Haskell and C:

```c
#include "HsFFI.h"

int main(int argc, char *argv[]) {
    hs_init(&argc, &argv);   // Start RTS

    // ... call Haskell functions ...

    hs_exit();               // Stop RTS
    return 0;
}
```

**What `hs_init()` does:**
1. Initialize heap and GC
2. Start scheduler
3. Set up signal handlers
4. Initialize profiling (if enabled)
5. Set up exception handling

## RTS Variants

GHC provides multiple RTS variants for different use cases:

| Variant | Library File | Use Case |
|---------|-------------|----------|
| **Vanilla** | `libHSrts.a` | Single-threaded, default |
| **Threaded** | `libHSrts_thr.a` | Multi-core parallelism |
| **Profiling** | `libHSrts_p.a` | Performance profiling |
| **Debug** | `libHSrts_debug.a` | RTS debugging |
| **Event log** | `libHSrts_l.a` | ThreadScope analysis |

```bash
# Use threaded RTS (most common for servers)
ghc -threaded MyProgram.hs

# Enable profiling
ghc -prof -fprof-auto MyProgram.hs

# Debug RTS
ghc -debug MyProgram.hs
```

### Threaded vs Non-threaded

**Use `-threaded` when:**
- ✅ Need to use multiple cores
- ✅ Building servers or long-running programs
- ✅ Making blocking foreign calls

**Skip `-threaded` when:**
- ⚠️ Building simple scripts
- ⚠️ Memory overhead is critical
- ⚠️ Only single-threaded performance matters

**Rule of thumb:** Use `-threaded` unless you have a specific reason not to.

## Performance Tuning

### Common RTS Options

```bash
# See all RTS options
./program +RTS --help

# Production web server settings
./web-server +RTS -N4        # 4 worker threads
                  -A32m      # Larger nursery (fewer minor GCs)
                  -H1g       # Start with 1GB heap
                  -I0        # Disable idle GC
                  -qg        # Enable parallel GC
                  -qn4       # 4 parallel GC threads
```

### Profiling

```bash
# 1. Build with profiling
ghc -prof -fprof-auto -rtsopts MyProgram.hs

# 2. Run with profiling enabled
./MyProgram +RTS -p -hc

# 3. Analyze results
cat MyProgram.prof          # Time and allocation profile
hp2ps MyProgram.hp          # Heap profile (graphical)
```

## Why This Matters for Linking

The RTS is **why you need GHC to link Haskell programs**:

1. **Essential dependency**: Without `libHSrts.a`, your Haskell code cannot execute
2. **Multiple variants**: GHC selects the right RTS based on your flags
3. **Platform-specific**: Different systems need different configurations
4. **Complex initialization**: The RTS must be properly initialized before any Haskell code runs

A naive linker has no knowledge of:
- Which RTS variant to use
- Where to find it
- How to link it correctly
- What initialization is needed

## Further Reading

For deeper exploration:

- **Full documentation**: [`../../docs/rts-explained.md`](../../docs/rts-explained.md)
- **GHC User's Guide: RTS**: [Official documentation](https://downloads.haskell.org/ghc/latest/docs/users_guide/runtime_control.html)
- **ThreadScope**: [Visualize parallel execution](https://wiki.haskell.org/ThreadScope)

---

## Summary

Key takeaways:

1. ✅ The RTS is **essential** - no Haskell code runs without it
2. ✅ Provides **GC, scheduler, lazy evaluation, and FFI support**
3. ✅ Comes in **multiple variants** (threaded, profiling, debug)
4. ✅ Highly **tunable** for different workloads
5. ✅ Why **GHC must orchestrate linking**

**Next**: Let's explore [The Linking Process →](./08-linking-process.md)

---

## Quick Navigation

- **Previous**: [← GHC Architecture](./06-ghc-architecture.md)
- **Next**: [The Linking Process →](./08-linking-process.md)
- **Related**: [FFI Guide →](./09-ffi-guide.md)
