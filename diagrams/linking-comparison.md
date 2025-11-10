# Linking Comparison: Naive vs GHC

This diagram visualizes the difference between attempting to link Haskell code with a standard linker versus using GHC as the driver.

## Naive Linking Attempt (Fails)

```mermaid
graph TD
    A[Hello.o<br/>Your compiled Haskell code] --> B[lld]
    C[-lc<br/>C standard library] --> B
    D[-lpthread<br/>POSIX threads] --> B
    E[-ldl<br/>Dynamic loading] --> B
    B --> F[❌ Link Failed]

    F --> G[Missing Symbols:<br/>- base_GHCziTopHandler_*<br/>- stg_ap_0_fast<br/>- ghc-prim symbols<br/>- RTS symbols<br/>... hundreds more]

    style F fill:#f99,stroke:#f00,stroke-width:3px
    style G fill:#fcc,stroke:#f00,stroke-width:2px
```

### Why It Fails

The linker cannot find:
- **Haskell Runtime System (RTS)**: `libHSrts.a`
- **Base library**: All standard Haskell functions
- **GHC primitives**: Core language operations
- **STG machine**: Lazy evaluation implementation

---

## GHC-Orchestrated Linking (Succeeds)

```mermaid
graph TD
    A[Your Code] --> Z[GHC Driver]

    Z --> B[Startup Code<br/>crt0.o, crti.o]
    Z --> C[Your Objects<br/>Hello.o]
    Z --> D[Base Library<br/>libHSbase-4.x.a]
    Z --> E[GHC Primitives<br/>libHSghc-prim-0.x.a]
    Z --> F[Integer Library<br/>libHSinteger-gmp-1.x.a]
    Z --> G[10+ Boot Packages<br/>array, deepseq, etc.]
    Z --> H[Runtime System<br/>libHSrts.a]
    Z --> I[System Libraries<br/>-lgmp -lm -lc -lpthread]
    Z --> J[Shutdown Code<br/>crtn.o]

    B --> K[System Linker<br/>ld / ld.lld / ld.gold]
    C --> K
    D --> K
    E --> K
    F --> K
    G --> K
    H --> K
    I --> K
    J --> K

    K --> L[✅ Executable<br/>hello]

    style Z fill:#9f9,stroke:#090,stroke-width:3px
    style L fill:#9f9,stroke:#090,stroke-width:3px
```

### What GHC Provides

1. **Knowledge of RTS Location**: Where to find `libHSrts.a` and which variant to use
2. **Package Database**: Complete dependency graph of all Haskell libraries
3. **Correct Ordering**: Topological sort of dependencies
4. **Calling Convention**: Ensures consistency between all Haskell code
5. **Platform Specifics**: Handles differences between Linux, macOS, Windows

---

## Argument Count Comparison

```mermaid
graph LR
    subgraph Naive Attempt
        A1[lld] --> A2[7 arguments]
        A2 --> A3[Hello.o<br/>-lc<br/>-lpthread<br/>-ldl<br/>-lm<br/>-o hello_fail]
    end

    subgraph GHC Linking
        B1[ghc] --> B2[140+ arguments]
        B2 --> B3[100+ library paths<br/>20+ object files<br/>15+ system libraries<br/>Startup/shutdown code<br/>RTS options]
    end

    style A2 fill:#fcc,stroke:#f00
    style B2 fill:#cfc,stroke:#090
```

---

## Component Dependency Graph

```mermaid
graph TD
    A[Your Hello.hs] --> B[base]
    B --> C[ghc-prim]
    B --> D[integer-gmp]
    D --> E[gmp<br/>system library]
    B --> F[array]
    F --> C

    A --> G[Haskell RTS]
    G --> H[Garbage Collector]
    G --> I[Scheduler]
    G --> J[Heap Manager]
    G --> K[FFI Support]

    C --> L[No dependencies]

    style A fill:#9cf,stroke:#06f
    style G fill:#f9f,stroke:#90f
    style B fill:#fc9,stroke:#f60
    style C fill:#fc9,stroke:#f60
    style D fill:#fc9,stroke:#f60
    style E fill:#ccc,stroke:#666
```

**Key Insight**: Even a "Hello, World" program has a complex dependency graph. Only GHC knows the complete graph and can link it correctly.

---

## The GHC "General Contractor" Model

```mermaid
graph TD
    A[You: The Architect] --> B[GHC: General Contractor]

    B --> C[Phase 1: Compilation]
    C --> C1[Parse source code]
    C --> C2[Type checking]
    C --> C3[Optimize Core IR]
    C --> C4[Generate object files]

    B --> D[Phase 2: Dependency Resolution]
    D --> D1[Query package database]
    D --> D2[Build dependency graph]
    D --> D3[Topological sort]

    B --> E[Phase 3: Link Command Construction]
    E --> E1[Select RTS variant]
    E --> E2[Find all libraries]
    E --> E3[Determine link order]
    E --> E4[Add platform-specific flags]

    B --> F[Phase 4: Delegation]
    F --> F1[System Linker<br/>ld.lld / ld.gold / ld]
    F1 --> G[Executable]

    style B fill:#9f9,stroke:#090,stroke-width:3px
    style G fill:#9cf,stroke:#06f,stroke-width:3px
```

---

## Linker Choice: GHC Delegates

```mermaid
graph LR
    A[GHC Driver] --> B{Which Linker?}

    B -->|Default| C[GNU ld<br/>Slow, Universal]
    B -->|-pgml=ld.gold| D[gold<br/>Fast, Google's linker]
    B -->|-pgml=ld.lld| E[lld<br/>Very Fast, LLVM's linker]
    B -->|macOS| F[ld64<br/>Apple's linker]

    C --> G[GHC constructs<br/>140+ argument command]
    D --> G
    E --> G
    F --> G

    G --> H[System Linker<br/>does the actual work]
    H --> I[Executable]

    style A fill:#9f9,stroke:#090
    style E fill:#9cf,stroke:#06f
    style I fill:#fc9,stroke:#f60
```

**Key Insight**: You can choose your system linker (ld, gold, lld), but you cannot bypass GHC because only GHC knows:
- Where all the Haskell libraries are
- Which RTS variant to use
- The correct dependency order
- Platform-specific requirements

---

## Memory Layout After Linking

```mermaid
graph TD
    subgraph "Executable Memory Layout"
        A[Text Segment<br/>Code]
        B[Data Segment<br/>Global Variables]
        C[BSS Segment<br/>Uninitialized Data]
        D[Heap<br/>Dynamic Memory]
        E[Stack<br/>Function Calls]
    end

    subgraph "Haskell-Specific"
        F[RTS Code<br/>GC, Scheduler, etc.]
        G[Haskell Heap<br/>Closures, Thunks]
        H[RTS Stack<br/>Update Frames]
        I[Info Tables<br/>GC Metadata]
    end

    A --> F
    D --> G
    E --> H
    B --> I

    style F fill:#f9f,stroke:#90f
    style G fill:#f9f,stroke:#90f
    style H fill:#f9f,stroke:#90f
    style I fill:#f9f,stroke:#90f
```

The RTS is embedded throughout the executable, which is why naive linking fails—the linker doesn't know about these Haskell-specific sections.

---

## Back to Main Documentation

- [Main README](../README.md)
- [GHC Architecture](../docs/ghc-architecture.md)
- [Linking Process](../docs/linking-process.md)
- [Runtime System](../docs/rts-explained.md)
