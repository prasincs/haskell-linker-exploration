# Summary

[Introduction](./README.md)

---

# Part I: Understanding the Problem

- [The Original Question](./part-1-understanding/01-original-question.md)
- [Two Critical Misconceptions](./part-1-understanding/02-misconceptions.md)

---

# Part II: Proof of Concepts

- [PoC 1: Quantifying the Problem](./part-2-proofs/03-poc1-linker-comparison.md)
  - [Running the Example](./part-2-proofs/03-poc1-linker-comparison.md#running-the-poc)
  - [What Goes Wrong](./part-2-proofs/03-poc1-linker-comparison.md#expected-output)
  - [Key Insights](./part-2-proofs/03-poc1-linker-comparison.md#key-insights)

- [PoC 2: FFI Integration](./part-2-proofs/04-poc2-ffi-integration.md)
  - [The Example Code](./part-2-proofs/04-poc2-ffi-integration.md#the-code)
  - [Manual Life Support](./part-2-proofs/04-poc2-ffi-integration.md#expected-output)
  - [Why GHC Must Link](./part-2-proofs/04-poc2-ffi-integration.md#the--no-hs-main-flag-explained)

- [PoC 3: gRPC Alternative](./part-2-proofs/05-poc3-grpc-alternative.md)
  - [The Modern Approach](./part-2-proofs/05-poc3-grpc-alternative.md#the-grpc-solution)
  - [Trade-offs](./part-2-proofs/05-poc3-grpc-alternative.md#architecture-comparison)
  - [When to Use Each](./part-2-proofs/05-poc3-grpc-alternative.md#when-to-use-each-approach)

---

# Part III: Deep Dive

- [GHC Architecture](./part-3-deep-dive/06-ghc-architecture.md)
  - [The 30-Year Evolution](./part-3-deep-dive/06-ghc-architecture.md#ghc-a-30-year-architectural-marvel)
  - [The Pipeline](./part-3-deep-dive/06-ghc-architecture.md#the-pipeline)
  - [Why GHC Is a Driver](./part-3-deep-dive/06-ghc-architecture.md#why-ghc-is-a-driver)

- [The Runtime System](./part-3-deep-dive/07-runtime-system.md)
  - [Garbage Collector](./part-3-deep-dive/07-runtime-system.md#the-garbage-collector)
  - [Green Thread Scheduler](./part-3-deep-dive/07-runtime-system.md#the-scheduler)
  - [Heap Management](./part-3-deep-dive/07-runtime-system.md#lazy-evaluation-heap)
  - [Exception Handling](./part-3-deep-dive/07-runtime-system.md#exception-handling)

- [The Linking Process](./part-3-deep-dive/08-linking-process.md)
  - [Boot Packages](./part-3-deep-dive/08-linking-process.md#boot-libraries)
  - [Why GHC Must Orchestrate](./part-3-deep-dive/08-linking-process.md#why-ghc-orchestrates)
  - [Calling Conventions](./part-3-deep-dive/08-linking-process.md#calling-conventions)

- [Foreign Function Interface](./part-3-deep-dive/09-ffi-guide.md)
  - [Marshaling Data](./part-3-deep-dive/09-ffi-guide.md#marshaling)
  - [Memory Management](./part-3-deep-dive/09-ffi-guide.md#memory-management)
  - [Performance Considerations](./part-3-deep-dive/09-ffi-guide.md#performance)
  - [Common Pitfalls](./part-3-deep-dive/09-ffi-guide.md#common-pitfalls)

---

# Part IV: Interactive Explorations

- [WebAssembly Demo](./part-4-interactive/10-wasm-demo.md)
  - [Running Haskell in Your Browser](./part-4-interactive/10-wasm-demo.md#features)
  - [Interactive Visualizations](./part-4-interactive/10-wasm-demo.md#running-the-demo)
  - [Live WASM Demo](./part-4-interactive/10-wasm-demo.md#try-it)

- [Benchmarking](./part-4-interactive/11-benchmarking.md)
  - [FFI vs gRPC Performance](./part-4-interactive/11-benchmarking.md#performance-comparison)
  - [Measuring Overhead](./part-4-interactive/11-benchmarking.md#latency)
  - [Real-World Numbers](./part-4-interactive/11-benchmarking.md#real-world-numbers)

---

# Part V: Production Considerations

- [Decision Framework](./part-5-production/12-decision-framework.md)
  - [Decision Matrix](./part-5-production/12-decision-framework.md#decision-matrix)
  - [When FFI Makes Sense](./part-5-production/12-decision-framework.md#when-ffi-still-makes-sense)
  - [When gRPC Makes Sense](./part-5-production/12-decision-framework.md#when-grpc-makes-more-sense)

- [Best Practices](./part-5-production/13-best-practices.md)
  - [FFI Patterns](./part-5-production/13-best-practices.md#ffi-patterns)
  - [Build System Integration](./part-5-production/13-best-practices.md#build-systems)
  - [Testing Strategies](./part-5-production/13-best-practices.md#testing)

- [Troubleshooting](./part-5-production/14-troubleshooting.md)
  - [Finding Missing Symbols](./part-5-production/14-troubleshooting.md#missing-symbols)
  - [RTS Initialization Issues](./part-5-production/14-troubleshooting.md#rts-issues)
  - [Memory Leaks](./part-5-production/14-troubleshooting.md#memory-leaks)
  - [Profiling Tools](./part-5-production/14-troubleshooting.md#profiling)

---

# Appendices

- [CI/CD Setup](./appendices/a-cicd-setup.md)
- [Build System Reference](./appendices/b-build-systems.md)
- [Further Reading](./appendices/c-further-reading.md)
- [Glossary](./appendices/d-glossary.md)

---

# Additional Resources

- [Rust vs Haskell: Design Philosophies](./part-5-production/15-rust-vs-haskell.md)
- [Methodology](./appendices/e-methodology.md)
- [Contributing](./appendices/f-contributing.md)
