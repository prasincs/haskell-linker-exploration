# Appendix D: Glossary

## Technical Terms Explained

Quick reference for terms used throughout this book.

---

## A

**ABI (Application Binary Interface)**
The low-level interface between program modules, defining calling conventions, data layout, and system calls.

**Allocation**
Process of reserving memory for data structures. In Haskell, managed by the garbage collector.

---

## B

**Boot Libraries**
Standard libraries that ship with GHC (base, ghc-prim, integer-gmp, etc.). Required for even simple programs.

**Bracket**
Pattern for exception-safe resource management: acquire, use, release (always).

---

## C

**C--** (C minus minus)
GHC's low-level intermediate representation, similar to C but tailored for functional languages.

**Calling Convention**
Rules for how functions receive parameters and return results (registers, stack, etc.).

**Capability**
Virtual CPU in GHC's runtime system. Each capability runs Haskell threads on one OS thread.

**Closure**
Runtime representation of a function with its environment (captured variables).

**Core**
GHC's primary intermediate representation, based on System FC. Small, explicitly-typed functional language.

**CString**
C-style null-terminated string (`char*` in C, `CString` in Haskell FFI).

---

## D

**Dynamic Linking**
Linking libraries at runtime rather than compile-time. Smaller executables but requires libraries at runtime.

---

## E

**Eventlog**
Binary log of runtime events (GC, thread scheduling, etc.) for analysis with ThreadScope.

---

## F

**FFI (Foreign Function Interface)**
Mechanism for calling C code from Haskell and vice versa.

**FunPtr**
Haskell type representing a C function pointer. Must be freed with `freeHaskellFunPtr`.

---

## G

**GC (Garbage Collector)**
Automatic memory manager that reclaims unused heap objects.

**Generational GC**
Garbage collector that separates young (frequently GC'd) from old objects.

**GHC (Glasgow Haskell Compiler)**
The most widely-used Haskell compiler. More than a compiler - also a build system and linker orchestrator.

**Green Threads**
Lightweight threads scheduled in user-space (not OS threads). Haskell can run millions.

**gRPC**
Modern RPC framework using Protocol Buffers. Alternative to FFI for inter-language communication.

---

## H

**Heap**
Region of memory where dynamically allocated data lives. Managed by GC in Haskell.

**HsFFI.h**
Header file providing C interface to Haskell runtime (`hs_init`, `hs_exit`, etc.).

---

## I

**Info Table**
Metadata structure for every heap object, containing entry code, layout, type information.

**Intermediate Representation (IR)**
Internal form used by compiler during optimization (e.g., Core, STG, C--).

---

## L

**Lazy Evaluation**
Deferring computation until result is needed. Enables infinite data structures.

**lld**
LLVM's linker. Fast alternative to GNU ld. Can be used by GHC via `-fuse-ld=lld`.

**LLVM**
Compiler infrastructure providing optimization and code generation. GHC can use as backend with `-fllvm`.

---

## M

**Marshalling**
Converting data between Haskell and C representations (`Int` ↔ `CInt`).

**Monomorphization**
Creating specialized versions of generic functions for specific types (Rust does this, Haskell doesn't).

---

## N

**NCG (Native Code Generator)**
GHC's default backend. Generates assembly directly without LLVM.

---

## O

**Object File**
Compiled code in `.o` format, not yet linked into executable.

---

## P

**Package Database**
Registry of installed Haskell packages maintained by `ghc-pkg`.

**Profiling**
Measuring program performance (time, memory allocation). Build with `-prof`.

**Ptr**
Haskell type representing a C pointer (`Ptr a` for pointer to `a`).

---

## R

**REPL (Read-Eval-Print Loop)**
Interactive environment for running Haskell code. Start with `ghci` or `cabal repl`.

**RTS (Runtime System)**
Collection of C code (~5 MB) providing GC, scheduler, heap management, FFI support. Essential for all Haskell programs.

**RTS Options**
Command-line flags for configuring runtime (e.g., `+RTS -N4` for 4 cores).

---

## S

**Safe/Unsafe FFI**
Safety levels for foreign calls:
- **safe**: Can call back into Haskell, slower
- **unsafe**: Cannot call back, faster

**Scheduler**
Component of RTS that manages green threads across capabilities.

**Stack**
Region of memory for function call frames and local variables.

**Stable Pointer**
Reference to Haskell value that prevents GC. Used when C code needs to hold Haskell data.

**Static Linking**
Including all libraries in the executable. Larger but self-contained.

**STG (Spineless Tagless G-machine)**
Intermediate representation between Core and C--. Makes lazy evaluation explicit.

**Strict Evaluation**
Evaluating arguments immediately (opposite of lazy). Use `seq` or `!` pattern.

---

## T

**Thunk**
Unevaluated expression stored on heap. Updated with result after evaluation.

**ThreadScope**
Tool for visualizing parallel Haskell execution via eventlogs.

**Topological Sort**
Ordering items based on dependencies. GHC uses this to order libraries for linking.

---

## U

**Unboxed Type**
Value stored directly (not via pointer). E.g., `Int#` vs `Int`. More efficient but no laziness.

---

## W

**WASM (WebAssembly)**
Binary format for running code in browsers. GHC 9.8+ can compile Haskell to WASM.

**Work-Stealing**
Scheduler strategy where idle capabilities steal tasks from busy ones.

**Wrapper**
Haskell function that converts types and calls FFI function. Provides type-safe API.

---

## Z

**Zero-Cost Abstraction**
Rust philosophy: high-level code compiles to same machine code as low-level equivalent. Haskell prioritizes expressiveness over this.

---

## Symbols and Abbreviations

**+RTS ... -RTS**
Syntax for passing runtime options to Haskell programs.

**:t** (in GHCi)
Show type of expression.

**:i** (in GHCi)
Show information about name (type, instances, etc.).

**->** (in types)
Function type constructor. `Int -> String` is function from Int to String.

**=>** (in types)
Type class constraint. `Eq a => a -> a -> Bool` requires `a` to have `Eq` instance.

---

## Common File Extensions

**.hs**
Haskell source file.

**.lhs**
Literate Haskell source (documentation + code).

**.hi**
Haskell interface file (produced during compilation).

**.o**
Object file (compiled code, not yet linked).

**.a**
Static library (archive of object files).

**.so** / **.dylib** / **.dll**
Dynamic/shared library (Linux / macOS / Windows).

**.cabal**
Cabal package description file.

**.yaml**
Stack or hpack configuration file.

---

## See Also

- **[Chapter 7: Runtime System](../part-3-deep-dive/07-runtime-system.md)** - Detailed RTS explanation
- **[Chapter 8: Linking Process](../part-3-deep-dive/08-linking-process.md)** - How GHC links programs
- **[Chapter 9: FFI Guide](../part-3-deep-dive/09-ffi-guide.md)** - Complete FFI reference

---

## Quick Navigation

- **Previous**: [← Further Reading](./c-further-reading.md)
- **Next**: [Methodology →](./e-methodology.md)
- **Main**: [← Back to Book](../README.md)
