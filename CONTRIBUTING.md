# Contributing to Haskell Linker Exploration

Thank you for your interest in contributing! This repository is designed to be an educational resource about GHC's compilation and linking process.

## How to Contribute

### Reporting Issues

If you find:
- Errors in documentation
- Broken examples
- Outdated information
- Unclear explanations

Please [open an issue](https://github.com/yourusername/haskell-linker-exploration/issues/new) with:
- A clear description of the problem
- Steps to reproduce (if applicable)
- Suggested fix (optional)

### Suggesting Enhancements

We welcome suggestions for:
- Additional PoCs demonstrating related concepts
- Better explanations or diagrams
- Performance comparisons
- Real-world examples
- Links to relevant resources

### Contributing Code

#### 1. Fork and Clone

```bash
git clone https://github.com/yourusername/haskell-linker-exploration.git
cd haskell-linker-exploration
```

#### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

#### 3. Make Your Changes

**For new PoCs:**
- Create a new directory: `poc4-your-concept/`
- Include a comprehensive README.md
- Add build scripts that work in Docker
- Update the main README.md to reference it

**For documentation:**
- Keep explanations clear and accessible
- Include code examples where helpful
- Add diagrams using Mermaid when appropriate
- Link to authoritative sources

**For code:**
- Keep examples simple and focused
- Add comments explaining key concepts
- Ensure scripts work in the Docker environment
- Test thoroughly

#### 4. Test Your Changes

```bash
# Build the Docker image
docker build -t ghc-linker-poc-test .

# Test your changes
docker run --rm ghc-linker-poc-test ./your-new-script.sh

# Test all PoCs still work
docker run --rm ghc-linker-poc-test ./scripts/run-all-demos.sh
```

#### 5. Commit and Push

```bash
git add .
git commit -m "Brief description of your changes

Longer explanation if needed:
- What changed
- Why it changed
- Any breaking changes
"

git push origin feature/your-feature-name
```

#### 6. Submit a Pull Request

- Go to the repository on GitHub
- Click "New Pull Request"
- Select your branch
- Fill in the PR template:
  - **What**: Describe your changes
  - **Why**: Explain the motivation
  - **Testing**: How you verified it works
  - **Screenshots**: If adding diagrams or changing output

## Code Style

### Shell Scripts

```bash
#!/bin/bash
set -e  # Exit on error

# Use descriptive variable names
LINKER_COMMAND="ghc -o program main.o"

# Add comments for non-obvious code
# Extract the linker command from verbose output
LINK_CMD=$(grep -A 1 '*** Linker:' ghc_verbose.log)

# Use echo for user-facing messages
echo "Building example..."

# Prefer || true for expected failures
lld -o fail Hello.o 2> errors.log || true
```

### Haskell Code

```haskell
-- Use clear, pedagogical examples
-- Avoid advanced features unless demonstrating them

-- Good: Simple, clear
fibonacci :: Int -> Int
fibonacci 0 = 0
fibonacci 1 = 1
fibonacci n = fibonacci (n-1) + fibonacci (n-2)

-- Avoid: Overly clever for educational code
-- fib = (map fst . iterate (\(a,b) -> (b,a+b))) (0,1) !!
```

### Documentation

- Use GitHub-flavored Markdown
- Keep paragraphs short (3-4 sentences max)
- Use tables for comparisons
- Use code blocks with syntax highlighting
- Link to primary sources (GHC docs, papers)
- Prefer Mermaid diagrams over external images

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Add PoC 4 for dynamic linking comparison
fix: Correct RTS library path in Docker image
docs: Improve explanation of Core IR optimizations
refactor: Simplify build.sh script
test: Add validation for linker command parsing
```

## Areas for Contribution

### High Priority

- **PoC 3 Implementation**: Complete the gRPC example with working code
- **More Diagrams**: Visualize RTS architecture, memory layout, etc.
- **Video Tutorials**: Record walkthroughs of each PoC
- **Benchmarks**: Quantify FFI vs gRPC performance

### Documentation

- **docs/linking-process.md**: Detailed linking explanation
- **docs/ffi-guide.md**: Comprehensive FFI reference
- **docs/modern-alternatives.md**: When to use alternatives
- **Case Studies**: Real-world examples of each approach

### Code Examples

- **PoC 4**: Dynamic linking and shared libraries
- **PoC 5**: Cross-compilation challenges
- **PoC 6**: Haskell + Rust FFI
- **Comparison Tool**: Automated performance testing

### Tooling

- **CI/CD**: GitHub Actions for testing
- **Pre-commit Hooks**: Validate scripts and markdown
- **Automated Tests**: Verify all PoCs work
- **Dependency Updates**: Keep GHC/LLVM versions current

## Questions?

- **Slack/Discord**: [Link if available]
- **GitHub Discussions**: Ask questions about the project
- **Issues**: For bugs and feature requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License (see [LICENSE](./LICENSE)).

## Recognition

Contributors will be acknowledged in:
- The main README.md
- Release notes
- Individual PoC READMEs where applicable

Thank you for helping make this a better educational resource!
