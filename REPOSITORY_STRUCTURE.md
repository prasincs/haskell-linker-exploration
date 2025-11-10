# Repository Structure

This document provides an overview of the repository organization and explains where to find specific content.

## Directory Layout

```
haskell-linker-exploration/
├── README.md                          # Main blog post (start here!)
├── CONTRIBUTING.md                    # How to contribute
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore patterns
├── Dockerfile                         # Docker image for all PoCs
├── docker-compose.yml                 # Orchestration for services
│
├── docs/                              # Deep-dive documentation
│   ├── ghc-architecture.md           # GHC's compilation pipeline
│   ├── rts-explained.md              # Runtime System deep dive
│   ├── linking-process.md            # [TODO] Detailed linking explanation
│   ├── ffi-guide.md                  # [TODO] Comprehensive FFI guide
│   └── modern-alternatives.md        # [TODO] Microservices comparison
│
├── diagrams/                          # Visual explanations
│   ├── ghc-pipeline.md               # Mermaid diagrams of compilation
│   ├── linking-comparison.md         # [TODO] Visual linking comparison
│   └── rts-architecture.md           # [TODO] RTS component diagram
│
├── poc1-linker-comparison/           # PoC 1: Naive lld vs GHC
│   ├── README.md                     # Explanation and instructions
│   ├── build.sh                      # Main demonstration script
│   └── analysis/
│       └── compare_commands.sh       # Parse and analyze linker commands
│
├── poc2-ffi-integration/             # PoC 2: Calling Haskell from C
│   ├── README.md                     # Explanation and instructions
│   ├── MyLib.hs                      # Haskell Fibonacci library (FFI)
│   ├── main.c                        # C program calling Haskell
│   └── build.sh                      # Demonstration script
│
├── poc3-grpc-microservices/          # PoC 3: Modern alternative
│   ├── README.md                     # Comparison and architecture
│   ├── proto/                        # [TODO] Protocol Buffer definitions
│   ├── haskell-service/              # [TODO] Haskell gRPC server
│   └── cpp-client/                   # [TODO] C++ gRPC client
│
├── scripts/                           # Utility scripts
│   ├── run-all-demos.sh              # Run all PoCs sequentially
│   └── analyze-dependencies.sh       # [TODO] Visualize dependency graph
│
├── output/                            # Generated artifacts (gitignored)
│   └── (logs, binaries, etc.)
│
└── [Legacy files]
    ├── Hello.hs                       # Original test file
    ├── Dockerfile.poc                 # Old Dockerfile
    └── Gemini-Output.md               # Original blog draft
```

## File Purpose Guide

### Start Here

| File | Purpose | Read Time |
|------|---------|-----------|
| **[README.md](./README.md)** | Main blog post explaining everything | 15 min |
| **[poc1-linker-comparison/README.md](./poc1-linker-comparison/README.md)** | PoC 1 explanation | 5 min |
| **[poc2-ffi-integration/README.md](./poc2-ffi-integration/README.md)** | PoC 2 explanation | 10 min |

### Technical Deep Dives

| File | Purpose | Read Time |
|------|---------|-----------|
| **[docs/ghc-architecture.md](./docs/ghc-architecture.md)** | GHC internals, pipeline, IRs | 25 min |
| **[docs/rts-explained.md](./docs/rts-explained.md)** | Runtime System components | 30 min |
| **[poc3-grpc-microservices/README.md](./poc3-grpc-microservices/README.md)** | Modern alternatives | 15 min |

### Visual Learners

| File | Content |
|------|---------|
| **[diagrams/ghc-pipeline.md](./diagrams/ghc-pipeline.md)** | Mermaid flowcharts of GHC's pipeline |

### Running Examples

| File | Command |
|------|---------|
| **[Dockerfile](./Dockerfile)** | `docker build -t ghc-linker-poc .` |
| **[docker-compose.yml](./docker-compose.yml)** | `docker-compose --profile demo run all-demos` |
| **[scripts/run-all-demos.sh](./scripts/run-all-demos.sh)** | `./scripts/run-all-demos.sh` |

## Key Concepts by File

### "Why can't lld link Haskell?"

**Start:** [README.md](./README.md) → [poc1-linker-comparison/README.md](./poc1-linker-comparison/README.md)

**Deep dive:** [docs/linking-process.md](./docs/linking-process.md) (TODO)

**Visual:** [diagrams/linking-comparison.md](./diagrams/linking-comparison.md) (TODO)

### "What does GHC actually do?"

**Start:** [README.md](./README.md) → Section "GHC: A 30-Year Architectural Marvel"

**Deep dive:** [docs/ghc-architecture.md](./docs/ghc-architecture.md)

**Visual:** [diagrams/ghc-pipeline.md](./diagrams/ghc-pipeline.md)

### "What is the Runtime System?"

**Start:** [README.md](./README.md) → Section "The Two Requirements"

**Deep dive:** [docs/rts-explained.md](./docs/rts-explained.md)

**Visual:** [diagrams/rts-architecture.md](./diagrams/rts-architecture.md) (TODO)

### "How do I call Haskell from C?"

**Start:** [poc2-ffi-integration/README.md](./poc2-ffi-integration/README.md)

**Deep dive:** [docs/ffi-guide.md](./docs/ffi-guide.md) (TODO)

**Example:** [poc2-ffi-integration/MyLib.hs](./poc2-ffi-integration/MyLib.hs) + [main.c](./poc2-ffi-integration/main.c)

### "What are the modern alternatives?"

**Start:** [poc3-grpc-microservices/README.md](./poc3-grpc-microservices/README.md)

**Deep dive:** [docs/modern-alternatives.md](./docs/modern-alternatives.md) (TODO)

## TODO Items

### High Priority

- [ ] Complete PoC 3 implementation (gRPC server + client)
- [ ] Write docs/linking-process.md
- [ ] Write docs/ffi-guide.md
- [ ] Create diagrams/rts-architecture.md

### Medium Priority

- [ ] Write docs/modern-alternatives.md
- [ ] Create diagrams/linking-comparison.md
- [ ] Add scripts/analyze-dependencies.sh
- [ ] Add CI/CD workflows

### Low Priority

- [ ] PoC 4: Dynamic linking comparison
- [ ] PoC 5: Cross-compilation example
- [ ] Video tutorials
- [ ] Benchmarking framework

## File Naming Conventions

### Documentation

- `README.md` - Overview and instructions for a directory
- `docs/*.md` - Technical deep dives
- `diagrams/*.md` - Mermaid diagram collections

### Code

- `*.hs` - Haskell source files
- `*.c` - C source files
- `*.cpp` - C++ source files
- `*.proto` - Protocol Buffer definitions

### Scripts

- `build.sh` - Build and demonstration scripts
- `*.sh` - Utility scripts
- All scripts should be executable (`chmod +x`)

### Docker

- `Dockerfile` - Main Docker image
- `docker-compose.yml` - Service orchestration
- `Dockerfile.*` - Variant images (if needed)

## Finding Specific Information

### "I want to understand the theory"

Read in order:
1. [README.md](./README.md) - High-level overview
2. [docs/ghc-architecture.md](./docs/ghc-architecture.md) - GHC internals
3. [docs/rts-explained.md](./docs/rts-explained.md) - Runtime details

### "I want to see it in action"

Run in order:
1. `docker build -t ghc-linker-poc .`
2. `docker-compose --profile demo run all-demos`
3. Explore individual PoCs

### "I want to understand a specific error"

1. Check [poc1-linker-comparison/README.md](./poc1-linker-comparison/README.md) → "Understanding the Symbols"
2. Check [docs/rts-explained.md](./docs/rts-explained.md) → Find the component
3. Run the PoC and examine the error output

### "I want to implement FFI in my project"

1. Read [poc2-ffi-integration/README.md](./poc2-ffi-integration/README.md)
2. Study [poc2-ffi-integration/MyLib.hs](./poc2-ffi-integration/MyLib.hs) + [main.c](./poc2-ffi-integration/main.c)
3. Consult [docs/ffi-guide.md](./docs/ffi-guide.md) (TODO)

### "I want to avoid FFI complexity"

1. Read [poc3-grpc-microservices/README.md](./poc3-grpc-microservices/README.md)
2. Compare trade-offs in the "Decision Matrix"
3. Consider modern microservices architecture

## Contribution Guide

See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- How to report issues
- How to submit PRs
- Code style guidelines
- Areas that need work

## Maintenance

### Updating GHC Version

1. Update `FROM haskell:X.Y.Z` in [Dockerfile](./Dockerfile)
2. Test all PoCs: `docker-compose --profile demo run all-demos`
3. Update version references in documentation
4. Update linker command examples (argument counts may change)

### Adding New PoCs

1. Create `pocN-concept-name/` directory
2. Add `README.md` with explanation
3. Add code examples and `build.sh`
4. Update main [README.md](./README.md)
5. Update [docker-compose.yml](./docker-compose.yml)
6. Test with Docker

## Questions?

- Open an issue: [GitHub Issues](https://github.com/yourusername/haskell-linker-exploration/issues)
- Start a discussion: [GitHub Discussions](https://github.com/yourusername/haskell-linker-exploration/discussions)
- Read contributing guide: [CONTRIBUTING.md](./CONTRIBUTING.md)

---

**Last Updated:** 2025-01-10

**Status:** Core structure complete, PoC 1 & 2 working, PoC 3 design complete
