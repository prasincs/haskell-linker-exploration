# The Haskell Runtime System (RTS): Explained

## Overview

The Haskell Runtime System (RTS) is the "life support" for every Haskell program. It's a sophisticated piece of C code (about 50,000 lines) that manages memory, threads, exceptions, and lazy evaluation.

**Without the RTS, no Haskell code can execute.**

This document explains what the RTS does, how it works, and why it's essential for linking Haskell programs.

## Table of Contents

- [What Is the RTS?](#what-is-the-rts)
- [Core Components](#core-components)
- [Memory Management](#memory-management)
- [The Scheduler](#the-scheduler)
- [Lazy Evaluation](#lazy-evaluation)
- [FFI Support](#ffi-support)
- [RTS Variants](#rts-variants)
- [Performance Tuning](#performance-tuning)

---

## What Is the RTS?

### Comparison with Other Languages

| Language | Runtime | Size | Purpose |
|----------|---------|------|---------|
| **C** | None | 0 KB | Direct hardware access |
| **Go** | Goroutine scheduler, GC | ~2 MB | Concurrency, memory |
| **Java** | JVM | ~200 MB | Virtual machine, JIT, GC |
| **Haskell** | RTS | ~5 MB | Lazy evaluation, GC, threads |

### What's Included in libHSrts.a

The RTS library contains:

```
libHSrts.a (static library, ~5 MB)
│
├── Garbage Collector (gc.c, compact.c, evac.c)
├── Scheduler (Schedule.c, Capability.c, Threads.c)
├── Heap Management (Storage.c, Block.c, Arena.c)
├── STG Evaluation (Apply.c, Interpreter.c)
├── Exception Handling (Exception.c, signals.c)
├── FFI Support (Adjustor.c, HsFFI.c)
├── Profiling (Profiling.c, ProfHeap.c)
├── Event Logging (Eventlog.c, Trace.c)
└── Platform Support (Posix.c, Win32.c)
```

---

## Core Components

### 1. The Garbage Collector (GC)

#### Overview

Haskell uses **automatic memory management** via a generational copying garbage collector.

```
Heap Structure:
┌──────────────────────────────────────────────────────────┐
│                    Haskell Heap                          │
├──────────────────────────────────────────────────────────┤
│  Generation 0 (Nursery)                                  │
│  ┌────┬────┬────┬────┬────┐                             │
│  │ A  │ B  │ C  │ D  │ E  │  <- Young objects           │
│  └────┴────┴────┴────┴────┘                             │
├──────────────────────────────────────────────────────────┤
│  Generation 1 (Mature)                                   │
│  ┌────┬────┬────┐                                        │
│  │ F  │ G  │ H  │  <- Survived Gen0 GC                  │
│  └────┴────┴────┘                                        │
└──────────────────────────────────────────────────────────┘
```

#### GC Algorithm

**Generational Hypothesis**: Most objects die young.

1. **Minor GC** (frequent):
   - Only scan Generation 0
   - Copy live objects to Generation 1
   - Fast: typically <1ms

2. **Major GC** (rare):
   - Scan all generations
   - Compact memory
   - Slower: 10-100ms

#### GC Triggering

```haskell
-- Automatic GC triggers when:
-- 1. Allocation reaches threshold
-- 2. Explicit call to System.Mem.performGC
-- 3. Before program exit

import System.Mem

main = do
    buildLargeStructure  -- Allocates lots of memory
    performGC            -- Explicit GC (rarely needed)
    processData
```

#### GC Tuning

```bash
# Set heap size limits
./program +RTS -H128m -M2g

# -H: Initial heap size (suggestion)
# -M: Maximum heap size (hard limit)

# GC statistics
./program +RTS -s

# Output:
#   Allocated: 1,024 MB
#   Copied:      128 MB
#   Max residency: 64 MB
#   GC time: 0.12s (2% of total)
```

### 2. The Heap

#### Heap Layout

Every Haskell object on the heap has a **closure** structure:

```c
// Simplified closure representation
typedef struct {
    StgInfoTable *info;   // Pointer to info table (metadata)
    StgWord payload[0];   // Variable-size payload
} StgClosure;
```

**Info Tables** contain:
- Entry code (how to evaluate the closure)
- Layout information (which fields are pointers)
- Type information
- Constructor tag (for data constructors)

#### Example: List in Memory

```haskell
-- Haskell code
let xs = [1, 2, 3]
```

```
Memory layout:
┌─────────────────────────┐
│ xs: Cons closure        │
│  info → (:) constructor │
│  head → Int# 1          │
│  tail → ┐               │
└─────────┼───────────────┘
          │
          ▼
    ┌─────────────────────────┐
    │ Cons closure            │
    │  info → (:) constructor │
    │  head → Int# 2          │
    │  tail → ┐               │
    └─────────┼───────────────┘
              │
              ▼
        ┌─────────────────────────┐
        │ Cons closure            │
        │  info → (:) constructor │
        │  head → Int# 3          │
        │  tail → []              │
        └─────────────────────────┘
```

#### Thunks (Unevaluated Expressions)

```haskell
-- Lazy computation
let expensive = sum [1..1000000]
```

```
Initial memory layout (THUNK):
┌─────────────────────────┐
│ expensive: THUNK        │
│  info → thunk_info      │
│  code → sum [1..1M]     │
└─────────────────────────┘

After evaluation (VALUE):
┌─────────────────────────┐
│ expensive: VALUE        │
│  info → Int_info        │
│  value → 500000500000   │
└─────────────────────────┘
```

**Update frames** ensure thunks are evaluated only once.

### 3. The Scheduler

#### Haskell Threads vs OS Threads

Haskell uses **green threads** (lightweight, user-space):

```
┌────────────────────────────────────────────────────────┐
│            Operating System                            │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ OS Thread 1  │  │ OS Thread 2  │  │ OS Thread 3 │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘ │
└─────────┼──────────────────┼──────────────────┼────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌────────────────────────────────────────────────────────┐
│          Haskell Runtime System (Scheduler)            │
│  ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐ │
│  │ T1 │ T2 │ T3 │ T4 │ T5 │ T6 │ T7 │ T8 │ T9 │T10 │ │
│  └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘ │
│         Haskell Threads (green threads)                │
│         Thousands can exist simultaneously             │
└────────────────────────────────────────────────────────┘
```

**Key differences:**

| Property | OS Thread | Haskell Thread |
|----------|-----------|----------------|
| Stack size | ~1-8 MB | ~1 KB (grows dynamically) |
| Creation time | ~1ms | ~1μs |
| Context switch | ~1-10μs | ~100ns |
| Max count | ~1,000-10,000 | ~1,000,000+ |

#### Capabilities

A **capability** is a "virtual CPU" in the RTS:

```bash
# Run with 4 capabilities (parallel execution)
./program +RTS -N4
```

```
┌──────────────────────────────────────────────────┐
│              Haskell Program                     │
├──────────────────────────────────────────────────┤
│  ┌───────────┐ ┌───────────┐ ┌───────────┐     │
│  │  Cap 1    │ │  Cap 2    │ │  Cap 3    │ ... │
│  │ ┌───────┐ │ │ ┌───────┐ │ │ ┌───────┐ │     │
│  │ │Run Q  │ │ │ │Run Q  │ │ │ │Run Q  │ │     │
│  │ └───────┘ │ │ └───────┘ │ │ └───────┘ │     │
│  └───────────┘ └───────────┘ └───────────┘     │
├──────────────────────────────────────────────────┤
│      ┌─────────────────────────────┐            │
│      │    Global Run Queue          │            │
│      │  (work stealing enabled)     │            │
│      └─────────────────────────────┘            │
└──────────────────────────────────────────────────┘
         │                 │                 │
         ▼                 ▼                 ▼
  ┌───────────┐     ┌───────────┐     ┌───────────┐
  │OS Thread 1│     │OS Thread 2│     │OS Thread 3│
  └───────────┘     └───────────┘     └───────────┘
```

Each capability:
- Has its own run queue
- Maps to one OS thread
- Can steal work from other capabilities

#### Thread States

```haskell
data ThreadStatus
  = ThreadRunning      -- Currently executing
  | ThreadBlocked      -- Waiting on MVar/STM/IO
  | ThreadFinished     -- Completed execution
  | ThreadDied         -- Terminated by exception
```

#### Scheduling Example

```haskell
import Control.Concurrent

main = do
    -- Create 1 million threads!
    forkIO $ putStrLn "Thread 1"
    forkIO $ putStrLn "Thread 2"
    -- ... (repeat 1 million times)

    threadDelay 1000000  -- Wait 1 second
```

**This is possible** because:
- Each thread uses minimal memory (~1 KB)
- Scheduler is very efficient (work-stealing)
- Most threads block immediately (no wasted CPU)

---

## Lazy Evaluation

### How It Works

Lazy evaluation is the defining feature of Haskell, and the RTS makes it possible.

#### Thunk Lifecycle

```haskell
-- Define an expensive computation
let x = sum [1..1000000]

-- x is NOT evaluated yet!
-- It's a THUNK (suspended computation)
```

**Thunk representation:**
```c
typedef struct {
    StgInfoTable *info;        // Points to thunk_info
    StgClosure *(*code)(void); // Function to evaluate
    StgClosure *env[];         // Captured environment
} StgThunk;
```

#### Evaluation (Forcing)

```haskell
print x  -- Now x must be evaluated
```

**What happens:**
1. RTS sees `x` is a thunk
2. Calls the thunk's entry code
3. Entry code computes `sum [1..1000000]`
4. **Updates** thunk to point to result (500000500000)
5. Returns result

**After evaluation:**
```c
// Thunk is overwritten (update in place)
typedef struct {
    StgInfoTable *info;   // Now points to Int_info
    StgInt value;         // 500000500000
} StgInt;
```

Any future use of `x` reads the cached value directly (no recomputation).

#### Update Frames

To ensure **sharing**, the RTS uses update frames:

```haskell
let x = expensive
let y = x + 1
let z = x + 2
```

When `y` forces `x`, the RTS:
1. Pushes an **update frame** on the stack
2. Evaluates the thunk
3. The update frame overwrites the thunk with the result
4. When `z` accesses `x`, it sees the cached value

### Black Holes

To detect infinite recursion and enable parallel evaluation:

```haskell
let x = x + 1  -- Infinite loop!
print x        -- This will hang
```

**Black hole mechanism:**
1. When thread starts evaluating a thunk, it **marks it as a black hole**
2. If another thread tries to evaluate the same thunk, it **blocks**
3. If the same thread encounters its own black hole → **infinite loop detected**

---

## FFI Support

The RTS provides the bridge between Haskell and foreign code.

### Calling C from Haskell

```haskell
foreign import ccall "math.h sin"
    c_sin :: CDouble -> CDouble
```

**RTS responsibilities:**
1. Set up the C calling convention
2. Convert Haskell types to C types
3. Handle potential blocking (if using `safe`)
4. Ensure GC doesn't run during C code execution

### Calling Haskell from C

```c
#include "HsFFI.h"

int main(int argc, char *argv[]) {
    hs_init(&argc, &argv);   // Start RTS

    // ... call Haskell functions ...

    hs_exit();               // Stop RTS
    return 0;
}
```

**`hs_init()` responsibilities:**
1. Initialize heap and GC
2. Start scheduler
3. Set up signal handlers
4. Initialize profiling (if enabled)
5. Set up exception handling

**`hs_exit()` responsibilities:**
1. Wait for all threads to finish
2. Run finalizers
3. Flush I/O buffers
4. Free all memory
5. Shut down profiling

---

## RTS Variants

GHC provides multiple RTS variants for different use cases:

### Available Variants

| Variant | Library File | Use Case |
|---------|-------------|----------|
| **Vanilla** | `libHSrts.a` | Single-threaded, default |
| **Threaded** | `libHSrts_thr.a` | Multi-core parallelism |
| **Profiling** | `libHSrts_p.a` | Performance profiling |
| **Debug** | `libHSrts_debug.a` | RTS debugging |
| **Dynamic** | `libHSrts.so` | Shared library |
| **Event log** | `libHSrts_l.a` | ThreadScope analysis |

### Choosing a Variant

```bash
# Threaded RTS (most common for servers)
ghc -threaded MyProgram.hs
# Links against libHSrts_thr.a

# Profiling
ghc -prof -fprof-auto MyProgram.hs
# Links against libHSrts_p.a

# Debug RTS
ghc -debug MyProgram.hs
# Links against libHSrts_debug.a
```

### Threaded vs Non-threaded

**Non-threaded (`-threaded` not used):**
- ✅ Lower memory overhead
- ✅ Simpler scheduler
- ✅ Slightly faster single-threaded performance
- ❌ Cannot use multiple cores
- ❌ Blocking foreign calls block entire program

**Threaded (`-threaded`):**
- ✅ Can use multiple cores (`+RTS -N`)
- ✅ Blocking foreign calls don't block other threads
- ✅ Better for servers and long-running programs
- ❌ Slightly higher memory overhead
- ❌ More complex scheduler

**Rule of thumb:** Use `-threaded` unless you have a specific reason not to.

---

## Performance Tuning

### RTS Options

```bash
# See all RTS options
./program +RTS --help

# Common tuning flags
./program +RTS -N4        # Use 4 cores
             -H512m       # Suggest 512 MB initial heap
             -A128m       # Set nursery (Gen 0) to 128 MB
             -s           # Print GC statistics
             -l           # Generate eventlog for ThreadScope
             -p           # Enable profiling
             -xc          # Show stack trace on exception
```

### Example: Web Server Tuning

```bash
# Production web server settings
./web-server +RTS -N4        # 4 worker threads
                  -A32m      # Larger nursery (fewer minor GCs)
                  -n2m       # Allocation area per thread
                  -H1g       # Start with 1GB heap
                  -I0        # Disable idle GC
                  -qg        # Enable parallel GC
                  -qn4       # 4 parallel GC threads
```

### Heap Sizing

```haskell
-- Too small: Frequent GC, poor performance
./program +RTS -H64m -M128m

-- Too large: Memory waste, rare but long GCs
./program +RTS -H4g -M8g

-- Just right: Depends on workload!
-- Rule of thumb: Set -H to 2x max residency
./program +RTS -H512m -M1g
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

---

## Conclusion

The Haskell Runtime System is a marvel of engineering that provides:

1. **Automatic memory management** via a sophisticated GC
2. **Lazy evaluation** with sharing and memoization
3. **Lightweight threads** (millions possible)
4. **Parallel execution** across multiple cores
5. **FFI support** for interoperating with C

**This is why you need GHC to link Haskell programs:** The RTS is essential, and only GHC knows:
- Which RTS variant to use
- Where to find it
- How to link it correctly

Without `libHSrts.a`, your Haskell code is just lifeless object code that cannot execute.

---

## Further Reading

### Official Documentation
- [GHC User's Guide: RTS](https://downloads.haskell.org/ghc/latest/docs/users_guide/runtime_control.html)
- [GHC Commentary: RTS](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/rts)

### Academic Papers
- [Parallel Generational-Copying Garbage Collection](https://www.microsoft.com/en-us/research/publication/parallel-generational-copying-garbage-collection/) - GHC's GC algorithm
- [Runtime Support for Multicore Haskell](https://www.microsoft.com/en-us/research/publication/runtime-support-for-multicore-haskell/) - Scheduler design

### Tools
- [ThreadScope](https://wiki.haskell.org/ThreadScope) - Visualize parallel execution
- [eventlog2html](https://mpickering.github.io/eventlog2html/) - Modern eventlog visualization
- [ghc-heap-view](https://hackage.haskell.org/package/ghc-heap-view) - Inspect heap objects

---

**Back to:** [Main README](../README.md) | [GHC Architecture](./ghc-architecture.md) | [Linking Process](./linking-process.md)
