# PoC 1: Quantifying the Linker Command Difference

## Overview

This proof-of-concept demonstrates the massive difference between a naive attempt to link Haskell object files with a standard linker (lld) versus the comprehensive linking command that GHC constructs.

## What This PoC Does

1. **Creates a minimal Haskell program** (`Hello.hs`) that prints "Hello, Haskell!"
2. **Compiles to object file** using GHC's LLVM backend (`ghc -fllvm -c`)
3. **Attempt 1 (Naive)**: Tries to link with `lld` directly, providing only basic C libraries
4. **Attempt 2 (Correct)**: Uses `ghc` as the driver to construct the proper link command
5. **Quantifies the difference**: Shows how GHC's command has 100+ more arguments

## Running the PoC

### With Docker (Recommended)

```bash
# From the repository root
docker build -t ghc-linker-poc -f Dockerfile .
docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh
```

### Locally (Requires GHC and LLVM)

```bash
cd poc1-linker-comparison
./build.sh
```

## Expected Output

### Attempt 1: The Naive Way (FAILS)

```
--- Attempt 1: Linking with lld (The Wrong Way) ---
Running: lld -o hello_fail Hello.o -lc -lm -lpthread -ldl
FAILED, as expected. lld errors:
undefined reference: base_GHCziTopHandler_flushStdHandles_closure
undefined reference: base_GHCziIOziHandleziFD_stdout_closure
undefined reference: ghczmprim_GHCziTypes_True_closure
undefined reference: base_GHCziShow_zdfShowChar_closure
undefined reference: stg_ap_0_fast
[... and many more, missing all 'base' and 'RTS' symbols]
```

**Why it fails**: The linker is missing:
- The Haskell Runtime System (RTS)
- All base library functions
- GHC-specific primitives
- STG machine implementations

### Attempt 2: The GHC Way (SUCCEEDS)

GHC constructs a massive linker command with:
- **Runtime System libraries**: `libHSrts.a` and related files
- **Base library**: `libHSbase-4.17.2.1.a`
- **Primitive libraries**: `libHSghc-prim-0.9.1.a`, `libHSinteger-gmp-1.1.2.0.a`
- **Startup code**: `crt0.o` and other initialization objects
- **System libraries**: Properly ordered `-lgmp`, `-ldl`, `-lpthread`, `-lm`, `-lc`

## Key Insights

### The Argument Count

- **Naive lld command**: ~7 arguments
- **GHC's real command**: 100+ arguments

This isn't just about quantity—it's about GHC acting as the "general contractor" that knows:
1. Which RTS variant to use (threaded, dynamic, profiling, etc.)
2. The complete dependency graph of all Haskell packages
3. The correct topological order for linking
4. Platform-specific requirements and calling conventions

### What GHC Provides

1. **Runtime System (RTS)**
   - Garbage collector
   - Thread scheduler (green threads)
   - Heap management
   - Exception handling
   - FFI support

2. **Standard Libraries**
   - `base`: Core Prelude and standard functions
   - `ghc-prim`: Compiler primitives
   - `integer-gmp`: Arbitrary-precision arithmetic
   - And many more boot libraries

3. **Startup/Shutdown Code**
   - Proper initialization of the RTS
   - Setting up the Haskell calling convention
   - Registering exception handlers

## Technical Deep Dive

The build script captures GHC's verbose output to show the actual linker command. You can examine `ghc_verbose.log` (generated during the build) to see every step GHC takes.

### Understanding the Symbols

The "undefined reference" errors reveal Haskell's internal naming conventions:

- `base_GHCziTopHandler_flushStdHandles_closure`: A closure from the `base` package, `GHC.TopHandler` module
  - `zi` represents `.` in module names (Z-encoding)
  - `_closure` indicates this is a heap-allocated closure object

- `stg_ap_0_fast`: Part of the STG (Spineless Tagless G-machine) implementation
  - These are the core evaluation primitives for Haskell's lazy evaluation

## Files in This Directory

- `build.sh`: The main demonstration script
- `README.md`: This file
- `analysis/compare_commands.sh`: Helper script to parse and analyze linker commands

## Further Reading

See the main [repository README](../README.md) for the complete blog post and conceptual explanation.

For deep dives into specific topics:
- [GHC Architecture](../docs/ghc-architecture.md)
- [Runtime System Explained](../docs/rts-explained.md)
- [The Linking Process](../docs/linking-process.md)
