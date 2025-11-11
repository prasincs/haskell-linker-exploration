# Chapter 13: Best Practices

## Production-Ready Integration

This chapter covers **best practices** for building production systems with Haskell FFI or gRPC integration.

## FFI Best Practices

### 1. Always Use Type-Safe Wrappers

**Don't expose raw FFI imports**:

```haskell
-- ❌ Bad: Raw C types in public API
module MyAPI (c_add) where

foreign import ccall "add"
    c_add :: CInt -> CInt -> CInt
```

**Do wrap with Haskell types**:

```haskell
-- ✅ Good: Type-safe wrapper
module MyAPI (add) where

import Foreign.C.Types

foreign import ccall "add"
    c_add :: CInt -> CInt -> CInt

-- Public API uses native Haskell types
add :: Int -> Int -> Int
add x y = fromIntegral $ c_add (fromIntegral x) (fromIntegral y)
```

**Why**: Prevents type confusion and makes API more Haskell-idiomatic.

### 2. Resource Management with Bracket

**Always use `bracket` for resource cleanup**:

```haskell
import Control.Exception (bracket)

-- ❌ Bad: Manual cleanup (can leak on exception)
openFile :: FilePath -> IO Handle
openFile path = do
    handle <- c_open path
    -- If error occurs here, handle leaks!
    return handle

-- ✅ Good: Exception-safe cleanup
withFile :: FilePath -> (Handle -> IO a) -> IO a
withFile path action = bracket
    (c_open path)        -- Acquire
    c_close              -- Release (always runs)
    action               -- Use
```

**Pattern**: Use `with*` functions that take a callback.

### 3. Error Handling

**Check return values and set up proper error handling**:

```haskell
-- ❌ Bad: Ignore errors
doThing :: IO ()
doThing = do
    _ <- c_risky_operation
    return ()

-- ✅ Good: Explicit error handling
doThing :: IO (Either String ())
doThing = do
    result <- c_risky_operation
    if result == 0
        then return (Right ())
        else do
            errno <- getErrno
            msg <- strerror errno
            return (Left msg)
```

**For system calls, use `throwErrnoIfMinus1`**:

```haskell
import Foreign.C.Error

safeSyscall :: IO CInt
safeSyscall = throwErrnoIfMinus1 "syscall" c_syscall
```

### 4. Memory Safety

**Use `withArray` and `allocaArray` for temporary arrays**:

```haskell
-- ✅ Good: Temporary array
processData :: [Int] -> IO ()
processData xs =
    withArray (map fromIntegral xs) $ \ptr ->
        c_process_array ptr (fromIntegral $ length xs)

-- ✅ Good: Allocate output array
getData :: Int -> IO [Int]
getData n =
    allocaArray n $ \ptr -> do
        c_fill_array ptr (fromIntegral n)
        fmap (map fromIntegral) $ peekArray n ptr
```

**Never**: Return pointers to stack-allocated memory!

### 5. Safety Annotations

**Choose the right safety level**:

```haskell
-- Fast math operations: unsafe
foreign import ccall unsafe "math.h sin"
    c_sin :: CDouble -> CDouble

-- I/O operations: safe
foreign import ccall safe "unistd.h read"
    c_read :: CInt -> Ptr () -> CSize -> IO CSsize

-- Blocking operations: safe or interruptible
foreign import ccall interruptible "poll"
    c_poll :: Ptr () -> CInt -> CInt -> IO CInt
```

**Guidelines**:
- **unsafe**: < 1μs, never blocks, never calls Haskell
- **safe**: Any I/O, might block, might call back
- **interruptible**: Long-running, supports async exceptions

### 6. Stable Pointers for Callbacks

**When C needs to hold Haskell data**:

```haskell
import Foreign.StablePtr

-- Export creation/destruction functions
foreign export ccall createContext :: IO (StablePtr Context)
foreign export ccall destroyContext :: StablePtr Context -> IO ()
foreign export ccall useContext :: StablePtr Context -> IO ()

createContext :: IO (StablePtr Context)
createContext = do
    ctx <- initializeContext
    newStablePtr ctx

destroyContext :: StablePtr Context -> IO ()
destroyContext = freeStablePtr

useContext :: StablePtr Context -> IO ()
useContext sptr = do
    ctx <- deRefStablePtr sptr
    processContext ctx
```

**Remember**: C must call the destroy function!

## Build System Integration

### Cabal Configuration

**Setup FFI dependencies in `.cabal` file**:

```cabal
name:                my-ffi-project
version:             0.1.0.0

library
  exposed-modules:   MyLib
  build-depends:     base >= 4.7 && < 5

  -- C sources
  c-sources:         cbits/mylib.c

  -- Include directories
  include-dirs:      cbits

  -- Extra libraries to link
  extra-libraries:   m, pthread

  -- Link options
  ld-options:        -L/usr/local/lib

  -- C compiler options
  cc-options:        -Wall -O2

  default-language:  Haskell2010
```

### Stack Configuration

**Configure Stack to find system libraries**:

```yaml
# stack.yaml
resolver: lts-20.0

extra-deps: []

extra-lib-dirs:
  - /usr/local/lib

extra-include-dirs:
  - /usr/local/include

flags:
  my-package:
    use-system-lib: true
```

### Build Scripts

**Provide build scripts for complex setups**:

```bash
#!/bin/bash
set -e

# build.sh - Build FFI project

echo "Building C library..."
gcc -c -O2 -fPIC cbits/mylib.c -o cbits/mylib.o

echo "Building Haskell library..."
cabal build

echo "Running tests..."
cabal test

echo "Build complete!"
```

## Testing Strategies

### Unit Testing

**Test Haskell wrappers separately from C code**:

```haskell
-- test/Spec.hs
import Test.Hspec
import MyAPI

main :: IO ()
main = hspec $ do
    describe "add" $ do
        it "adds two numbers" $ do
            add 2 3 `shouldBe` 5

        it "handles negative numbers" $ do
            add (-1) 5 `shouldBe` 4

        it "handles large numbers" $ do
            add 1000000 2000000 `shouldBe` 3000000
```

### Property Testing

**Use QuickCheck for property-based testing**:

```haskell
import Test.QuickCheck

prop_add_commutative :: Int -> Int -> Bool
prop_add_commutative x y = add x y == add y x

prop_add_associative :: Int -> Int -> Int -> Bool
prop_add_associative x y z =
    add (add x y) z == add x (add y z)

main :: IO ()
main = do
    quickCheck prop_add_commutative
    quickCheck prop_add_associative
```

### Integration Testing

**Test the full FFI boundary**:

```haskell
-- test/Integration.hs
import Test.Hspec
import Foreign.C.Types
import Control.Exception

main :: IO ()
main = hspec $ do
    describe "FFI integration" $ do
        it "handles errors correctly" $ do
            result <- try $ processInvalidInput
            result `shouldSatisfy` isLeft

        it "cleans up resources on exception" $ do
            before <- getResourceCount
            _ <- try $ processWithException
            after <- getResourceCount
            after `shouldBe` before
```

### Memory Leak Testing

**Use `-prof` and heap profiling**:

```bash
# Build with profiling
ghc -prof -fprof-auto MyProgram.hs

# Run with heap profiling
./MyProgram +RTS -hc -p

# Analyze results
hp2ps -c MyProgram.hp
ps2pdf MyProgram.ps
```

## Logging and Observability

### Structured Logging

**Use `katip` or `fast-logger` for structured logs**:

```haskell
import Katip

logFFICall :: KatipContext m => Text -> m ()
logFFICall funcName = do
    $(logTM) InfoS $ logStr $
        "Calling FFI function: " <> funcName

processData :: KatipContext m => ByteString -> m Result
processData input = do
    logFFICall "c_process"
    result <- liftIO $ c_process input
    $(logTM) InfoS $ ls ("FFI result" :: Text) <> showLS result
    return result
```

### Metrics

**Track FFI call metrics**:

```haskell
import System.Metrics
import System.Metrics.Counter

data Metrics = Metrics
    { ffiCalls :: Counter
    , ffiErrors :: Counter
    , ffiLatency :: Distribution
    }

withMetrics :: Metrics -> IO a -> IO a
withMetrics metrics action = do
    Counter.inc (ffiCalls metrics)
    start <- getTime
    result <- action `catch` \e -> do
        Counter.inc (ffiErrors metrics)
        throwIO e
    end <- getTime
    Distribution.add (ffiLatency metrics) (end - start)
    return result
```

## Performance Optimization

### Profile First

**Don't optimize without profiling**:

```bash
# 1. Build with profiling
ghc -prof -fprof-auto -rtsopts MyProgram.hs

# 2. Run with time/allocation profiling
./MyProgram +RTS -p

# 3. Analyze
cat MyProgram.prof
```

### Use `unsafe` for Hot Paths

**After profiling identifies hot paths**:

```haskell
-- Before optimization (safe)
foreign import ccall safe "compute"
    c_compute :: CInt -> IO CInt

-- After profiling shows this is hot path (unsafe)
foreign import ccall unsafe "compute"
    c_compute_fast :: CInt -> CInt
```

**Measure improvement**: Expected 5-10x speedup for simple functions.

### Batch Operations

**Reduce FFI call overhead**:

```haskell
-- ❌ Bad: Call for each item
process :: [Int] -> IO [Int]
process = mapM (\x -> c_process (fromIntegral x))

-- ✅ Good: Batch processing
processBatch :: [Int] -> IO [Int]
processBatch xs =
    withArray (map fromIntegral xs) $ \inPtr ->
    allocaArray (length xs) $ \outPtr -> do
        c_process_array inPtr outPtr (fromIntegral $ length xs)
        fmap (map fromIntegral) $ peekArray (length xs) outPtr
```

## Documentation

### Haddock Comments

**Document FFI functions thoroughly**:

```haskell
-- | Add two integers using C's addition.
--
-- This is a wrapper around the C @add@ function. It handles
-- type conversion between Haskell's 'Int' and C's @int@.
--
-- >>> add 2 3
-- 5
--
-- __Note__: This function is pure and cannot fail.
add :: Int -> Int -> Int
add x y = fromIntegral $ c_add (fromIntegral x) (fromIntegral y)

-- | Low-level C addition function.
--
-- __Warning__: This is a low-level function. Use 'add' instead.
foreign import ccall "add"
    c_add :: CInt -> CInt -> CInt
```

### README

**Provide clear build instructions**:

```markdown
## Building

### Prerequisites

- GHC >= 9.0
- C compiler (gcc or clang)
- Required C libraries: libfoo

### Build Steps

1. Install C dependencies:
   ```
   apt-get install libfoo-dev
   ```

2. Build with Cabal:
   ```
   cabal build
   ```

3. Run tests:
   ```
   cabal test
   ```

### Troubleshooting

**Error: undefined reference to `foo`**

Solution: Install libfoo-dev

**Error: cannot find -lfoo**

Solution: Add library path with:
```
cabal build --extra-lib-dirs=/usr/local/lib
```
```

## Deployment

### Static Linking

**For easier deployment**:

```bash
# Build statically linked binary
ghc -static -optl-static MyProgram.hs

# Verify
ldd MyProgram
# Should show: "not a dynamic executable"
```

**Trade-off**: Larger binary (~10-50 MB) but no dependencies.

### Docker

**Create reproducible environment**:

```dockerfile
FROM haskell:9.4.8

WORKDIR /app

# Install C dependencies
RUN apt-get update && apt-get install -y \
    libfoo-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy source
COPY . .

# Build
RUN cabal update && cabal build

CMD ["cabal", "run", "my-program"]
```

## Further Reading

- **Troubleshooting**: [→ Chapter 14](./14-troubleshooting.md)
- **FFI Guide**: [→ Chapter 9](../part-3-deep-dive/09-ffi-guide.md)
- **Full FFI docs**: [`../../docs/ffi-guide.md`](../../docs/ffi-guide.md)

---

## Summary

Key takeaways:

1. ✅ **Type-safe wrappers** protect against errors
2. ✅ **Resource management** with bracket
3. ✅ **Error handling** is critical
4. ✅ **Testing** at all levels (unit, property, integration)
5. ✅ **Profile before optimizing**

**Next**: [Troubleshooting →](./14-troubleshooting.md)

---

## Quick Navigation

- **Previous**: [← Decision Framework](./12-decision-framework.md)
- **Next**: [Troubleshooting →](./14-troubleshooting.md)
- **Related**: [FFI Guide →](../part-3-deep-dive/09-ffi-guide.md)
