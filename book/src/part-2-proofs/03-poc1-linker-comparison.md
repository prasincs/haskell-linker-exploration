# Chapter 3: PoC 1 - Quantifying the Problem

## Overview

In the previous chapters, we learned why naive linking fails. Now let's **measure** it! This proof-of-concept compares a naive attempt to link Haskell object files with a standard linker (lld) versus the comprehensive linking command that GHC constructs.

## What This PoC Does

1. **Creates a minimal Haskell program** that prints "Hello, Haskell!"
2. **Compiles to object file** using GHC's LLVM backend
3. **Attempt 1 (Naive)**: Tries to link with `lld` directly, providing only basic C libraries
4. **Attempt 2 (Correct)**: Uses `ghc` as the driver to construct the proper link command
5. **Quantifies the difference**: Shows how GHC's command has 100+ more arguments

## The Setup

### The Source Code

```haskell
-- Hello.hs
main :: IO ()
main = putStrLn "Hello, Haskell!"
```

That's it! A simple 2-line program. Let's see what it takes to link it.

### Compiling to Object File

```bash
$ ghc -fllvm -c Hello.hs -o Hello.o
```

This produces:
- `Hello.o` - The compiled object file containing our `main` function
- `Hello.hi` - GHC's interface file (metadata about the module)

The object file contains standard ELF machine code. So far, so good!

## Attempt 1: The Naive Way (FAILS)

Let's try linking with `lld` directly:

```bash
$ ld.lld -o hello_fail Hello.o -lc -lm -lpthread -ldl
```

We're providing:
- Our object file (`Hello.o`)
- C standard library (`-lc`)
- Math library (`-lm`)
- Threading library (`-lpthread`)
- Dynamic linking library (`-ldl`)

That should be enough, right? **WRONG!**

### The Result: Spectacular Failure

```
ld.lld: error: undefined symbol: base_GHCziTopHandler_flushStdHandles_closure
>>> referenced by Hello.o
ld.lld: error: undefined symbol: base_GHCziIOziHandleziFD_stdout_closure
>>> referenced by Hello.o
ld.lld: error: undefined symbol: ghczmprim_GHCziTypes_True_closure
>>> referenced by Hello.o
ld.lld: error: undefined symbol: base_GHCziShow_zdfShowChar_closure
>>> referenced by Hello.o
ld.lld: error: undefined symbol: stg_ap_0_fast
>>> referenced by Hello.o
[... 95+ more undefined references ...]
```

The linker is missing:
- ❌ All **Haskell base library** functions
- ❌ The **STG** (Spineless Tagless G-machine) implementation
- ❌ The entire **Runtime System (RTS)**

### Understanding the Symbols

Let's decode some of these error messages:

| Symbol | Meaning |
|--------|---------|
| `base_GHCziTopHandler_flushStdHandles_closure` | A closure from the `base` package, `GHC.TopHandler` module (`zi` = `.` in Z-encoding) |
| `stg_ap_0_fast` | Part of the STG machine - application of a 0-argument function (fast calling convention) |
| `ghczmprim_GHCziTypes_True_closure` | The `True` constructor from `ghc-prim` package (`zmprim` = `-prim` in Z-encoding) |

These aren't standard C symbols—they're Haskell-specific runtime constructs!

## Attempt 2: The GHC Way (SUCCEEDS)

Now let's do it the right way:

```bash
$ ghc -v -fllvm Hello.hs -o hello_success
```

The `-v` flag shows us what GHC is actually doing. Let's see:

### The Massive Linker Command

GHC constructs a linker command with **140+ arguments**!

Here's an abbreviated version (the real one is much longer):

```bash
/usr/bin/ld \
  -o hello_success \

  # Startup code
  /usr/lib/ghc-9.4.8/rts/lib/x86_64-linux-ghc-9.4.8/Scrt1.o \
  /usr/lib/ghc-9.4.8/rts/lib/x86_64-linux-ghc-9.4.8/crti.o \
  /usr/lib/gcc/x86_64-linux-gnu/11/crtbeginS.o \

  # Your code
  Hello.o \

  # Haskell standard libraries (static archives)
  /usr/lib/ghc-9.4.8/base-4.17.2.1/libHSbase-4.17.2.1.a \
  /usr/lib/ghc-9.4.8/ghc-prim-0.9.1/libHSghc-prim-0.9.1.a \
  /usr/lib/ghc-9.4.8/integer-gmp-1.1.2.0/libHSinteger-gmp-1.1.2.0.a \
  /usr/lib/ghc-9.4.8/array-0.5.4.0/libHSarray-0.5.4.0.a \
  /usr/lib/ghc-9.4.8/deepseq-1.4.8.0/libHSdeepseq-1.4.8.0.a \
  [... 10+ more Haskell libraries ...]

  # The Runtime System!
  /usr/lib/ghc-9.4.8/rts/libHSrts.a \

  # System libraries
  -lgmp \
  -ldl \
  -lpthread \
  -lm \
  -lc \

  # Shutdown code
  /usr/lib/gcc/x86_64-linux-gnu/11/crtendS.o \
  /usr/lib/ghc-9.4.8/rts/lib/x86_64-linux-ghc-9.4.8/crtn.o \

  [... plus 100+ more flags and arguments ...]
```

### The Result: Success!

```bash
$ ./hello_success
Hello, Haskell!
```

It works! ✅

## The Comparison

| Aspect | Naive lld | GHC Driver |
|--------|-----------|------------|
| **Arguments** | 7 | **140+** |
| **Your code** | ✅ Hello.o | ✅ Hello.o |
| **Runtime System** | ❌ Missing | ✅ libHSrts.a |
| **Base library** | ❌ Missing | ✅ libHSbase-4.17.2.1.a |
| **Primitives** | ❌ Missing | ✅ libHSghc-prim-0.9.1.a |
| **Other boot libs** | ❌ Missing | ✅ 10+ more libraries |
| **Result** | ❌ **100+ errors** | ✅ **Works perfectly** |

## Key Insights

### 1. The Argument Count Difference

- **Naive command**: 7 arguments
- **GHC's command**: 140+ arguments

This isn't just about quantity—it's about GHC acting as the **"general contractor"** that knows:
1. Which RTS variant to use (threaded, dynamic, profiling, etc.)
2. The complete dependency graph of all Haskell packages
3. The correct topological order for linking
4. Platform-specific requirements and calling conventions

### 2. What GHC Provides

#### Runtime System (RTS)
- Garbage collector
- Thread scheduler (green threads)
- Heap management
- Exception handling
- FFI support

**Total size**: ~5MB of compiled code

#### Standard Libraries
- `base` (700+ modules): Core Prelude and standard functions
- `ghc-prim`: Compiler primitives and basic types
- `integer-gmp`: Arbitrary-precision arithmetic
- And many more boot libraries

#### Startup/Shutdown Code
- Proper initialization of the RTS
- Setting up the Haskell calling convention
- Registering exception handlers
- Cleanup code for program exit

### 3. Why Order Matters

The linker processes libraries in order. If library A depends on library B, then A must come *before* B in the linker command. GHC knows this dependency graph and constructs the correct order.

Try this:
```bash
# Wrong order - might fail!
$ ld -o prog Hello.o -lHSrts -lHSbase

# Right order - works!
$ ld -o prog Hello.o -lHSbase -lHSghc-prim -lHSrts -lgmp
```

Actually, neither will work without GHC because the libraries aren't even in the standard search path! GHC knows where they are.

## Running the PoC

### With Docker (Recommended)

No GHC installation required! The Docker image includes everything.

```bash
# From the repository root
docker build -t ghc-linker-poc .
docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh
```

### Locally (Requires GHC and LLVM)

```bash
cd poc1-linker-comparison
./build.sh
```

**Prerequisites**:
- GHC ≥ 9.0
- LLVM ≥ 18 (for lld)

### What You'll See

The script will:
1. ✅ Compile `Hello.hs` to `Hello.o`
2. ❌ Attempt linking with `lld` (fails with 100+ errors)
3. ✅ Link with `ghc` (succeeds)
4. ✅ Run the resulting executable
5. 📊 Compare the two linker commands side-by-side

## Files in This Directory

```
poc1-linker-comparison/
├── README.md                   # Detailed documentation
├── build.sh                    # Main demonstration script
├── Hello.hs                    # The simple Haskell program
└── analysis/
    └── compare_commands.sh     # Helper to analyze linker commands
```

## Exercises

Try these experiments to deepen your understanding:

### Exercise 1: Explore the Object File

```bash
$ ghc -fllvm -c Hello.hs
$ objdump -t Hello.o | grep -i main
$ nm Hello.o | grep -i main
```

What symbols do you see? Are they standard C symbols or Haskell-specific?

### Exercise 2: Try Different Backends

```bash
# NCG (Native Code Generator) - default
$ ghc -c Hello.hs
$ size Hello.o

# LLVM backend
$ ghc -fllvm -c Hello.hs
$ size Hello.o
```

Is there a size difference? Why or why not?

### Exercise 3: Verbose GHC Output

```bash
$ ghc -v3 Hello.hs -o hello 2>&1 | tee ghc_output.log
```

Read through `ghc_output.log`. Can you find:
- The actual linker command?
- All the libraries being linked?
- The RTS variant being used?

---

## Next Steps

Now that we've **seen** the problem, let's explore why this matters for **FFI** (calling Haskell from other languages).

**Next chapter**: [PoC 2: FFI Integration →](./04-poc2-ffi-integration.md)

---

## Quick Navigation

- **Previous**: [← Two Critical Misconceptions](../part-1-understanding/02-misconceptions.md)
- **Next**: [PoC 2: FFI Integration →](./04-poc2-ffi-integration.md)
- **Deep Dive**: [The Linking Process →](../part-3-deep-dive/08-linking-process.md)
