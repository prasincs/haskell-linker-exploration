# Appendix B: Build System Reference

## Working with Cabal and Stack

This appendix provides **quick references** for Cabal and Stack build systems when working with FFI.

## Cabal

### Basic FFI Project

```cabal
cabal-version:       2.4
name:                my-ffi-project
version:             0.1.0.0
license:             MIT
author:              Your Name
maintainer:          your.email@example.com

library
  exposed-modules:   MyFFI
  other-modules:     MyFFI.Internal

  build-depends:     base >= 4.7 && < 5

  -- C sources to compile
  c-sources:         cbits/mylib.c
                     cbits/helper.c

  -- Header files (for reference, not compiled)
  include-dirs:      cbits
  includes:          mylib.h

  -- Extra libraries to link against
  extra-libraries:   m
                     pthread
                     custom

  -- Library search paths
  extra-lib-dirs:    /usr/local/lib

  -- C compiler options
  cc-options:        -Wall -O2 -fPIC

  -- Linker options
  ld-options:        -Wl,-rpath,/usr/local/lib

  default-language:  Haskell2010
  ghc-options:       -Wall -Wcompat

executable my-program
  main-is:           Main.hs
  build-depends:     base
                   , my-ffi-project

  default-language:  Haskell2010
  ghc-options:       -Wall -threaded -rtsopts

test-suite tests
  type:              exitcode-stdio-1.0
  main-is:           Spec.hs
  build-depends:     base
                   , my-ffi-project
                   , hspec

  default-language:  Haskell2010
  ghc-options:       -Wall -threaded
```

### Conditional Compilation

```cabal
library
  if os(linux)
    extra-libraries: dl pthread
    c-sources: cbits/linux_specific.c

  if os(darwin)
    extra-libraries: iconv
    frameworks: CoreFoundation
    c-sources: cbits/macos_specific.c

  if os(windows)
    extra-libraries: kernel32 ws2_32
    c-sources: cbits/windows_specific.c
```

### Using pkg-config

```cabal
library
  pkgconfig-depends: openssl >= 1.1
  -- Automatically adds:
  --   include-dirs
  --   extra-lib-dirs
  --   extra-libraries
```

### Build Commands

```bash
# Configure
cabal configure

# Build
cabal build

# Build with profiling
cabal build --enable-profiling

# Install locally
cabal install

# Clean
cabal clean

# REPL with library loaded
cabal repl
```

## Stack

### stack.yaml Configuration

```yaml
resolver: lts-20.26  # GHC 9.2.8

packages:
  - .

extra-deps: []

# System library locations
extra-lib-dirs:
  - /usr/local/lib
  - /opt/homebrew/lib  # macOS Homebrew

extra-include-dirs:
  - /usr/local/include
  - /opt/homebrew/include

# GHC options for all packages
ghc-options:
  "$everything": -Wall -Wcompat

# Flags for specific packages
flags:
  my-ffi-project:
    use-system-lib: true
```

### package.yaml (hpack)

Instead of `.cabal`, you can use `package.yaml`:

```yaml
name:        my-ffi-project
version:     0.1.0.0
github:      username/my-ffi-project
license:     MIT
author:      Your Name
maintainer:  your.email@example.com

dependencies:
  - base >= 4.7 && < 5

library:
  source-dirs: src
  exposed-modules:
    - MyFFI
  c-sources:
    - cbits/mylib.c
  include-dirs:
    - cbits
  extra-libraries:
    - m
    - pthread
  cc-options: -Wall -O2
  ghc-options:
    - -Wall

executables:
  my-program:
    main: Main.hs
    source-dirs: app
    dependencies:
      - my-ffi-project
    ghc-options:
      - -threaded
      - -rtsopts

tests:
  spec:
    main: Spec.hs
    source-dirs: test
    dependencies:
      - my-ffi-project
      - hspec
```

### Build Commands

```bash
# Build
stack build

# Build with profiling
stack build --profile

# Run executable
stack exec my-program

# Run with RTS options
stack exec my-program -- +RTS -N4 -s

# REPL
stack repl

# Test
stack test

# Clean
stack clean

# Purge everything (including dependencies)
stack clean --full
```

## Common Patterns

### Finding System Libraries

**Problem**: Library installed but Cabal/Stack can't find it.

**Solution 1**: Use pkg-config

```bash
# Check if pkg-config knows about it
pkg-config --libs --cflags openssl

# Add to .cabal
pkgconfig-depends: openssl
```

**Solution 2**: Explicit paths

```bash
# Find library
find /usr -name "libssl.so" 2>/dev/null

# Add to cabal.project.local
extra-lib-dirs: /usr/lib/x86_64-linux-gnu
extra-include-dirs: /usr/include/openssl
```

**Solution 3**: Environment variables

```bash
export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH
export C_INCLUDE_PATH=/usr/local/include:$C_INCLUDE_PATH

cabal build
```

### Cross-Platform Builds

```cabal
-- .cabal file
if os(linux)
  c-sources: cbits/linux.c
  extra-libraries: dl

if os(darwin)
  c-sources: cbits/macos.c
  frameworks: CoreFoundation

if os(windows)
  c-sources: cbits/windows.c
  extra-libraries: kernel32
  cpp-options: -DWINDOWS
```

### Development vs Production

**cabal.project.local** (not in version control):

```cabal
-- Development settings
ghc-options: -j +RTS -A128m -RTS
optimization: 0

-- Or for production:
-- ghc-options: -O2
-- optimization: 2
```

### Using Different Linkers

```bash
# Use lld (faster linking)
cabal build --ghc-option=-fuse-ld=lld

# Or in cabal.project
ghc-options: -fuse-ld=lld
```

## Debugging Build Issues

### Verbose Output

```bash
# Cabal
cabal build -v3

# Stack
stack build --verbose
```

### See Full Commands

```bash
# Cabal
cabal build --ghc-options="-v"

# Stack
stack build --ghc-options="-v"
```

### Inspect Package Database

```bash
# See all registered packages
ghc-pkg list

# Check specific package
ghc-pkg describe base

# Find package files
ghc-pkg field base library-dirs
```

### Common Errors

**Error**: `could not find module 'Foreign.C.Types'`

**Solution**: Add dependency:

```cabal
build-depends: base >= 4.7 && < 5
```

**Error**: `cannot find -lmylib`

**Solution**: Add library path:

```bash
cabal build --extra-lib-dirs=/usr/local/lib
```

**Error**: `cbits/mylib.c: No such file or directory`

**Solution**: Check c-sources path:

```cabal
c-sources: cbits/mylib.c  -- Relative to .cabal file
```

## Advanced Features

### Custom Setup

For complex builds, create `Setup.hs`:

```haskell
import Distribution.Simple
import System.Process

main = defaultMainWithHooks simpleUserHooks
  { preBuild = \args flags -> do
      -- Run custom build step
      callCommand "make -C cbits"
      preBuild simpleUserHooks args flags
  }
```

Then in `.cabal`:

```cabal
cabal-version: 2.0
build-type: Custom

custom-setup
  setup-depends:
    base >= 4.7,
    Cabal,
    process
```

### Profiling Configuration

```cabal
library
  ghc-prof-options: -fprof-auto -rtsopts

executable my-program
  ghc-prof-options: -fprof-auto -rtsopts
  -- Enables: ghc -prof -fprof-auto -rtsopts
```

```bash
# Build with profiling
cabal build --enable-profiling

# Run with profiling
./dist-newstyle/.../my-program +RTS -p -hc
```

## Quick Reference

### Cabal Commands

| Command | Purpose |
|---------|---------|
| `cabal init` | Create new project |
| `cabal build` | Build project |
| `cabal run` | Build and run executable |
| `cabal test` | Run tests |
| `cabal bench` | Run benchmarks |
| `cabal repl` | Start REPL |
| `cabal clean` | Clean build artifacts |

### Stack Commands

| Command | Purpose |
|---------|---------|
| `stack new` | Create new project |
| `stack build` | Build project |
| `stack exec` | Run executable |
| `stack test` | Run tests |
| `stack bench` | Run benchmarks |
| `stack repl` | Start REPL |
| `stack clean` | Clean build artifacts |

### GHC Options

| Option | Purpose |
|--------|---------|
| `-Wall` | Enable all warnings |
| `-O2` | Full optimization |
| `-threaded` | Use threaded RTS |
| `-rtsopts` | Enable RTS options |
| `-prof` | Enable profiling |
| `-fllvm` | Use LLVM backend |
| `-fuse-ld=lld` | Use lld linker |

---

## Quick Navigation

- **Previous**: [← CI/CD Setup](./a-cicd-setup.md)
- **Next**: [Further Reading →](./c-further-reading.md)
- **Main**: [← Back to Book](../README.md)
