# Appendix C: Further Reading

## Resources for Deeper Learning

This appendix provides **curated resources** for learning more about GHC, the RTS, FFI, and related topics.

## Official Documentation

### GHC Documentation

- **[GHC User's Guide](https://downloads.haskell.org/ghc/latest/docs/users_guide/)** - Complete reference for GHC
  - [FFI Chapter](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/ffi.html)
  - [RTS Options](https://downloads.haskell.org/ghc/latest/docs/users_guide/runtime_control.html)
  - [Profiling](https://downloads.haskell.org/ghc/latest/docs/users_guide/profiling.html)

- **[GHC Commentary](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary)** - Internal documentation
  - [RTS Commentary](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/rts)
  - [Compiler Pipeline](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler)

### Haskell Language

- **[Haskell 2010 Report](https://www.haskell.org/onlinereport/haskell2010/)** - Language specification
  - [Chapter 8: FFI](https://www.haskell.org/onlinereport/haskell2010/haskellch8.html)

- **[Haskell Wiki](https://wiki.haskell.org/)**
  - [FFI Introduction](https://wiki.haskell.org/Foreign_Function_Interface)
  - [FFI Cookbook](https://wiki.haskell.org/FFI_cook_book)

## Academic Papers

### GHC and RTS

**Must-read papers**:

1. **[Spineless Tagless G-machine](https://www.microsoft.com/en-us/research/wp-content/uploads/1992/04/spineless-tagless-gmachine.pdf)** (1992)
   - Simon Peyton Jones
   - The core execution model for Haskell

2. **[Runtime Support for Multicore Haskell](https://www.microsoft.com/en-us/research/publication/runtime-support-for-multicore-haskell/)** (2009)
   - Simon Marlow, Simon Peyton Jones, Satnam Singh
   - How GHC's parallel RTS works

3. **[Parallel Generational-Copying Garbage Collection](https://www.microsoft.com/en-us/research/publication/parallel-generational-copying-garbage-collection-with-a-block-structured-heap/)** (2008)
   - Simon Marlow, Simon Peyton Jones
   - GHC's garbage collector design

4. **[System F with Type Equality Coercions](https://www.microsoft.com/en-us/research/publication/system-f-with-type-equality-coercions/)** (2007)
   - The theoretical basis for GHC Core

### Haskell History

5. **[A History of Haskell: Being Lazy With Class](https://www.microsoft.com/en-us/research/publication/a-history-of-haskell-being-lazy-with-class/)** (2007)
   - Paul Hudak et al.
   - Complete history of Haskell's design

## Books

### Haskell Programming

1. **[Real World Haskell](http://book.realworldhaskell.org/)**
   - Chapter 17: Interfacing with C (The FFI)
   - Free online

2. **[Parallel and Concurrent Programming in Haskell](https://www.oreilly.com/library/view/parallel-and-concurrent/9781449335939/)**
   - Simon Marlow
   - Deep dive into Haskell's concurrency

3. **[Thinking Functionally with Haskell](https://www.cambridge.org/core/books/thinking-functionally-with-haskell/FBD926FBCE1DB8FD02C0AFDA0606E34A)**
   - Richard Bird
   - Functional programming fundamentals

### GHC Internals

4. **[The Architecture of Open Source Applications: GHC](https://aosabook.org/en/v2/ghc.html)**
   - Simon Marlow, Simon Peyton Jones
   - High-level overview of GHC architecture
   - Free online, excellent starting point

5. **[Implementing Functional Languages: A Tutorial](https://www.microsoft.com/en-us/research/publication/implementing-functional-languages-a-tutorial/)**
   - Simon Peyton Jones, David Lester
   - How to build a compiler

## Online Courses

### Free Courses

- **[CIS 194: Introduction to Haskell](https://www.cis.upenn.edu/~cis1940/spring13/)** - UPenn
- **[CS240h: Functional Systems in Haskell](http://www.scs.stanford.edu/16wi-cs240h/)** - Stanford
- **[FP Course](https://github.com/system-f/fp-course)** - NICTA/Data61

### Video Lectures

- **[Simon Peyton Jones Lectures](https://www.youtube.com/results?search_query=simon+peyton+jones+haskell)**
  - Many talks on GHC internals
  - "Escape from the Ivory Tower" series

- **[Haskell Exchange](https://skillsmatter.com/conferences/11741-haskell-exchange-2019)**
  - Annual conference with expert talks

## Tools and Libraries

### Development Tools

- **[GHCup](https://www.haskell.org/ghcup/)** - GHC version manager
- **[Cabal](https://www.haskell.org/cabal/)** - Build system
- **[Stack](https://docs.haskellstack.org/)** - Alternative build system
- **[HLS](https://github.com/haskell/haskell-language-server)** - Language server

### Profiling and Debugging

- **[ThreadScope](https://wiki.haskell.org/ThreadScope)** - Parallel execution visualizer
- **[eventlog2html](https://mpickering.github.io/eventlog2html/)** - Modern eventlog viewer
- **[ghc-heap-view](https://hackage.haskell.org/package/ghc-heap-view)** - Inspect heap objects

### FFI Libraries

- **[inline-c](https://hackage.haskell.org/package/inline-c)** - Inline C code in Haskell
- **[c2hs](https://hackage.haskell.org/package/c2hs)** - C to Haskell binding generator
- **[hsc2hs](https://hackage.haskell.org/package/hsc2hs)** - Preprocessor for C bindings

## Community Resources

### Forums and Discussion

- **[Haskell Discourse](https://discourse.haskell.org/)** - Official discussion forum
- **[r/haskell](https://www.reddit.com/r/haskell/)** - Reddit community
- **[Haskell Cafe](https://mail.haskell.org/mailman/listinfo/haskell-cafe)** - Mailing list
- **[Stack Overflow](https://stackoverflow.com/questions/tagged/haskell)** - Q&A

### Blogs

- **[Well-Typed](https://well-typed.com/blog/)** - Consulting company blog
- **[FP Complete](https://www.fpcomplete.com/blog/)** - Commercial Haskell
- **[Tweag](https://www.tweag.io/blog/)** - Research and consulting

### Podcasts

- **[Haskell Weekly Podcast](https://haskellweekly.news/podcast.html)**
- **[The Haskell Interlude](https://haskell.foundation/podcast/)**

## Related Projects

### Compilers Using GHC

- **[PureScript](https://www.purescript.org/)** - Haskell for JavaScript
- **[Elm](https://elm-lang.org/)** - Functional language for web
- **[Agda](https://wiki.portal.chalmers.se/agda/)** - Dependently-typed language

### Alternative Haskell Implementations

- **[Hugs](https://www.haskell.org/hugs/)** - Interpreter (historical)
- **[Frege](https://github.com/Frege/frege)** - Haskell for JVM
- **[Eta](https://eta-lang.org/)** - Haskell on JVM

### LLVM and Linking

- **[LLVM Documentation](https://llvm.org/docs/)** - LLVM project
- **[lld](https://lld.llvm.org/)** - LLVM linker
- **[Linkers and Loaders](https://www.iecc.com/linker/)** - Book by John Levine

## Tutorials and Guides

### FFI Tutorials

- **[24 Days of GHC Extensions: FFI](https://ocharles.org.uk/posts/2014-12-01-24-days-of-ghc-extensions.html)**
- **[School of Haskell: FFI](https://www.schoolofhaskell.com/user/commercial/content/ffi-intro)**

### Performance Guides

- **[Haskell Performance](https://wiki.haskell.org/Performance)** - Wiki guide
- **[GHC Optimization](https://wiki.haskell.org/Performance/GHC)** - Compiler optimization
- **[Parallel Haskell Tutorial](https://wiki.haskell.org/Parallel/Tutorial)**

### Build System Guides

- **[Cabal User Guide](https://cabal.readthedocs.io/)** - Complete Cabal docs
- **[Stack User Guide](https://docs.haskellstack.org/)** - Stack documentation
- **[Nix for Haskell](https://nixos.org/guides/nix-pills/)** - Reproducible builds

## Case Studies

### Production Haskell

- **[Mercury](https://mercury.com/blog)** - FinTech using Haskell
- **[Standard Chartered](https://www.standardchartered.com/)** - Banking
- **[Juspay](https://juspay.in/)** - Payments platform
- **[Hasura](https://hasura.io/)** - GraphQL engine

### Open Source Projects

- **[Pandoc](https://pandoc.org/)** - Document converter
- **[ShellCheck](https://www.shellcheck.net/)** - Shell script analyzer
- **[Dhall](https://dhall-lang.org/)** - Configuration language
- **[Cardano](https://cardano.org/)** - Blockchain platform

## Research Papers Archive

- **[Microsoft Research: Haskell Papers](https://www.microsoft.com/en-us/research/search/?q=haskell)**
- **[ICFP](https://www.icfpconference.org/)** - International Conference on Functional Programming
- **[Haskell Symposium](https://www.haskell.org/haskell-symposium/)**

## Stay Updated

### News Sources

- **[Haskell Weekly](https://haskellweekly.news/)** - Weekly newsletter
- **[Planet Haskell](https://planet.haskell.org/)** - Blog aggregator
- **[This Week in Haskell](https://www.reddit.com/r/haskell/search?q=author%3Ahwn_bot)**

### Conferences

- **[ICFP](https://icfp20.sigplan.org/)** - Functional Programming
- **[Haskell Symposium](https://www.haskell.org/haskell-symposium/)**
- **[Haskell eXchange](https://skillsmatter.com/conferences/)**
- **[ZuriHac](https://zurihac.info/)** - Largest Haskell Hackathon

## Repository Documentation

### This Project

All comprehensive documentation is in [`../../docs/`](../../docs/):

- **[GHC Architecture](../../docs/ghc-architecture.md)** - Compiler pipeline
- **[RTS Explained](../../docs/rts-explained.md)** - Runtime system
- **[Linking Process](../../docs/linking-process.md)** - How linking works
- **[FFI Guide](../../docs/ffi-guide.md)** - Complete FFI reference

---

## Quick Navigation

- **Previous**: [← Build Systems](./b-build-systems.md)
- **Next**: [Glossary →](./d-glossary.md)
- **Main**: [← Back to Book](../README.md)
