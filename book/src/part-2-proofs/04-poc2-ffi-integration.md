# Chapter 4: PoC 2 - FFI Integration

## Overview

In [PoC 1](./03-poc1-linker-comparison.md), we saw that linking a simple Haskell program requires GHC's orchestration. But what if you want to **call Haskell functions from C code**?

This proof-of-concept demonstrates the Foreign Function Interface (FFI) and reveals why you *still* need GHC as the linker, even when your `main()` function is written in C.

## The Question

*"If Haskell compiles to object files, why can't I just link them with my C program using gcc or clang?"*

The answer reveals the essential role of the **Haskell Runtime System** and why it must be "manually started" when calling from C.

## The Code

### Haskell Library (MyLib.hs)

We'll create a simple Fibonacci calculator in Haskell and export it for C to call:

```haskell
{-# LANGUAGE ForeignFunctionInterface #-}

module MyLib where

import Foreign.C.Types

-- Pure Haskell implementation
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
- `{-# LANGUAGE ForeignFunctionInterface #-}` enables FFI
- `foreign export ccall` makes the function callable from C
- The function name `hs_fib` is what C code will see
- We use `CInt` for C-compatible integer types
- GHC will generate `MyLib_stub.h` with the C declaration

### C Program (main.c)

Now let's call our Haskell function from C:

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
- `hs_init(&argc, &argv)` **starts the Haskell Runtime System**
- Without this, the Haskell code cannot execute (would crash!)
- `hs_exit()` **shuts down the RTS** and cleans up resources
- This is the "manual life support" for Haskell code

## Compilation: Both Work Fine

Let's compile each piece separately:

### Compile Haskell Library

```bash
$ ghc -c MyLib.hs
```

This creates:
- `MyLib.o` - The compiled Haskell code
- `MyLib.hi` - GHC's interface file
- `MyLib_stub.h` - C header with the function declaration

**Contents of MyLib_stub.h**:
```c
#include "HsFFI.h"

extern HsInt32 hs_fib(HsInt32 n);
```

### Compile C Program

```bash
$ cc -c main.c -I$(ghc --print-libdir)/include
```

This creates:
- `main.o` - The compiled C code

The `-I` flag tells the compiler where to find `HsFFI.h`.

✅ **Both compile successfully!** No problems yet.

## Linking: Only GHC Works

Now for the critical part—linking these together.

### Attempt 1: With cc (FAILS)

```bash
$ cc -o program main.o MyLib.o -lpthread -ldl
```

**Result**:
```
undefined reference to `__stg_split_marker'
undefined reference to `base_GHCziIOziHandleziFD_stdout_closure'
undefined reference to `base_GHCziShow_zdfShowInt_closure'
undefined reference to `ghczmprim_GHCziTypes_Izh_con_info'
undefined reference to `stg_ap_p_info'
undefined reference to `stg_ap_pp_info'
[... hundreds more errors ...]
```

❌ **Fails spectacularly!**

**Why it fails**: Even though we have `MyLib.o`, it references:
- Runtime System functions (`stg_*`, `hs_init`, `hs_exit`)
- Base library closures and primitives
- GHC's internal calling convention machinery

The C linker has no idea where these symbols are!

### Attempt 2: With ghc -no-hs-main (SUCCEEDS)

```bash
$ ghc -o program main.o MyLib.o -no-hs-main
```

**Result**:
```bash
$ ./program
Haskell calculated fib(10) = 55
```

✅ **Success!**

## The `-no-hs-main` Flag Explained

By default, GHC expects to find a Haskell `main :: IO ()` function and will:
1. Generate its own C `main()` that calls `hs_init()`
2. Run the Haskell `main` function
3. Call `hs_exit()` and return

When you use `-no-hs-main`, you're telling GHC:
- "I'm providing my own `main()` function (in C)"
- "I'll manually call `hs_init()` and `hs_exit()`"
- "But I **still need you** to find and link all the Haskell libraries"

GHC then:
1. ✅ Links in the complete Runtime System
2. ✅ Finds all dependencies of `MyLib` (base, ghc-prim, etc.)
3. ✅ Constructs the proper 140+ argument linker command
4. ❌ Does NOT provide its own `main()` function

## Why This Makes Sense Now

Let's review what we learned:

### From PoC 1
We learned that every Haskell program needs:
- The Runtime System (GC, scheduler, heap)
- Boot libraries (base, ghc-prim, etc.)
- Proper linking order

### New Insight from PoC 2
**The Runtime System doesn't start automatically!**

When there's a Haskell `main`, GHC generates startup code:
```c
// GHC-generated (simplified)
int main(int argc, char *argv[]) {
    hs_init(&argc, &argv);      // Start RTS
    haskell_main();              // Call Haskell main :: IO ()
    hs_exit();                   // Stop RTS
    return 0;
}
```

When there's a C `main`, **you must do this manually**:
```c
// Your responsibility!
int main(int argc, char *argv[]) {
    hs_init(&argc, &argv);      // YOU start the RTS
    // ... call Haskell functions ...
    hs_exit();                   // YOU stop the RTS
    return 0;
}
```

## The "General Contractor" Analogy

Think of it this way:

| Role | In Construction | In Our PoC |
|------|----------------|------------|
| **Architect** | Designs the building | You (writing `MyLib.hs` and `main.c`) |
| **Sub-contractors** | Plumbers, electricians, etc. | System linker (ld, lld, gold) |
| **General Contractor** | Coordinates everything, knows where to get materials | **GHC** |

You can:
- ✅ Choose your architect (write in C, Rust, Python, whatever)
- ✅ Choose your sub-contractors (tell GHC to use lld: `-pgml=lld`)
- ❌ Skip the general contractor (GHC knows where all the Haskell "materials" are)

## Running the PoC

### With Docker (Recommended)

```bash
# From the repository root
docker build -t ghc-linker-poc .
docker run --rm -it ghc-linker-poc ./poc2-ffi-integration/build.sh
```

The script will pause twice to let you see the failures and success.

### Locally (Requires GHC and build tools)

```bash
cd poc2-ffi-integration
./build.sh
```

**Prerequisites**:
- GHC ≥ 9.0
- C compiler (gcc or clang)

### What You'll See

The script will:
1. ✅ Compile `MyLib.hs` → `MyLib.o`, `MyLib_stub.h`
2. ✅ Compile `main.c` → `main.o`
3. ❌ Attempt linking with `cc` (fails with undefined references)
4. ✅ Link with `ghc -no-hs-main` (succeeds)
5. ✅ Run the program: "Haskell calculated fib(10) = 55"

## Real-World Use Cases

This FFI pattern is used when:

### 1. Embedding Haskell in Existing C/C++ Projects
- You have a large C++ codebase
- Want to use Haskell for specific components
- Example: Using Haskell for parsing, type-checking, or business logic

### 2. Writing Plugins or Shared Libraries
- Creating `.so`/`.dll` files loadable by C programs
- Example: Audio processing plugins, game logic modules

### 3. Integrating with Other Language Runtimes
- **Python** extensions via ctypes:
  ```python
  from ctypes import *
  haskell = CDLL('./mylib.so')
  result = haskell.hs_fib(10)
  ```
- **Node.js** native addons
- **Ruby** C extensions

## Performance Considerations

### The Good News
Calling Haskell from C via FFI is **fast**:
- **Latency**: ~10-20 nanoseconds per call
- **Overhead**: Minimal (just a function call)
- **No serialization**: Direct memory access

### The Caveats
1. **RTS Startup**: ~50ms one-time cost for `hs_init()`
2. **Memory**: RTS allocates heap (~5-10MB baseline)
3. **GC Pauses**: If Haskell allocates a lot, GC may pause your C code
4. **Threading**: Must be careful with threaded RTS (`-threaded`)

## Common Pitfalls

### Pitfall 1: Forgetting `hs_init()`

```c
int main() {
    // int result = hs_fib(10);  // CRASH! RTS not initialized
    hs_init(NULL, NULL);         // Must init first!
    int result = hs_fib(10);     // Now it works
    hs_exit();
    return 0;
}
```

### Pitfall 2: Forgetting `hs_exit()`

```c
int main() {
    hs_init(NULL, NULL);
    int result = hs_fib(10);
    // Missing hs_exit()!
    return 0;  // Memory leaks! RTS still running!
}
```

### Pitfall 3: Wrong Include Paths

```bash
$ cc -c main.c  # Error: HsFFI.h not found!
$ cc -c main.c -I$(ghc --print-libdir)/include  # Correct!
```

## Files in This Directory

```
poc2-ffi-integration/
├── README.md          # Detailed documentation
├── build.sh           # Demonstration script
├── MyLib.hs           # Haskell library
└── main.c             # C program that calls Haskell
```

## Exercises

### Exercise 1: Add More Functions

Try exporting another function from Haskell:

```haskell
foreign export ccall hs_factorial :: CInt -> CInt

hs_factorial :: CInt -> CInt
hs_factorial n = fromIntegral $ product [1..fromIntegral n]
```

Then call it from C!

### Exercise 2: Pass Strings

Strings are tricky in FFI. Try this:

```haskell
foreign export ccall hs_reverse :: CString -> IO CString

hs_reverse :: CString -> IO CString
hs_reverse cstr = do
    str <- peekCString cstr
    newCString (reverse str)
```

What memory management issues might arise?

### Exercise 3: Benchmarking

Compare FFI call overhead vs pure C:

```c
// Measure FFI call
clock_t start = clock();
for (int i = 0; i < 1000000; i++) {
    hs_fib(10);
}
clock_t end = clock();
printf("FFI: %f seconds\n", (double)(end - start) / CLOCKS_PER_SEC);
```

---

## Next Steps

FFI is powerful but has build complexity and tight coupling. Is there a more modern approach?

**Next chapter**: [PoC 3: gRPC Alternative →](./05-poc3-grpc-alternative.md)

---

## Quick Navigation

- **Previous**: [← PoC 1: Linker Comparison](./03-poc1-linker-comparison.md)
- **Next**: [PoC 3: gRPC Alternative →](./05-poc3-grpc-alternative.md)
- **Deep Dive**: [FFI Guide →](../part-3-deep-dive/09-ffi-guide.md)
