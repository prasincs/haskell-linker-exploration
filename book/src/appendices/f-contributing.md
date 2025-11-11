# Appendix F: Contributing

## How to Contribute to This Book

This educational resource welcomes contributions from the community!

## Ways to Contribute

### Reporting Issues

If you find:
- Errors in documentation
- Broken examples
- Outdated information
- Unclear explanations
- Broken links

Please [open an issue](../../issues) with:
- Clear description of the problem
- Steps to reproduce (if applicable)
- Suggested fix (optional)
- Which chapter/section

### Suggesting Enhancements

We welcome suggestions for:
- Additional PoCs demonstrating related concepts
- Better explanations or diagrams
- Performance comparisons
- Real-world examples
- Links to relevant resources
- New chapters or sections

### Improving Documentation

**Areas that need help**:
- Clarifying complex concepts
- Adding more diagrams
- Providing alternative explanations
- Platform-specific guides (macOS, Windows)
- Translations to other languages

## Contributing Code

### Getting Started

**1. Fork and Clone**:

```bash
git clone https://github.com/yourusername/haskell-linker-exploration.git
cd haskell-linker-exploration
```

**2. Create a Branch**:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

**3. Make Your Changes**:

For new PoCs:
- Create directory: `poc4-your-concept/`
- Include comprehensive README.md
- Add build scripts that work in Docker
- Update main README.md to reference it

For documentation:
- Keep explanations clear and accessible
- Include code examples where helpful
- Add diagrams using Mermaid when appropriate
- Link to authoritative sources

For code:
- Keep examples simple and focused
- Add comments explaining key concepts
- Ensure scripts work in Docker environment
- Test thoroughly

### Testing Your Changes

**Build Docker image**:

```bash
docker build -t ghc-linker-poc-test .
```

**Test your changes**:

```bash
docker run --rm ghc-linker-poc-test ./your-new-script.sh
```

**Test all PoCs still work**:

```bash
docker run --rm ghc-linker-poc-test ./scripts/run-all-demos.sh
```

**Build the book**:

```bash
cd book
mdbook build
mdbook serve  # Preview at http://localhost:3000
```

### Commit and Push

**Make commits**:

```bash
git add .
git commit -m "Brief description of your changes

Longer explanation if needed:
- What changed
- Why it changed
- Any breaking changes"

git push origin feature/your-feature-name
```

**Commit message guidelines**:
- Use [Conventional Commits](https://www.conventionalcommits.org/)
- Start with type: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`
- Keep first line under 72 characters
- Provide detailed explanation in body if needed

### Submit a Pull Request

**Go to GitHub**:
1. Click "New Pull Request"
2. Select your branch
3. Fill in the PR template

**PR Template**:

```markdown
## What

Describe your changes

## Why

Explain the motivation

## Testing

How you verified it works
- [ ] All PoCs build and run
- [ ] Documentation builds
- [ ] Links verified
- [ ] Code examples tested

## Screenshots

If adding diagrams or changing output
```

## Code Style

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

### Markdown Documentation

**Style guide**:
- Use GitHub-flavored Markdown
- Keep paragraphs short (3-4 sentences max)
- Use tables for comparisons
- Use code blocks with syntax highlighting
- Link to primary sources
- Prefer Mermaid diagrams over images

**Example**:

```markdown
# Chapter Title

## Section

Brief introduction paragraph.

### Subsection

Key points:
- First point
- Second point

**Example**:
​```haskell
-- Code example
main = putStrLn "Hello"
​```

See [related chapter](./other-chapter.md) for more details.
```

## Areas for Contribution

### High Priority

- **PoC 4**: Dynamic linking comparison
- **More Diagrams**: RTS architecture, memory layout
- **Video Tutorials**: Walkthroughs of each PoC
- **Benchmarks**: Quantify FFI vs gRPC performance
- **Windows Support**: Make PoCs work on Windows

### Documentation

- **Platform Guides**: macOS, Windows-specific instructions
- **Troubleshooting**: More common issues and solutions
- **Case Studies**: Real-world examples
- **Translations**: Non-English versions

### Code Examples

- **PoC 5**: Cross-compilation challenges
- **PoC 6**: Haskell + Rust FFI
- **Comparison Tool**: Automated performance testing
- **CI/CD Examples**: GitHub Actions, GitLab CI

### Tooling

- **Pre-commit Hooks**: Validate scripts and markdown
- **Automated Tests**: Verify all PoCs work
- **Dependency Updates**: Keep versions current
- **Link Checker**: Verify all links work

## Review Process

### What We Look For

**Code contributions**:
- ✅ Builds successfully in Docker
- ✅ Clear, commented code
- ✅ Includes tests
- ✅ Documentation updated

**Documentation contributions**:
- ✅ Technically accurate
- ✅ Clear and well-organized
- ✅ Links to sources
- ✅ Consistent with existing style

**New PoCs**:
- ✅ Demonstrates clear concept
- ✅ Works in Docker
- ✅ Well-documented
- ✅ Adds value to existing PoCs

### Timeline

- Initial review: Within 1 week
- Follow-up: As needed
- Merge: When all checks pass

## Recognition

Contributors will be acknowledged in:
- Main README.md
- Release notes
- Individual chapter credits (where applicable)

## Questions?

- **GitHub Discussions**: Ask questions about the project
- **Issues**: For bugs and feature requests
- **Email**: See [METHODOLOGY.md](../../METHODOLOGY.md) for contact

## Code of Conduct

### Our Standards

**Positive environment**:
- ✅ Be respectful and inclusive
- ✅ Accept constructive criticism
- ✅ Focus on what's best for the community
- ✅ Show empathy toward others

**Not acceptable**:
- ❌ Harassment or discrimination
- ❌ Trolling or insulting comments
- ❌ Public or private harassment
- ❌ Publishing others' private information

### Enforcement

Violations will be addressed:
1. Warning
2. Temporary ban
3. Permanent ban (if needed)

## License

By contributing, you agree that your contributions will be licensed under the **MIT License**.

See [LICENSE](../../LICENSE) for details.

## Thank You!

Every contribution makes this resource better for the entire Haskell community!

---

## Quick Navigation

- **Previous**: [← Methodology](./e-methodology.md)
- **Main**: [← Back to Book](../README.md)
- **Full Contributing Guide**: [`../../CONTRIBUTING.md`](../../CONTRIBUTING.md)
