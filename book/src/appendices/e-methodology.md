# Appendix E: Methodology

## How This Book Was Created

This appendix provides **full transparency** about how this educational resource was developed.

## The Origin

This project started with a genuine question from working with GHC and LLVM:

> "Since Rust and Haskell can both use LLVM backends, why can't I just use lld to link Haskell object files?"

When attempting this led to hundreds of undefined reference errors, it sparked a deep investigation into GHC's architecture, the Runtime System, and why GHC must orchestrate linking.

**The gap**: No comprehensive resource existed that:
- Demonstrated the problem with runnable code
- Explained the underlying reasons with technical depth
- Compared different approaches (FFI vs gRPC, Haskell vs Rust)
- Provided interactive learning experiences

This book fills that gap.

## The Process

### 1. Research & Proof-of-Concept Development

**What was done**:
- Created basic Haskell and C code examples
- Tested naive linking attempts with lld and documented failures
- Built working FFI integration examples
- Developed gRPC microservices comparison
- Set up Docker environment for reproducibility
- Identified the "general contractor" analogy for GHC's role
- Developed the Rust vs Haskell comparison framework

**Why this matters**: The research question came from real experience. The working code demonstrates rather than just describes.

### 2. Documentation & Structure

**Human contributions**:
- Outlined key concepts to explain
- Identified official sources for verification
- Structured the progression (simple → complex)
- Added the Rust comparison as differentiator
- Created overall architecture and flow

**AI assistance (Claude - Anthropic)**:
- Helped structure explanations for clarity
- Generated comprehensive documentation from technical direction
- Created Mermaid diagrams for visualization
- Expanded on technical concepts with examples
- Produced detailed FFI guide and linking process documentation
- Helped organize flow and added cross-references

**Analogy**: Like using LaTeX for typesetting or an IDE for code completion - AI amplified expertise but didn't replace it.

### 3. Verification (Critical Step)

**Every claim verified against**:
- ✅ GHC User's Guide (v9.4.8+)
- ✅ Academic papers (Peyton Jones 1992, Harris 2009, Marlow 2008)
- ✅ GHC Commentary wiki
- ✅ Haskell 2010 Report (FFI specification)
- ✅ Working code execution

**Quality checks**:
- ✅ All code examples compile and run correctly
- ✅ Docker container builds and executes successfully
- ✅ All links functional and point to authoritative sources
- ✅ Version numbers accurate (GHC 9.4.8 → base-4.17.2.1)
- ✅ Bash scripts syntax-checked

**Why this matters**: AI can hallucinate. Human verification ensures every claim is verifiable.

### 4. Novel Contributions

**Original insights added**:
- The "general contractor" analogy for GHC's role
- Quantifying the difference (7 vs 140+ linker arguments)
- Rust vs Haskell runtime trade-off analysis
  - "Haskell's runtime is a feature, not a bug"
  - Observation that Rust async runtimes re-implement RTS features
- Three-tier approach: problem demonstration → technical explanation → alternative solution

**Why this matters**: These insights come from domain expertise, not AI generation.

## What Makes This Valuable

### 1. Runnable Proof-of-Concepts

Not just documentation - actual code you can execute:

```bash
docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh
```

You'll see:
- lld fails with 100+ undefined references
- GHC succeeds with 140+ arguments
- The executable runs correctly

**This is harder than writing about code** - it requires deep understanding to demonstrate.

### 2. Technical Accuracy

Every claim is backed by authoritative sources:

| Claim | Source | Verified |
|-------|--------|----------|
| STG machine architecture | Peyton Jones, JFP 1992 | ✅ [PDF](https://www.microsoft.com/en-us/research/wp-content/uploads/1992/04/spineless-tagless-gmachine.pdf) |
| GHC 9.4.8 base version | GHC release notes | ✅ [4.17.2.1](https://www.haskell.org/ghc/blog/20231110-ghc-9.4.8-released.html) |
| RTS options | GHC User's Guide | ✅ [Official docs](https://downloads.haskell.org/ghc/latest/docs/users_guide/runtime_control.html) |
| FFI specification | Haskell 2010 Report | ✅ [Chapter 8](https://www.haskell.org/onlinereport/haskell2010/haskellch8.html) |

### 3. Fills a Real Gap

**Before this resource**:
- Stack Overflow: Fragmented answers, no comprehensive view
- GHC Commentary: Accurate but reference-focused, not tutorial
- Academic papers: Theoretical, no runnable examples
- Blog posts: Often hand-wave the details

**After this resource**:
- Working demonstrations of why naive linking fails
- Complete documentation from basics to RTS internals
- Practical comparison of approaches (FFI vs gRPC)
- Design trade-offs explained (Rust vs Haskell)

## Transparency About AI Assistance

### What AI Did Well

✅ **Structuring**: Organizing concepts logically
✅ **Expanding**: Turning outlines into comprehensive documentation
✅ **Visualizing**: Creating Mermaid diagrams from descriptions
✅ **Examples**: Generating code examples from specified patterns
✅ **Cross-referencing**: Adding links between related sections

### What AI Cannot Do

❌ **Original research**: Identifying the question
❌ **Domain expertise**: Understanding GHC internals
❌ **Verification**: Ensuring technical accuracy
❌ **Novel insights**: Creating the Rust comparison
❌ **Code that works**: Making PoCs actually executable

### The Role of Human Expertise

**Human brought**:
- Years of experience with GHC and systems programming
- Understanding of compiler architecture and linking
- Ability to identify gaps in existing documentation
- Knowledge to verify claims against authoritative sources
- Insight to compare Haskell's design with Rust's approach

**AI brought**:
- Speed in generating comprehensive documentation
- Consistency in formatting and structure
- Ability to create detailed diagrams
- Help articulating complex concepts clearly

**Result**: A resource combining human expertise with AI capabilities to create something better than either alone.

## Quality Standards

### Every Chapter Must Meet

1. ✅ **Technical accuracy**: All claims verified against official sources
2. ✅ **Reproducibility**: All code examples work
3. ✅ **Completeness**: No hand-waving complex topics
4. ✅ **Clarity**: Concepts explained for various expertise levels
5. ✅ **Citations**: Academic papers and official docs properly referenced

### Testing Methodology

```bash
# All code verified
bash -n poc1-linker-comparison/build.sh  # ✓ Syntax OK
bash -n poc2-ffi-integration/build.sh    # ✓ Syntax OK
docker build -t ghc-linker-poc .         # ✓ Builds successfully
docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh  # ✓ Runs
```

### Link Verification

- GHC User's Guide links → ✅ Checked
- Academic papers → ✅ Verified accessible
- Code references → ✅ Confirmed correct
- Related projects → ✅ Verified active and relevant

## Contributing & Corrections

### Found an Error?

Please open an issue! Accuracy is taken seriously.

**Include**:
- What's wrong (with source/evidence)
- What it should be
- Reference to official documentation

### Want to Improve It?

Pull requests welcome!

**Especially interested in**:
- Additional PoCs or examples
- Platform-specific guidance (macOS, Windows)
- Alternative explanations
- Performance measurements
- Translations

## The "AI-Generated Content" Question

### What Makes Content Low-Quality?

❌ Generic explanations that could apply to anything
❌ Code that doesn't compile
❌ Unverified or hallucinated claims
❌ No original insight or value
❌ Mass-produced without expertise

### What Makes This Resource High-Quality?

✅ **Specific to the problem**: GHC linking architecture
✅ **Working code**: All PoCs execute correctly
✅ **Verified claims**: Every fact cited and checked
✅ **Original insights**: Novel comparisons and analogies
✅ **Expert-driven**: Built from genuine understanding

### The Real Test

**Would this be valuable if every word was written by hand?**

**Yes** - because:
- The research question is important
- The demonstrations prove the point
- The explanations are accurate
- The comparisons are insightful
- No other resource quite like this exists

**Therefore**: The value is in the **insight, accuracy, and completeness**, not in how the words were generated.

## Acknowledgments

### Primary Author

**Prasanna** - Original research, technical insights, code development, verification

### AI Assistance

**Claude (Anthropic)** - Documentation structure, diagram generation, expansion of explanations

### Verified Against

- GHC User's Guide and Commentary
- Academic papers (Peyton Jones 1992, Harris 2009, Marlow 2008)
- Official Haskell documentation
- Working code execution

### Community

- GHC developers for 30+ years of work
- Haskell community for knowledge sharing
- Academic researchers for foundational work

## License & Usage

This book is **MIT licensed**. You are free to:
- Use it for learning
- Reference it in courses or tutorials
- Build upon it
- Share it widely

**Just**:
- Maintain accuracy (verify claims)
- Give appropriate credit
- Don't present errors as facts

## Final Note

This resource represents the kind of technical documentation that should exist for complex systems. Every tool available was used - experience, research, AI assistance, and community knowledge - to create the best possible educational resource.

**The goal**: Make GHC's architecture accessible and understandable through working examples and clear explanations.

**The method**: Whatever works, as long as it's accurate and verifiable.

**The commitment**: Errors will be fixed. Quality matters.

---

## Quick Navigation

- **Previous**: [← Glossary](./d-glossary.md)
- **Next**: [Contributing →](./f-contributing.md)
- **Full Methodology**: [`../../METHODOLOGY.md`](../../METHODOLOGY.md)
- **Main**: [← Back to Book](../README.md)
