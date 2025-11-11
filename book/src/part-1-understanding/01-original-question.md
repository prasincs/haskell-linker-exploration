# Chapter 1: The Original Question

## The Spark

A while ago, I had a conversation that kicked off this deep dive into how Haskell is *actually* put together:

> *"Since many modern languages (like Rust and Haskell) can use an LLVM backend, shouldn't they all just compile down to a common format? And if they do, can't we just use a fast, modern linker like lld to link them all together?"*

This question seems perfectly reasonable. After all, if we have:

```
Haskell Source → LLVM IR → Object File (.o)
Rust Source → LLVM IR → Object File (.o)
```

Then shouldn't we be able to:

```
$ ld.lld -o my_program *.o -lc
# Done!
```

## The Assumption

My assumption was simple and logical:

1. **Haskell** can use the LLVM backend (via `-fllvm` flag)
2. LLVM produces **standard object files** (`.o` files)
3. Object files contain **machine code** and **symbols**
4. Modern linkers like **lld** can link object files
5. Therefore: I should be able to **link Haskell object files with lld**

**This assumption is wrong in two different and important ways.**

And digging into *why* reveals the secret role of the Glasgow Haskell Compiler (GHC) and the "special sauce" that makes a Haskell program run.

## What This Book Will Teach You

By exploring this seemingly simple question, we'll uncover:

### 1. **What GHC Really Is**
GHC isn't just a compiler—it's a **build orchestrator** and **driver** that coordinates an entire ecosystem of tools and libraries.

### 2. **The Hidden Runtime System**
Every Haskell program runs on top of a sophisticated **Runtime System (RTS)** that provides:
- Garbage collection
- Green thread scheduling
- Lazy evaluation heap management
- Exception handling
- FFI (Foreign Function Interface) support

This RTS is ~5MB of compiled code that *must* be linked into every Haskell program.

### 3. **The Massive Dependency Tree**
A simple "Hello, World" in Haskell doesn't just link against `libc`. It links against:
- `base` (the standard Prelude)
- `ghc-prim` (compiler primitives)
- `integer-gmp` (arbitrary-precision arithmetic)
- Plus: `array`, `deepseq`, `template-haskell`, and [many more](../part-3-deep-dive/08-linking-process.md#boot-libraries)

GHC knows about all of these and adds them to the linker command automatically. A naive linker doesn't even know these libraries exist.

### 4. **Why This Matters for Integration**
Understanding this is crucial if you want to:
- **Call Haskell from C/C++** (FFI)
- **Embed Haskell in other applications**
- **Choose between FFI and microservices** architectures
- **Optimize build times and binary sizes**

## The Journey Ahead

In the next chapter, we'll explore the [two critical misconceptions](./02-misconceptions.md) that underpin this question. Then, in Part II, we'll prove everything with runnable code examples.

Here's a preview of what we'll discover:

| Naive Linker Command | GHC's Real Command |
|---------------------|-------------------|
| 7 arguments | **140+ arguments** |
| Links only your code | Links RTS + 10+ libraries |
| **Fails with 100+ undefined references** | **Succeeds perfectly** |

Ready to dive in? Let's explore [the two critical misconceptions](./02-misconceptions.md) next.

---

## Quick Navigation

- **Next**: [Two Critical Misconceptions →](./02-misconceptions.md)
- **Jump ahead**: [PoC 1: See the Difference in Action →](../part-2-proofs/03-poc1-linker-comparison.md)
