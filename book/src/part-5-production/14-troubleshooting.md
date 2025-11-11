# Chapter 14: Troubleshooting

## Common Problems and Solutions

This chapter provides **solutions to common issues** when working with Haskell FFI and linking.

## Linking Errors

### Problem: Undefined Reference to C Function

**Error**:

```
undefined reference to `my_c_function'
```

**Cause**: The C object file isn't being linked.

**Solutions**:

**1. Link the object file directly**:

```bash
# Compile C code
gcc -c mylib.c -o mylib.o

# Link with GHC
ghc MyProgram.hs mylib.o -o program
```

**2. Or link the library**:

```bash
ghc MyProgram.hs -lmylib -L/path/to/lib
```

**3. For Cabal projects**, add to `.cabal` file:

```cabal
library
  c-sources: cbits/mylib.c
  -- or
  extra-libraries: mylib
  extra-lib-dirs: /usr/local/lib
```

### Problem: Undefined Reference to Haskell Symbol

**Error**:

```
undefined reference to `base_GHCziIO_...`
undefined reference to `stg_ap_0_fast`
```

**Cause**: Trying to link with a non-GHC linker.

**Solution**: **Always use GHC as the linker**:

```bash
# ❌ Wrong
gcc main.o MyLib.o -o program

# ✅ Correct
ghc main.o MyLib.o -o program
```

For C `main()`, use `-no-hs-main`:

```bash
ghc -no-hs-main main.o MyLib.o -o program
```

### Problem: Cannot Find Library

**Error**:

```
cannot find -lmylib
```

**Cause**: Library not in default search paths.

**Solutions**:

**1. Add library directory**:

```bash
ghc MyProgram.hs -lmylib -L/usr/local/lib
```

**2. Set environment variable**:

```bash
export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
ghc MyProgram.hs -lmylib
```

**3. For Cabal**:

```cabal
extra-lib-dirs: /usr/local/lib
```

**4. For Stack**:

```yaml
# stack.yaml
extra-lib-dirs:
  - /usr/local/lib
```

### Problem: Wrong RTS Variant

**Error**:

```
ghc: the flag -threaded requires the program to be linked
with the threaded RTS
```

**Cause**: Compiled with `-threaded` but linking without it.

**Solution**: Be consistent:

```bash
# Compile AND link with -threaded
ghc -threaded MyProgram.hs -o program

# Or don't use -threaded at all
ghc MyProgram.hs -o program
```

## Runtime Errors

### Problem: Segmentation Fault

**Symptoms**:

```
Segmentation fault (core dumped)
```

**Common Causes**:

**1. Null pointer dereference**:

```haskell
-- ❌ Bad: No null check
processString :: CString -> IO ()
processString ptr = do
    str <- peekCString ptr  -- Crashes if ptr is NULL!
    putStrLn str
```

```haskell
-- ✅ Good: Check for NULL
import Foreign.Ptr (nullPtr)

processString :: CString -> IO ()
processString ptr
    | ptr == nullPtr = putStrLn "NULL string"
    | otherwise = do
        str <- peekCString ptr
        putStrLn str
```

**2. Memory not allocated**:

```haskell
-- ❌ Bad: Using uninitialized pointer
badAlloc :: IO ()
badAlloc = do
    ptr <- malloc :: IO (Ptr CInt)
    -- Forgot to poke!
    value <- peek ptr  -- Garbage!
    print value
```

```haskell
-- ✅ Good: Initialize memory
goodAlloc :: IO ()
goodAlloc = do
    ptr <- malloc :: IO (Ptr CInt)
    poke ptr 42
    value <- peek ptr
    print value
    free ptr
```

**3. Using `unsafe` for blocking calls**:

```haskell
-- ❌ Bad: Blocks RTS
foreign import ccall unsafe "blocking_io"
    c_blocking :: IO ()  -- RTS can't handle this!
```

```haskell
-- ✅ Good: Use safe
foreign import ccall safe "blocking_io"
    c_blocking :: IO ()
```

**4. Not calling `hs_init()` before Haskell code**:

```c
// ❌ Bad
int main(int argc, char *argv[]) {
    hs_fibonacci(10);  // RTS not initialized!
    return 0;
}
```

```c
// ✅ Good
int main(int argc, char *argv[]) {
    hs_init(&argc, &argv);
    hs_fibonacci(10);
    hs_exit();
    return 0;
}
```

**Debugging**:

```bash
# Build with debug symbols
ghc -g -debug MyProgram.hs

# Run with stack trace
./MyProgram +RTS -xc

# Or use gdb
gdb ./MyProgram
(gdb) run
(gdb) backtrace
```

### Problem: Memory Leak

**Symptoms**: Memory usage grows over time.

**Common Causes**:

**1. Forgetting to `free` malloc'd memory**:

```haskell
-- ❌ Bad: Memory leak
leak :: IO ()
leak = do
    ptr <- malloc :: IO (Ptr CInt)
    poke ptr 42
    -- Forgot to free!
```

```haskell
-- ✅ Good: Always free
noLeak :: IO ()
noLeak = bracket
    (malloc :: IO (Ptr CInt))
    free
    (\ptr -> poke ptr 42)
```

**2. Not freeing stable pointers**:

```haskell
-- ❌ Bad: StablePtr leak
foreign export ccall create :: IO (StablePtr Foo)

create :: IO (StablePtr Foo)
create = do
    foo <- makeFoo
    newStablePtr foo  -- C must call destroy!

-- Must also export:
foreign export ccall destroy :: StablePtr Foo -> IO ()

destroy :: StablePtr Foo -> IO ()
destroy = freeStablePtr
```

**3. Not freeing function pointers**:

```haskell
-- ❌ Bad: FunPtr leak
registerCallback :: IO ()
registerCallback = do
    fp <- mkCallback myCallback
    c_register fp
    -- Forgot to save fp for later freeing!
```

```haskell
-- ✅ Good: Save and free
data Context = Context { callbackPtr :: FunPtr Callback }

initialize :: IO Context
initialize = do
    fp <- mkCallback myCallback
    c_register fp
    return $ Context fp

cleanup :: Context -> IO ()
cleanup ctx = freeHaskellFunPtr (callbackPtr ctx)
```

**Detecting Leaks**:

```bash
# Heap profiling
ghc -prof -fprof-auto MyProgram.hs
./MyProgram +RTS -hc -p

# Analyze
hp2ps -c MyProgram.hp
```

### Problem: Stack Overflow

**Error**:

```
Stack space overflow: current size 8388608 bytes.
```

**Cause**: Usually deep recursion without tail-call optimization.

**Solutions**:

**1. Increase stack size** (temporary):

```bash
./MyProgram +RTS -K64m  # 64MB stack
```

**2. Make function tail-recursive** (permanent):

```haskell
-- ❌ Bad: Not tail-recursive
sum :: [Int] -> Int
sum [] = 0
sum (x:xs) = x + sum xs  -- Stack builds up

-- ✅ Good: Tail-recursive
sum :: [Int] -> Int
sum = go 0
  where
    go acc [] = acc
    go acc (x:xs) = go (acc + x) xs  -- Tail call
```

**3. Use strict accumulator**:

```haskell
import Data.List (foldl')

sum :: [Int] -> Int
sum = foldl' (+) 0  -- Strict left fold
```

## Build Errors

### Problem: Cannot Find Header File

**Error**:

```
fatal error: mylib.h: No such file or directory
```

**Solutions**:

**1. Add include directory**:

```bash
gcc -c mycode.c -I/usr/local/include
```

**2. For Cabal**:

```cabal
include-dirs: cbits, /usr/local/include
```

**3. For Stack**:

```yaml
extra-include-dirs:
  - /usr/local/include
```

### Problem: ABI Incompatibility

**Error**:

```
error: symbol X has multiple definitions
```

**Cause**: Mixing GHC versions or linking against wrong RTS.

**Solution**: Rebuild everything with same GHC version:

```bash
# Clean everything
cabal clean
# Or
stack clean --full

# Rebuild
cabal build
# Or
stack build
```

### Problem: Package Registration Errors

**Error**:

```
cannot satisfy -package mypackage
```

**Solution**:

```bash
# Update package database
ghc-pkg recache

# Check what's registered
ghc-pkg list mypackage

# If broken, unregister and reinstall
ghc-pkg unregister mypackage
cabal install mypackage
```

## Performance Issues

### Problem: Unexpected Slowness

**Debugging Steps**:

**1. Profile**:

```bash
ghc -prof -fprof-auto -rtsopts MyProgram.hs
./MyProgram +RTS -p
cat MyProgram.prof
```

**2. Check for accidental thunks**:

```haskell
-- ❌ Bad: Builds thunks
sum = foldl (+) 0

-- ✅ Good: Strict
sum = foldl' (+) 0
```

**3. Check FFI safety level**:

```haskell
-- ❌ Slow: Using safe unnecessarily
foreign import ccall safe "fast_math"
    c_fast :: CDouble -> CDouble

-- ✅ Fast: Use unsafe for fast functions
foreign import ccall unsafe "fast_math"
    c_fast :: CDouble -> CDouble
```

**4. Check for repeated FFI calls**:

```haskell
-- ❌ Bad: N FFI calls
process = mapM callFFI items

-- ✅ Good: 1 FFI call
process = withArray items $ \ptr ->
    c_process_batch ptr (length items)
```

### Problem: GC Pauses

**Symptoms**: Periodic freezes.

**Solutions**:

**1. Increase nursery size**:

```bash
./MyProgram +RTS -A128m  # 128MB nursery
```

**2. Use concurrent GC**:

```bash
./MyProgram +RTS -qg
```

**3. Disable idle GC**:

```bash
./MyProgram +RTS -I0
```

**4. Profile GC**:

```bash
./MyProgram +RTS -s  # GC statistics
```

## Debugging Tools

### GDB

**For C crashes**:

```bash
# Build with debug symbols
ghc -g -debug MyProgram.hs

# Run in gdb
gdb ./MyProgram
(gdb) run
(gdb) backtrace
(gdb) print variable
```

### ThreadScope

**For parallel programs**:

```bash
# Build with eventlog
ghc -threaded -eventlog MyProgram.hs

# Run with eventlog enabled
./MyProgram +RTS -l

# View in ThreadScope
threadscope MyProgram.eventlog
```

### Valgrind

**For memory issues** (with care):

```bash
# Build position-independent
ghc -fPIC -dynamic MyProgram.hs

# Run valgrind
valgrind --leak-check=full ./MyProgram
```

**Note**: Valgrind has false positives with GHC's GC.

## Getting Help

### Information to Provide

When asking for help, include:

1. **GHC version**: `ghc --version`
2. **OS and architecture**: `uname -a`
3. **Full error message**
4. **Minimal reproduction**: Smallest code that shows the problem
5. **Build commands used**
6. **Cabal/Stack configuration**

### Resources

- **GHC Issue Tracker**: [https://gitlab.haskell.org/ghc/ghc/-/issues](https://gitlab.haskell.org/ghc/ghc/-/issues)
- **Haskell Discourse**: [https://discourse.haskell.org/](https://discourse.haskell.org/)
- **Stack Overflow**: Tag: `[haskell]` and `[ffi]`
- **Reddit**: [r/haskell](https://reddit.com/r/haskell)

---

## Summary

Key takeaways:

1. ✅ **Always use GHC as linker** for Haskell code
2. ✅ **Check for NULL** before dereferencing
3. ✅ **Use bracket** for resource management
4. ✅ **Profile before optimizing**
5. ✅ **Provide minimal reproductions** when asking for help

**Next**: [Rust vs Haskell →](./15-rust-vs-haskell.md)

---

## Quick Navigation

- **Previous**: [← Best Practices](./13-best-practices.md)
- **Next**: [Rust vs Haskell →](./15-rust-vs-haskell.md)
- **Related**: [FFI Guide →](../part-3-deep-dive/09-ffi-guide.md)
