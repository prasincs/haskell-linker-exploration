# Methodology: How This Repository Was Created

## The Origin

This repository started with a genuine question from my experience working with GHC and LLVM:

> "Since Rust and Haskell can both use LLVM backends, why can't I just use lld to link Haskell object files?"

When I tried it, I got hundreds of undefined reference errors. That failure led me down a rabbit hole of understanding GHC's architecture, the Runtime System, and why GHC must orchestrate linking. I realized there wasn't a comprehensive resource that:
- **Demonstrated the problem** with runnable code
- **Explained the why** with technical depth
- **Compared approaches** (FFI vs gRPC, Haskell vs Rust)

So I built one.

---

## The Process

### 1. Research & Proof-of-Concept Development (Human)

**What I did:**
- Created the basic Haskell and C code examples
- Tested naive linking attempts with lld and documented failures
- Built working FFI integration examples
- Set up Docker environment for reproducibility
- Identified the "general contractor" analogy for GHC's role
- Developed the Rust vs Haskell comparison framework

**Why this matters:** The **research question** came from real experience. AI can't identify gaps in documentation or create novel analogies.

### 2. Documentation & Structure (Human + AI Collaboration)

**What I did:**
- Outlined the key concepts to explain
- Identified official sources for verification
- Structured the progression (simple → complex)
- Added the Rust comparison as a differentiator

**What Claude (Anthropic AI) did:**
- Helped structure explanations for clarity
- Generated comprehensive documentation from my technical direction
- Created Mermaid diagrams for visualization
- Expanded on technical concepts with examples
- Produced the detailed FFI guide and linking process documentation
- Helped organize the flow and added cross-references

**Analogy:** Like using LaTeX for typesetting or an IDE for code completion - AI amplified my expertise but didn't replace it.

### 3. Verification (Human - Critical Step)

**What I verified:**
- ✅ All code examples compile and run correctly
- ✅ Docker container builds and executes successfully
- ✅ Every technical claim against official sources:
  - GHC User's Guide (v9.12.2)
  - Academic papers (Peyton Jones 1992, Harris 2009, etc.)
  - GHC Commentary wiki
  - Haskell 2010 Report (FFI specification)
- ✅ All links functional and point to authoritative sources
- ✅ Bash scripts syntax-checked
- ✅ Version numbers accurate (GHC 9.4.8 → base-4.17.2.1)

**Why this matters:** AI can hallucinate. I ensured every claim is **verifiable**.

### 4. Novel Contributions (Human)

**Original insights I added:**
- The "general contractor" analogy for GHC's role
- Quantifying the difference (7 vs 140+ linker arguments)
- Rust vs Haskell runtime trade-off analysis
  - "Haskell's runtime is a feature, not a bug"
  - Observing that Rust async runtimes re-implement RTS features
- The three-tier approach: problem demonstration → technical explanation → alternative solution (gRPC)

**Why this matters:** These insights come from **domain expertise**, not AI generation.

---

## What Makes This Valuable

### 1. **Runnable Proof-of-Concepts**

**Not just documentation** - actual code you can execute:
```bash
docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh
```

You'll see:
- ld.lld fails with 100+ undefined references
- GHC succeeds with 140+ arguments
- The executable runs correctly

**This is orders of magnitude harder than writing about code.** It requires understanding the problem deeply enough to demonstrate it.

### 2. **Technical Accuracy**

Every claim is backed by authoritative sources:

| Claim | Source | Verified |
|-------|--------|----------|
| STG machine architecture | Peyton Jones, JFP 1992 | [✅ PDF](https://www.microsoft.com/en-us/research/wp-content/uploads/1992/04/spineless-tagless-gmachine.pdf) |
| GHC 9.4.8 base version | GHC release notes | [✅ 4.17.2.1](https://www.haskell.org/ghc/blog/20231110-ghc-9.4.8-released.html) |
| RTS options | GHC User's Guide | [✅ Official docs](https://downloads.haskell.org/ghc/latest/docs/users_guide/runtime_control.html) |
| FFI specification | Haskell 2010 Report | [✅ Chapter 8](https://www.haskell.org/onlinereport/haskell2010/haskellch8.html) |

### 3. **Fills a Real Gap**

Before this repository:
- **Stack Overflow**: Fragmented answers, no comprehensive view
- **GHC Commentary**: Accurate but reference-focused, not tutorial
- **Academic papers**: Theoretical, no runnable examples
- **Blog posts**: Often hand-wave the details

After this repository:
- **Working demonstrations** of why naive linking fails
- **Complete documentation** from basics to RTS internals
- **Practical comparison** of approaches (FFI vs gRPC)
- **Design trade-offs** explained (Rust vs Haskell)

---

## Transparency About AI Assistance

### What AI Did Well:

✅ **Structuring** - Organizing concepts logically
✅ **Expanding** - Turning outlines into comprehensive documentation
✅ **Visualizing** - Creating Mermaid diagrams from descriptions
✅ **Examples** - Generating code examples from patterns I specified
✅ **Cross-referencing** - Adding links between related sections

### What AI Cannot Do:

❌ **Original research** - Identifying the question
❌ **Domain expertise** - Understanding GHC internals
❌ **Verification** - Ensuring technical accuracy
❌ **Novel insights** - Creating the Rust comparison
❌ **Code that works** - Making PoCs actually executable

### The Role of Human Expertise:

**I brought:**
- Years of experience with GHC and systems programming
- Understanding of compiler architecture and linking
- Ability to identify what's missing in existing documentation
- Knowledge to verify claims against authoritative sources
- Insight to compare Haskell's design with Rust's approach

**AI brought:**
- Speed in generating comprehensive documentation
- Consistency in formatting and structure
- Ability to create detailed diagrams
- Help articulating complex concepts clearly

**Result:** A resource that combines human expertise with AI capabilities to create something better than either alone.

---

## Quality Standards

### Every Page Must Meet:

1. ✅ **Technical accuracy** - All claims verified against official sources
2. ✅ **Reproducibility** - All code examples work
3. ✅ **Completeness** - No hand-waving complex topics
4. ✅ **Clarity** - Concepts explained for various expertise levels
5. ✅ **Citations** - Academic papers and official docs properly referenced

### Testing Methodology:

```bash
# All code verified:
bash -n poc1-linker-comparison/build.sh  # ✓ Syntax OK
bash -n poc2-ffi-integration/build.sh    # ✓ Syntax OK
docker build -t ghc-linker-poc .         # ✓ Builds successfully
docker run --rm ghc-linker-poc ./poc1-linker-comparison/build.sh  # ✓ Runs
```

### Link Verification:

- GHC User's Guide links → ✅ Checked
- Academic papers → ✅ Verified accessible
- Code references → ✅ Confirmed correct line numbers
- Related projects → ✅ Verified active and relevant

---

## Contributing & Corrections

### Found an Error?

**Please open an issue!** I take accuracy seriously.

Include:
- What's wrong (with source/evidence)
- What it should be
- Reference to official documentation

### Want to Improve It?

**Pull requests welcome!**

Especially interested in:
- Additional PoCs or examples
- Platform-specific guidance (macOS, Windows)
- Alternative explanations
- Performance measurements
- Translation to other languages

### Quality Over Speed

I'd rather have:
- ✅ One accurate, well-researched resource
- ❌ Ten superficial tutorials

---

## The "AI Slop" Question

### What Makes Content Low-Quality?

❌ Generic explanations that could apply to anything
❌ Code that doesn't compile
❌ Unverified or hallucinated claims
❌ No original insight or value
❌ Mass-produced without expertise

### What Makes This Repository High-Quality?

✅ **Specific to the problem** - GHC linking architecture
✅ **Working code** - All PoCs execute correctly
✅ **Verified claims** - Every fact cited and checked
✅ **Original insights** - Novel comparisons and analogies
✅ **Expert-driven** - Built from genuine understanding

### The Real Test:

**Would this be valuable if I wrote every word by hand?**

**Yes** - because:
- The research question is important
- The demonstrations prove the point
- The explanations are accurate
- The comparisons are insightful
- No other resource quite like this exists

**Therefore:** The value is in the **insight, accuracy, and completeness**, not in how the words were generated.

---

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
- Dmitrii Kovanikov and others for clarifications

---

## License & Usage

This repository is MIT licensed. You are free to:
- Use it for learning
- Reference it in courses or tutorials
- Build upon it
- Share it widely

**Just:**
- Maintain accuracy (verify claims)
- Give appropriate credit
- Don't present errors as facts

---

## Final Note

This repository represents the kind of technical documentation I wish existed when I was learning about GHC internals. I used every tool at my disposal - experience, research, AI assistance, and community knowledge - to create the best possible resource.

**The goal:** Make GHC's architecture accessible and understandable through working examples and clear explanations.

**The method:** Whatever works, as long as it's accurate and verifiable.

**The commitment:** If you find errors, I'll fix them. Quality matters.

---

**Questions about methodology?** Open an issue or discussion.
