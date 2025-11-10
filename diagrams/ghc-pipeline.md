# GHC Compilation Pipeline

This document contains Mermaid diagrams visualizing GHC's compilation and linking process.

## Complete Compilation Pipeline

```mermaid
flowchart TD
    Start([Haskell Source Code<br/>Hello.hs]) --> Parser

    subgraph Frontend[Front End]
        Parser[Parser<br/>Parse source to AST] --> Renamer
        Renamer[Renamer<br/>Resolve names and imports] --> TypeChecker
        TypeChecker[Type Checker<br/>Infer and check types]
    end

    TypeChecker --> Desugarer

    subgraph MiddleEnd[Middle End - Core IR]
        Desugarer[Desugarer<br/>Convert to Core IR] --> Simplifier
        Simplifier[Simplifier<br/>Inlining, beta-reduction] --> Optimizer
        Optimizer[Core Optimizations<br/>10+ transformation passes] --> Optimizer
        Optimizer --> STGConvert[Convert to STG]
    end

    STGConvert --> CmmGen

    subgraph BackEnd[Back End]
        CmmGen[C-- Generation<br/>Low-level IR] --> BackendChoice{Backend?}
        BackendChoice -->|Default| NCG[Native Code Generator<br/>Fast compilation]
        BackendChoice -->|"-fllvm"| LLVM[LLVM Backend<br/>Better optimization]
        NCG --> Assembly1[Assembly Code]
        LLVM --> LLVMOptimize[LLVM Optimization] --> Assembly2[Assembly/Object Code]
    end

    Assembly1 --> Assembler
    Assembly2 --> Linker
    Assembler[System Assembler<br/>'as'] --> ObjectFile
    ObjectFile[Object File<br/>Hello.o] --> Linker

    subgraph LinkingPhase[Linking Phase - GHC Driver]
        Linker[GHC Driver] --> FindRTS[Find Runtime System<br/>libHSrts.a]
        Linker --> FindPackages[Find Package Dependencies<br/>base, ghc-prim, etc.]
        Linker --> BuildCommand[Construct Linker Command<br/>100+ arguments]
        FindRTS --> BuildCommand
        FindPackages --> BuildCommand
        BuildCommand --> InvokeLinker[Invoke System Linker<br/>ld/gold/lld]
    end

    InvokeLinker --> Executable([Executable Binary<br/>hello_success])

    style Start fill:#e1f5ff
    style Executable fill:#c8e6c9
    style Frontend fill:#fff9c4
    style MiddleEnd fill:#ffecb3
    style BackEnd fill:#ffe0b2
    style LinkingPhase fill:#ffccbc
```

## Linking Phase Detail

```mermaid
flowchart LR
    Start([Your Code<br/>Hello.o]) --> Driver

    subgraph GHCDriver[GHC Driver - The General Contractor]
        Driver[ghc command] --> ParseFlags[Parse Flags<br/>-threaded, -prof, etc.]
        ParseFlags --> QueryPkgDB[Query Package Database<br/>ghc-pkg]
        QueryPkgDB --> SelectRTS[Select RTS Variant<br/>vanilla/threaded/prof]
        SelectRTS --> ResolveDeps[Resolve Dependencies<br/>Build dependency graph]
        ResolveDeps --> TopSort[Topological Sort<br/>Determine link order]
        TopSort --> ConstructCmd[Construct Command<br/>140+ arguments]
    end

    ConstructCmd --> LinkerCmd

    subgraph LinkerCommand[Linker Command Components]
        LinkerCmd[Final Command] --> StartupCode[Startup Code<br/>crt0.o, etc.]
        LinkerCmd --> RTSLibs[RTS Libraries<br/>libHSrts.a]
        LinkerCmd --> BaseLib[base Library<br/>libHSbase-4.17.2.1.a]
        LinkerCmd --> PrimLibs[Primitive Libraries<br/>ghc-prim, integer-gmp]
        LinkerCmd --> BootLibs[Boot Libraries<br/>array, deepseq, etc.]
        LinkerCmd --> UserCode[Your Code<br/>Hello.o]
        LinkerCmd --> SysLibs[System Libraries<br/>-lgmp -ldl -lpthread]
    end

    LinkerCmd --> SystemLinker[System Linker<br/>ld/gold/lld]
    SystemLinker --> Executable([Executable<br/>hello_success])

    style Start fill:#e1f5ff
    style Executable fill:#c8e6c9
    style GHCDriver fill:#fff9c4
    style LinkerCommand fill:#ffecb3
```

## Why Naive Linking Fails

```mermaid
flowchart TD
    Start([Your Code<br/>Hello.o]) --> NaiveAttempt

    subgraph NaiveLinking[Naive Linking Attempt]
        NaiveAttempt[lld -o hello Hello.o<br/>-lc -lpthread -ldl] --> Missing
        Missing{Missing Components}
    end

    Missing -->|No RTS| Error1[❌ undefined reference:<br/>stg_ap_0_fast]
    Missing -->|No base| Error2[❌ undefined reference:<br/>base_GHCziIO_closure]
    Missing -->|No primitives| Error3[❌ undefined reference:<br/>ghczmprim_GHCziTypes]
    Missing -->|Wrong order| Error4[❌ undefined reference:<br/>Wrong symbol resolution]

    Error1 --> Failure([Link Failure])
    Error2 --> Failure
    Error3 --> Failure
    Error4 --> Failure

    Start --> CorrectWay

    subgraph GHCWay[Correct Way - GHC Orchestration]
        CorrectWay[ghc -o hello Hello.o] --> GHCDriver[GHC Driver]
        GHCDriver --> AddRTS[Add RTS:<br/>libHSrts.a]
        GHCDriver --> AddBase[Add base:<br/>libHSbase.a]
        GHCDriver --> AddPrim[Add primitives:<br/>libHSghc-prim.a]
        GHCDriver --> AddOrder[Correct Order:<br/>Topological sort]
        AddRTS --> BuildCmd[Construct 140+ arg<br/>linker command]
        AddBase --> BuildCmd
        AddPrim --> BuildCmd
        AddOrder --> BuildCmd
        BuildCmd --> CallLinker[Call lld with<br/>complete info]
    end

    CallLinker --> Success([✅ hello_success])

    style Start fill:#e1f5ff
    style Failure fill:#ffcdd2
    style Success fill:#c8e6c9
    style NaiveLinking fill:#fff9c4
    style GHCWay fill:#c8e6c9
```

## FFI Linking Comparison

```mermaid
flowchart TD
    subgraph FFIScenario[FFI Scenario: C calls Haskell]
        CCode[C Code<br/>main.c] --> CompileC[gcc -c main.c]
        HaskellCode[Haskell Library<br/>MyLib.hs] --> CompileHS[ghc -c MyLib.hs]
        CompileC --> CObject[main.o]
        CompileHS --> HSObject[MyLib.o]
        CompileHS --> Stub[MyLib_stub.h]
    end

    CObject --> LinkAttempt1
    HSObject --> LinkAttempt1

    subgraph WrongWay[❌ Wrong: Link with gcc/lld]
        LinkAttempt1[gcc -o program<br/>main.o MyLib.o] --> MissingRTS[Missing: RTS]
        LinkAttempt1 --> MissingBase[Missing: base libs]
        LinkAttempt1 --> MissingPrim[Missing: primitives]
        MissingRTS --> Fail1([Link Failure])
        MissingBase --> Fail1
        MissingPrim --> Fail1
    end

    CObject --> LinkAttempt2
    HSObject --> LinkAttempt2

    subgraph RightWay[✅ Correct: Link with GHC]
        LinkAttempt2[ghc -no-hs-main<br/>-o program<br/>main.o MyLib.o] --> GHCFinds[GHC Finds Everything]
        GHCFinds --> IncludeRTS[Include RTS]
        GHCFinds --> IncludeBase[Include base]
        GHCFinds --> IncludePrim[Include primitives]
        IncludeRTS --> Success[✅ program]
        IncludeBase --> Success
        IncludePrim --> Success
    end

    Success --> Runtime

    subgraph RuntimeExecution[Runtime: Manual RTS Control]
        Runtime[./program] --> Init[C: hs_init]
        Init --> CallHaskell[C: hs_fib]
        CallHaskell --> RTSActive[Haskell RTS Active:<br/>GC, Scheduler, Heap]
        RTSActive --> Return[Return to C]
        Return --> Exit[C: hs_exit]
    end

    style FFIScenario fill:#e1f5ff
    style WrongWay fill:#ffcdd2
    style RightWay fill:#c8e6c9
    style RuntimeExecution fill:#fff9c4
    style Fail1 fill:#f44336,color:#fff
    style Success fill:#4caf50,color:#fff
```

## Intermediate Representations Flow

```mermaid
flowchart TD
    Source[Haskell Source] --> HsSyn

    subgraph IRs[Intermediate Representations]
        HsSyn[HsSyn - Haskell Syntax Tree<br/>Level: High<br/>Typed: Yes<br/>Purpose: Preserve structure] --> Core
        Core[Core - Tiny Lambda Calculus<br/>Level: High<br/>Typed: Explicitly<br/>Purpose: Optimization] --> STG
        STG[STG - Spineless Tagless G-machine<br/>Level: Mid<br/>Typed: No<br/>Purpose: Lazy evaluation] --> Cmm
        Cmm[C-- - Portable Assembly<br/>Level: Low<br/>Typed: No<br/>Purpose: Code generation] --> Backend
    end

    Backend{Backend<br/>Choice} -->|NCG| NativeAsm[Native Assembly<br/>x86-64, ARM, etc.]
    Backend -->|LLVM| LLVMIR[LLVM IR]
    LLVMIR --> LLVMAsm[Assembly via LLVM]

    NativeAsm --> MachineCode[Machine Code]
    LLVMAsm --> MachineCode

    style Source fill:#e1f5ff
    style IRs fill:#fff9c4
    style MachineCode fill:#c8e6c9
```

## Render These Diagrams

To view these diagrams:

1. **GitHub**: These diagrams render automatically in GitHub's markdown viewer
2. **VS Code**: Install the "Markdown Preview Mermaid Support" extension
3. **Online**: Copy/paste to https://mermaid.live/
4. **CLI**: Use `mmdc` (mermaid-cli) to generate PNG/SVG:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   mmdc -i ghc-pipeline.md -o ghc-pipeline.png
   ```

## References

- [GHC Commentary: Compilation Pipeline](https://gitlab.haskell.org/ghc/ghc/-/wikis/commentary/compiler/pipeline)
- [The Architecture of Open Source Applications: GHC](https://aosabook.org/en/v2/ghc.html)
- [GHC User's Guide](https://downloads.haskell.org/ghc/latest/docs/users_guide/)

**Back to:** [Main README](../README.md) | [GHC Architecture](../docs/ghc-architecture.md)
