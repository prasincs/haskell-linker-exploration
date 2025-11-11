# Chapter 15: Rust vs Haskell - Design Philosophies

## Different Tools for Different Goals

This chapter explores the **fundamental design differences** between Rust and Haskell, and why each makes different trade-offs.

**Neither is "better"** - they optimize for different priorities.

## The Core Trade-off: Runtime vs Zero-Cost Abstractions

### Haskell: Rich Runtime

| Aspect | Details |
|--------|---------|
| **Runtime Size** | ~5 MB (RTS) |
| **Garbage Collection** | Automatic GC (generational) |
| **Evaluation** | Lazy by default |
| **Concurrency** | Green threads (M:N) |
| **Memory Model** | Managed heap |

**Philosophy**: Provide powerful abstractions and manage complexity for you.

### Rust: Minimal Runtime

| Aspect | Details |
|--------|---------|
| **Runtime Size** | ~50 KB (stdlib, no runtime) |
| **Memory Management** | Ownership system (compile-time) |
| **Evaluation** | Eager (explicit lazy with `Lazy<T>`) |
| **Concurrency** | OS threads (1:1) or async |
| **Memory Model** | Explicit ownership |

**Philosophy**: Zero-cost abstractions - pay only for what you use.

## Why Rust Can Use Standard Linkers

```rust
// Rust: No runtime needed
fn main() {
    println!("Hello, Rust!");
}
```

**Linking**:

```bash
rustc hello.rs          # Creates hello.o
ld -o hello hello.o -lc # Standard linker works!
```

**Why it works**:

1. ✅ **No runtime system**: No GC, no scheduler
2. ✅ **Standard calling convention**: Uses C ABI
3. ✅ **Minimal dependencies**: Only libc
4. ✅ **Static dispatch**: Generics monomorphized at compile time
5. ✅ **Zero-cost abstractions**: High-level code → efficient machine code

**Haskell cannot do this** because:

1. ❌ Needs RTS (~5 MB) for GC, scheduler, lazy evaluation
2. ❌ Custom calling convention (closures, thunks, info tables)
3. ❌ Complex dependencies (10+ boot libraries)
4. ❌ Dynamic dispatch for type classes
5. ❌ Runtime overhead is inherent to the design

## Comparison Table

### Binary Size

| Program | Haskell (static) | Rust (static) |
|---------|------------------|---------------|
| **"Hello, World"** | ~10 MB | ~500 KB |
| **Medium app** | ~30 MB | ~5 MB |
| **Large app** | ~100 MB | ~20 MB |

**Why**: Haskell includes full RTS + boot libraries. Rust only includes what you use.

### Startup Time

| Runtime | Haskell | Rust |
|---------|---------|------|
| **Initialization** | ~50ms (RTS setup) | <1ms |
| **First GC** | +10ms | N/A |
| **Total** | ~60ms | <1ms |

**When it matters**:
- **Haskell**: Long-running servers (startup amortized)
- **Rust**: CLI tools, serverless functions

### Memory Usage

**Haskell "Hello, World"**:

```
RTS: 5 MB
Heap (initial): 32 MB
Thunks: Variable
Total: ~40 MB minimum
```

**Rust "Hello, World"**:

```
Binary: 500 KB
Stack: 8 MB (default)
Heap: As allocated
Total: ~8 MB minimum
```

**Difference**: Haskell's GC and lazy evaluation require more memory.

### Performance

#### Latency

| Operation | Haskell | Rust | Winner |
|-----------|---------|------|--------|
| **Function call** | ~10ns | ~5ns | Rust |
| **Allocation** | ~20ns (GC) | ~10ns (manual) | Rust |
| **FFI call** | ~50ns | ~5ns | Rust |

**Why Rust is faster**: No GC overhead, direct machine code.

#### Throughput

| Task | Haskell | Rust | Winner |
|------|---------|------|--------|
| **CPU-bound** | Good | Excellent | Rust |
| **I/O-bound** | Excellent | Good | Haskell |
| **Parallel** | Excellent | Good | Haskell |

**Why Haskell wins I/O**: Green threads enable massive concurrency.

**Example**: 1 million concurrent connections:

```haskell
-- Haskell: Trivial
main = do
    replicateM_ 1000000 $ forkIO handleConnection
```

```rust
// Rust: Requires async runtime (Tokio)
// And careful tuning
#[tokio::main(flavor = "multi_thread", worker_threads = 8)]
async fn main() {
    // Can handle, but more complex
}
```

## Design Philosophies

### Haskell: Academic Research Language

**Design priorities** (in order):

1. ✅ **Expressiveness**: Make complex ideas simple to express
2. ✅ **Correctness**: Strong type safety and purity
3. ✅ **Research**: Test new PL concepts
4. ⚠️ **Performance**: Good, but not primary goal
5. ⚠️ **Deployment**: Not optimized for minimal binaries

**Historical context**:
- Created in **1990** by committee of researchers
- Goal: Standardize lazy functional languages
- Focus: Pure functions, type systems, lazy evaluation
- Used for: Compilers, theorem provers, DSLs

**Strengths**:
- Powerful type system (GADTs, type families)
- Lazy evaluation (infinite data structures)
- Purity (referential transparency)
- Concurrency abstractions (STM)

**Trade-offs accepted**:
- Large runtime (worth it for GC + lazy eval)
- Slower startup (worth it for long-running apps)
- Larger binaries (worth it for rapid development)

### Rust: Systems Programming Language

**Design priorities** (in order):

1. ✅ **Safety**: Memory safety without GC
2. ✅ **Zero-cost abstractions**: High-level code, low-level performance
3. ✅ **Predictability**: No hidden costs (GC pauses, etc.)
4. ✅ **Control**: Fine-grained control over resources
5. ✅ **Deployment**: Small, fast, self-contained binaries

**Historical context**:
- Created in **2010** by Mozilla (Graydon Hoare)
- Goal: Safe systems programming (replace C++)
- Focus: Memory safety, concurrency, zero-cost
- Used for: OS kernels, browsers, embedded systems

**Strengths**:
- Memory safety (ownership system)
- No garbage collection
- Predictable performance
- Small runtime overhead

**Trade-offs accepted**:
- Steep learning curve (borrow checker)
- Longer compilation times
- More verbose (lifetime annotations)
- Limited higher-kinded types

## When Each Wins

### Use Haskell When

**1. Correctness is paramount**:

```haskell
-- Financial calculations
-- Type system catches errors at compile time
calculateInterest :: Decimal -> Days -> Interest
calculateInterest principal days =
    principal * (rate days)  -- Types prevent mistakes
```

**Examples**: Financial systems, compilers, blockchain

**2. You need powerful abstractions**:

```haskell
-- Parser combinators
parseJSON :: Parser Value
parseJSON = object <|> array <|> string <|> number
  where
    object = Object <$> brackets (commaSep pair)
```

**Examples**: Parsers, DSLs, protocol implementations

**3. Lazy evaluation fits naturally**:

```haskell
-- Infinite data structures
fibs = 0 : 1 : zipWith (+) fibs (tail fibs)

-- Generate primes lazily
primes = sieve [2..]
  where sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

-- Take only what you need
take 100 primes
```

**Examples**: Stream processing, mathematical computations

**4. Development speed matters**:

```haskell
-- Concise, expressive code
main = do
    users <- fetchUsers
    posts <- forM users fetchPosts
    renderDashboard (zip users posts)
```

**Examples**: Prototypes, research code, internal tools

### Use Rust When

**1. Performance is critical**:

```rust
// Zero-overhead game loop
fn game_loop() {
    loop {
        process_input();   // ~10μs
        update_physics();  // ~100μs
        render();          // ~16ms (60 FPS)
    }
}
```

**Examples**: Game engines, video codecs, databases

**2. Memory usage must be minimal**:

```rust
// Embedded system with 64KB RAM
#![no_std]
use core::mem::size_of;

// Every byte counts
assert_eq!(size_of::<MyStruct>(), 24);
```

**Examples**: Embedded systems, IoT devices, kernel modules

**3. You need predictable performance**:

```rust
// Real-time system - no GC pauses
fn process_audio(buffer: &mut [f32]) {
    // Guaranteed to complete in < 1ms
    // No garbage collection interruptions
}
```

**Examples**: Audio processing, robotics, real-time trading

**4. Binary size matters**:

```rust
// CLI tool users download
// Rust: 2 MB
// Haskell: 15 MB
fn main() {
    // Minimal dependencies
}
```

**Examples**: CLI tools, serverless functions, distributed apps

## The Irony: Converging Features

Modern Rust async runtimes **re-implement parts of Haskell's RTS**:

| Feature | Haskell RTS | Rust (Tokio) |
|---------|-------------|--------------|
| **Green threads** | Built-in (`forkIO`) | `async`/`.await` |
| **Scheduler** | Built-in | Tokio runtime |
| **Work stealing** | Built-in | Tokio work-stealing |
| **M:N threading** | Default | Optional |

**Example**:

```haskell
-- Haskell: Built-in
main = forkIO $ putStrLn "Hello"
```

```rust
// Rust: Requires runtime
#[tokio::main]
async fn main() {
    tokio::spawn(async {
        println!("Hello");
    });
}
```

**The difference**: Haskell makes it **built-in** (always present), Rust makes it **opt-in** (only if you `use tokio`).

**Why this matters**:
- **Rust**: You choose your runtime (or none)
- **Haskell**: Runtime chosen for you

## Language Ecosystem

### Haskell Strengths

**1. Academic backing**:
- Cutting-edge type system research
- Formal verification (Liquid Haskell)
- Category theory integration

**2. Mature libraries**:
- Parsec (parser combinators)
- Pandoc (document conversion)
- QuickCheck (property testing)

**3. Niche dominance**:
- Compilers (GHC itself, PureScript, Elm)
- Financial systems (Jane Street uses OCaml, similar ecosystem)
- Blockchain (Cardano)

### Rust Strengths

**1. Industry adoption**:
- Mozilla (Firefox)
- Microsoft (Windows components)
- AWS (Firecracker)
- Google (Android, Fuchsia)

**2. Systems programming**:
- Operating systems (Redox)
- WebAssembly (wasm-bindgen)
- Embedded (embedded-hal)

**3. Growing ecosystem**:
- Web frameworks (Actix, Rocket)
- Async runtimes (Tokio, async-std)
- Graphics (wgpu, bevy)

## The Verdict

**Neither is "winning"** - they serve different purposes:

### Haskell is winning in:
- Academia and research
- Financial systems (correctness-critical)
- Compiler development
- Domain-specific languages (DSLs)

### Rust is winning in:
- Systems programming
- WebAssembly
- Embedded systems
- Cloud infrastructure

### Both excel at:
- Concurrent systems
- Type-safe programming
- Functional programming patterns

## Choosing Between Them

### Decision Matrix

| Requirement | Haskell | Rust |
|-------------|---------|------|
| **Binary size < 5 MB** | ❌ | ✅ |
| **Startup time < 10ms** | ❌ | ✅ |
| **GC pauses acceptable** | ✅ | ❌ |
| **Rapid prototyping** | ✅ | ⚠️ |
| **Academic research** | ✅ | ⚠️ |
| **Production systems** | ✅ | ✅ |
| **Embedded systems** | ❌ | ✅ |
| **Web services** | ✅ | ✅ |

### Hybrid Approach

**Use both**:

```
┌─────────────────────┐     FFI      ┌─────────────────────┐
│   Haskell Core      │◄───────────►│   Rust Hot Path     │
│  (Business Logic)   │              │  (Performance)      │
└─────────────────────┘              └─────────────────────┘
```

**Examples**:
- Haskell for complex business logic
- Rust for performance-critical code
- gRPC for service boundaries

## Further Reading

- **Main README**: [`../../README.md`](../../README.md#rust-vs-haskell-different-design-philosophies)
- **Decision Framework**: [→ Chapter 12](./12-decision-framework.md)
- **Benchmarking**: [→ Chapter 11](../part-4-interactive/11-benchmarking.md)

---

## Summary

Key takeaways:

1. ✅ **Different design goals**: Research vs systems programming
2. ✅ **Runtime trade-offs**: Haskell's RTS is a feature, not a bug
3. ✅ **Converging features**: Rust async ≈ Haskell green threads
4. ✅ **Choose based on requirements**, not popularity
5. ✅ **Hybrid approaches** often work best

**Next**: [Appendices →](../appendices/a-cicd-setup.md)

---

## Quick Navigation

- **Previous**: [← Troubleshooting](./14-troubleshooting.md)
- **Next**: [CI/CD Setup →](../appendices/a-cicd-setup.md)
- **Related**: [Decision Framework →](./12-decision-framework.md)
