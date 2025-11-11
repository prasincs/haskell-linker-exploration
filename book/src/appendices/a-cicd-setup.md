# Appendix A: CI/CD Setup

## Continuous Integration and Deployment

This appendix describes the **CI/CD setup** for ensuring all examples remain reproducible.

## GitHub Actions Workflow

### What's Tested

The repository includes comprehensive CI/CD:

1. **Build Verification**:
   - All PoCs build successfully
   - Docker images build correctly
   - Documentation compiles (mdBook)

2. **Test Execution**:
   - PoC 1: Linker comparison runs
   - PoC 2: FFI integration works
   - PoC 3: gRPC services communicate

3. **Reproducibility**:
   - Multiple runs verify consistency
   - Different environments tested
   - Weekly scheduled runs catch bitrot

### Workflow Configuration

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    # Weekly builds (every Sunday at 00:00 UTC)
    - cron: '0 0 * * 0'

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Set up GHC
      uses: haskell/actions/setup@v2
      with:
        ghc-version: '9.4.8'

    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y llvm-18 lld

    - name: Run PoC 1
      run: cd poc1-linker-comparison && ./build.sh

    - name: Run PoC 2
      run: cd poc2-ffi-integration && ./build.sh

    - name: Run PoC 3
      run: cd poc3-grpc-microservices && ./build.sh

    - name: Build Docker image
      run: docker build -t ghc-linker-poc .

    - name: Run all demos in Docker
      run: docker run --rm ghc-linker-poc ./scripts/run-all-demos.sh

  documentation:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup mdBook
      run: |
        curl -L https://github.com/rust-lang/mdBook/releases/download/v0.4.36/mdbook-v0.4.36-x86_64-unknown-linux-gnu.tar.gz | tar xz
        sudo mv mdbook /usr/local/bin/

    - name: Build documentation
      run: cd book && mdbook build

    - name: Deploy to GitHub Pages
      if: github.ref == 'refs/heads/main'
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./book/book
```

## Testing Locally

### Prerequisites

```bash
# Install act (run GitHub Actions locally)
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### Run Locally

```bash
# Run the entire CI workflow
act

# Run specific job
act -j build-and-test

# Run with custom workflow file
act -W .github/workflows/ci.yml
```

## Docker-Based CI

### Multi-Stage Build

The Docker image uses multi-stage builds for efficiency:

```dockerfile
# Stage 1: Build environment
FROM haskell:9.4.8 AS builder

RUN apt-get update && apt-get install -y \
    llvm-18 \
    lld \
    clang-18

WORKDIR /workspace
COPY . .

# Build all PoCs
RUN cd poc1-linker-comparison && ./build.sh && \
    cd ../poc2-ffi-integration && ./build.sh && \
    cd ../poc3-grpc-microservices && ./build.sh

# Stage 2: Runtime environment
FROM debian:bookworm-slim

COPY --from=builder /workspace /workspace

WORKDIR /workspace

CMD ["./scripts/run-all-demos.sh"]
```

### Building and Testing

```bash
# Build image
docker build -t ghc-linker-poc .

# Run all tests
docker run --rm ghc-linker-poc

# Interactive shell
docker run --rm -it ghc-linker-poc /bin/bash
```

## Caching Strategies

### Cabal Cache

```yaml
- name: Cache Cabal packages
  uses: actions/cache@v3
  with:
    path: |
      ~/.cabal/packages
      ~/.cabal/store
      dist-newstyle
    key: ${{ runner.os }}-cabal-${{ hashFiles('**/*.cabal') }}
```

### Docker Layer Cache

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v2

- name: Build with cache
  uses: docker/build-push-action@v4
  with:
    context: .
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Artifact Management

### Store Build Artifacts

```yaml
- name: Upload artifacts
  uses: actions/upload-artifact@v3
  with:
    name: binaries
    path: |
      poc1-linker-comparison/hello_success
      poc2-ffi-integration/program
      poc3-grpc-microservices/client
      poc3-grpc-microservices/server
```

### Download in Subsequent Jobs

```yaml
- name: Download artifacts
  uses: actions/download-artifact@v3
  with:
    name: binaries
```

## Performance Benchmarking

### Benchmark Job

```yaml
benchmark:
  runs-on: ubuntu-latest

  steps:
  - uses: actions/checkout@v3

  - name: Run benchmarks
    run: |
      cd poc3-grpc-microservices
      ./benchmark.sh > results.txt

  - name: Upload results
    uses: actions/upload-artifact@v3
    with:
      name: benchmark-results
      path: poc3-grpc-microservices/results.txt

  - name: Comment on PR
    uses: actions/github-script@v6
    with:
      script: |
        const fs = require('fs');
        const results = fs.readFileSync('poc3-grpc-microservices/results.txt', 'utf8');
        github.rest.issues.createComment({
          issue_number: context.issue.number,
          owner: context.repo.owner,
          repo: context.repo.repo,
          body: `## Benchmark Results\n\n\`\`\`\n${results}\n\`\`\``
        })
```

## Scheduled Maintenance

### Weekly Builds

```yaml
schedule:
  # Every Sunday at 00:00 UTC
  - cron: '0 0 * * 0'
```

**Purpose**:
- Catch dependency rot
- Verify examples still work
- Test against latest dependencies

### Dependency Updates

```yaml
update-dependencies:
  runs-on: ubuntu-latest

  steps:
  - uses: actions/checkout@v3

  - name: Update Cabal packages
    run: cabal update

  - name: Freeze dependencies
    run: cabal freeze

  - name: Create PR
    uses: peter-evans/create-pull-request@v5
    with:
      commit-message: 'chore: update dependencies'
      title: 'Update dependencies'
      branch: update-deps
```

## Status Badges

### Add to README

```markdown
[![CI](https://github.com/yourusername/haskell-linker-exploration/workflows/CI/badge.svg)](https://github.com/yourusername/haskell-linker-exploration/actions)

[![Documentation](https://github.com/yourusername/haskell-linker-exploration/workflows/Documentation/badge.svg)](https://yourusername.github.io/haskell-linker-exploration/)
```

## Troubleshooting CI

### Common Issues

**1. GHC version mismatch**:

```yaml
# Pin GHC version
- name: Set up GHC
  uses: haskell/actions/setup@v2
  with:
    ghc-version: '9.4.8'  # Exact version
```

**2. Timeout on builds**:

```yaml
# Increase timeout
jobs:
  build-and-test:
    timeout-minutes: 60  # Default is 360
```

**3. Disk space issues**:

```yaml
- name: Free disk space
  run: |
    sudo rm -rf /usr/local/lib/android
    sudo rm -rf /opt/ghc
    df -h
```

## Best Practices

1. ✅ **Pin versions**: GHC, dependencies, tools
2. ✅ **Cache aggressively**: Cabal, Docker layers
3. ✅ **Test multiple environments**: Ubuntu, macOS, Docker
4. ✅ **Run scheduled builds**: Catch bitrot early
5. ✅ **Store artifacts**: Debug failures easily

---

## Quick Navigation

- **Previous**: [← Rust vs Haskell](../part-5-production/15-rust-vs-haskell.md)
- **Next**: [Build Systems →](./b-build-systems.md)
- **Main**: [← Back to Book](../README.md)
