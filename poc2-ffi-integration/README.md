# PoC 2: Calling Haskell from C (FFI Integration)

## Overview

This proof-of-concept demonstrates how to call Haskell functions from C code, and why you still need GHC as the linker even when your `main()` function is written in C.

## What This PoC Does

1. **Haskell Library** (`MyLib.hs`): Exports a Fibonacci function via FFI
2. **C Program** (`main.c`): Calls the Haskell function using `hs_init()` and `hs_exit()`
3. **Linking Attempts**:
   - **Fails** with standard C compiler/linker (gcc, clang, lld)
   - **Succeeds** when using `ghc -no-hs-main` as the linker

## The Code

### MyLib.hs - Haskell Library

```haskell
{-# LANGUAGE ForeignFunctionInterface #-}

module MyLib where

import Foreign.C.Types

fibonacci :: Int -> Int
fibonacci 0 = 0
fibonacci 1 = 1
fibonacci n = fibonacci (n-1) + fibonacci (n-2)

-- Export this function to C
foreign export ccall hs_fib :: CInt -> CInt

hs_fib :: CInt -> CInt
hs_fib n = fromIntegral $ fibonacci (fromIntegral n)
```

**Key points**:
- `foreign export ccall` makes the function callable from C
- The function name `hs_fib` is what C will see
- We use `CInt` for C-compatible integer types
- GHC will generate `MyLib_stub.h` with the C declaration

### main.c - C Caller

```c
#include <stdio.h>
#include "HsFFI.h"          // GHC's FFI header
#include "MyLib_stub.h"      // Generated from MyLib.hs

int main(int argc, char *argv[]) {
    // 1. Start the Haskell Runtime System
    hs_init(&argc, &argv);

    // 2. Call our Haskell function
    int n = 10;
    int result = hs_fib(n);
    printf("Haskell calculated fib(%d) = %d\n", n, result);

    // 3. Shut down the RTS
    hs_exit();

    return 0;
}
```

**Key points**:
- `hs_init()` and `hs_exit()` manage the Haskell Runtime System
- Without these, the Haskell code cannot execute
- This is the "manual life support" for Haskell code

## Running the PoC

### With Docker (Recommended)

```bash
# From the repository root
docker build -t ghc-linker-poc -f Dockerfile .
docker run --rm -it ghc-linker-poc ./poc2-ffi-integration/build.sh
```

The script will pause twice to let you see the failures and success.

### Locally (Requires GHC and build tools)

```bash
cd poc2-ffi-integration
./build.sh
```

## Expected Output

### Compilation Phase (SUCCEEDS)

Both the Haskell and C code compile to object files without issue:

```bash
$ ghc -c MyLib.hs
# Creates: MyLib.o, MyLib.hi, MyLib_stub.h

$ cc -c main.c -I.
# Creates: main.o
```

### Linking Attempt 1: With cc (FAILS)

```
--- Attempt 1: Linking with clang/lld (The Wrong Way) ---
Trying with cc as driver...
FAILED (with cc), as expected. Errors:
undefined reference to `__stg_split_marker'
undefined reference to `base_GHCziIOziHandleziFD_stdout_closure'
undefined reference to `base_GHCziShow_zdfShowInt_closure'
undefined reference to `ghczmprim_GHCziTypes_Izh_con_info'
undefined reference to `stg_ap_p_info'
[... and many more]
```

**Why it fails**: Even though we have `MyLib.o`, it references:
- Runtime System functions (`stg_*`)
- Base library closures and primitives
- GHC's internal calling convention machinery

### Linking Attempt 2: With ghc -no-hs-main (SUCCEEDS)

```bash
$ ghc -o my_program_success main.o MyLib.o -no-hs-main

--- Success! ---
Created executable: ./my_program_success
Running it now:

Haskell calculated fib(10) = 55
```

**Why it succeeds**: GHC:
1. Links in the complete Runtime System
2. Finds all dependencies of `MyLib` (base, ghc-prim, etc.)
3. Uses `-no-hs-main` to skip providing its own `main()` function
4. Constructs the proper linker command with 100+ arguments

## The "-no-hs-main" Flag Explained

By default, GHC expects to find a Haskell `main :: IO ()` function and will:
1. Generate its own C `main()` that calls `hs_init()`, runs the Haskell `main`, then calls `hs_exit()`
2. Link that startup code into your executable

When you use `-no-hs-main`, you're telling GHC:
- "I'm providing my own `main()` function (in C)"
- "I'll manually call `hs_init()` and `hs_exit()`"
- "But I still need you to find and link all the Haskell libraries"

## Why This Matters: The "General Contractor" Analogy

Think of it this way:

| Role | In Construction | In Our PoC |
|------|----------------|------------|
| **Architect** | Designs the building | You (writing `MyLib.hs` and `main.c`) |
| **Sub-contractors** | Plumbers, electricians | System linker (ld, lld, gold) |
| **General Contractor** | Coordinates everything | **GHC** |

You can:
- ✅ Choose your architect (write in C, Rust, whatever)
- ✅ Choose your sub-contractors (use lld instead of ld)
- ❌ Skip the general contractor (GHC knows where all the Haskell materials are)

## Real-World Use Cases

This pattern is used when:
1. **Embedding Haskell in existing C/C++ projects**
   - You have a large C++ codebase and want to use Haskell for specific components
   - Example: Using Haskell for parsing, type-checking, or business logic

2. **Writing plugins or shared libraries in Haskell**
   - Creating `.so`/`.dll` files that can be loaded by C programs
   - Example: Audio processing plugins, game logic modules

3. **Integrating Haskell with other language runtimes**
   - Python extensions via ctypes
   - Node.js native addons
   - Ruby C extensions

## Files in This Directory

- `MyLib.hs`: Haskell library with FFI exports
- `main.c`: C program that calls Haskell code
- `build.sh`: Demonstration script showing failure and success
- `README.md`: This file

## Further Reading

See the main [repository README](../README.md) for the complete blog post.

For more on FFI:
- [Comprehensive FFI Guide](../docs/ffi-guide.md)
- [GHC User's Guide: FFI](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/ffi.html)
