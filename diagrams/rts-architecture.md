# Haskell Runtime System (RTS) Architecture

This document provides visual diagrams of the Haskell Runtime System architecture and its components.

## RTS Components Overview

```mermaid
graph TD
    A[Haskell Runtime System] --> B[Memory Management]
    A --> C[Thread Scheduling]
    A --> D[Evaluation Engine]
    A --> E[FFI Support]
    A --> F[Profiling & Debugging]

    B --> B1[Garbage Collector]
    B --> B2[Heap Allocator]
    B --> B3[Memory Pools]

    C --> C1[Green Thread Scheduler]
    C --> C2[Work Stealing]
    C --> C3[Capabilities]

    D --> D1[STG Machine]
    D --> D2[Lazy Evaluation]
    D --> D3[Thunk Updates]

    E --> E1[C FFI]
    E --> E2[Safe/Unsafe Calls]
    E --> E3[Stable Pointers]

    F --> F1[Cost Centre Stacks]
    F --> F2[Event Logging]
    F --> F3[Heap Profiling]

    style A fill:#f9f,stroke:#90f,stroke-width:3px
    style B fill:#9cf,stroke:#06f
    style C fill:#fc9,stroke:#f60
    style D fill:#9f9,stroke:#090
    style E fill:#fcf,stroke:#c0c
    style F fill:#ff9,stroke:#cc0
```

---

## Memory Architecture

```mermaid
graph TB
    subgraph "Haskell Program Memory"
        A[Operating System Memory]

        subgraph "RTS Managed Heap"
            B[Generation 0<br/>Young Objects<br/>Nursery]
            C[Generation 1<br/>Older Objects]
            D[Large Object Pool<br/>Objects > 4KB]
        end

        subgraph "RTS Stacks"
            E[Main Thread Stack]
            F[Haskell Thread 1 Stack]
            G[Haskell Thread 2 Stack]
            H[... more stacks]
        end

        subgraph "Static Data"
            I[Info Tables]
            J[Static Closures]
            K[CAFs<br/>Constant Applicative Forms]
        end

        L[RTS Code Segment]
        M[Your Haskell Code]
    end

    A --> B
    A --> C
    A --> D
    A --> E
    A --> F
    A --> G
    A --> H
    A --> I
    A --> J
    A --> K
    A --> L
    A --> M

    style B fill:#9f9,stroke:#090
    style C fill:#fc9,stroke:#f60
    style D fill:#f99,stroke:#f00
    style L fill:#9cf,stroke:#06f
    style M fill:#fcf,stroke:#c0c
```

---

## Garbage Collector Architecture

```mermaid
graph LR
    subgraph "Generational GC"
        A[Nursery<br/>Gen 0]
        B[Old Generation<br/>Gen 1]

        A -->|Minor GC<br/>Frequent| C[Copy survivors]
        C -->|Promote| B

        B -->|Major GC<br/>Rare| D[Mark & Sweep<br/>Compact]
        D -->|Reclaim| B
    end

    subgraph "GC Algorithms"
        E[Copying GC<br/>for Gen 0]
        F[Mark-Compact<br/>for Gen 1]
        G[Parallel GC<br/>Multi-core]
    end

    style A fill:#9f9,stroke:#090
    style B fill:#fc9,stroke:#f60
    style E fill:#9cf,stroke:#06f
    style F fill:#fcf,stroke:#c0c
    style G fill:#ff9,stroke:#cc0
```

### GC Statistics

```mermaid
graph TD
    A[Program Execution] -->|Allocation| B[Fill Nursery]
    B -->|Nursery Full| C{Minor GC}
    C -->|Live Objects| D[Copy to Gen 1]
    C -->|Dead Objects| E[Reclaim]

    D -->|Gen 1 Full| F{Major GC}
    F -->|Mark Live| G[Compact Gen 1]
    F -->|Sweep Dead| E

    G --> H[Continue Execution]
    E --> H

    style C fill:#9f9,stroke:#090
    style F fill:#f99,stroke:#f00
    style H fill:#9cf,stroke:#06f
```

---

## Thread Scheduler Architecture

```mermaid
graph TB
    subgraph "Multi-Core System"
        OS1[OS Thread 1]
        OS2[OS Thread 2]
        OS3[OS Thread 3]
        OS4[OS Thread 4]
    end

    subgraph "Haskell Runtime System"
        CAP1[Capability 1]
        CAP2[Capability 2]
        CAP3[Capability 3]
        CAP4[Capability 4]

        GRQ[Global Run Queue<br/>Shared Thread Pool]
    end

    subgraph "Haskell Threads Green Threads"
        T1[Thread 1]
        T2[Thread 2]
        T3[Thread 3]
        T4[Thread 4]
        T5[Thread 5]
        T6[Thread 6]
        TN[... thousands more]
    end

    OS1 --> CAP1
    OS2 --> CAP2
    OS3 --> CAP3
    OS4 --> CAP4

    CAP1 --> T1
    CAP1 --> T2
    CAP2 --> T3
    CAP3 --> T4
    CAP3 --> T5
    CAP4 --> T6

    T1 -.Work Stealing.-> GRQ
    T3 -.Work Stealing.-> GRQ
    GRQ -.-> TN

    style CAP1 fill:#9f9,stroke:#090
    style CAP2 fill:#9f9,stroke:#090
    style CAP3 fill:#9f9,stroke:#090
    style CAP4 fill:#9f9,stroke:#090
    style GRQ fill:#fc9,stroke:#f60
```

### Thread States

```mermaid
stateDiagram-v2
    [*] --> Created
    Created --> Runnable: forkIO
    Runnable --> Running: scheduled
    Running --> Runnable: preempted/yield
    Running --> Blocked: takeMVar/IO
    Blocked --> Runnable: MVar ready/IO complete
    Running --> Finished: thread exits
    Finished --> [*]

    note right of Running
        Only one thread runs
        per Capability
    end note

    note right of Blocked
        Does not consume
        CPU time
    end note
```

---

## Lazy Evaluation: Thunk Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Thunk: Create suspended computation
    Thunk --> BlackHole: Start evaluation
    BlackHole --> Value: Evaluation complete
    BlackHole --> BlockedThread: Another thread tries to evaluate
    BlockedThread --> Value: First thread finishes
    Value --> [*]: Memoized, never recomputed

    note right of Thunk
        Not yet evaluated
        Pointer to code + environment
    end note

    note right of BlackHole
        Currently being evaluated
        Prevents infinite loops
        Allows parallel GC
    end note

    note right of Value
        Fully evaluated
        Thunk overwritten in-place
    end note
```

### Closure Representation

```mermaid
graph LR
    subgraph "Closure in Memory"
        A[Info Table Pointer]
        B[Payload Field 1]
        C[Payload Field 2]
        D[...]
    end

    A --> E[Info Table]

    subgraph "Info Table Contents"
        E --> F[Entry Code<br/>How to evaluate]
        E --> G[Layout Info<br/>Which fields are pointers]
        E --> H[Type Info<br/>Constructor tag]
        E --> I[SRT<br/>Static Reference Table]
    end

    style A fill:#9cf,stroke:#06f
    style E fill:#fc9,stroke:#f60
    style F fill:#9f9,stroke:#090
```

---

## FFI Integration

```mermaid
graph TB
    subgraph "Haskell Code"
        A[Haskell Function]
    end

    subgraph "RTS FFI Layer"
        B{FFI Call}
        C[Safe FFI<br/>Can callback]
        D[Unsafe FFI<br/>No callback]
        E[Save RTS State]
        F[Restore RTS State]
    end

    subgraph "C Code"
        G[C Function]
        H[C Callback to Haskell]
    end

    A --> B
    B -->|foreign import safe| C
    B -->|foreign import unsafe| D

    C --> E
    E --> G
    G --> H
    H --> F
    F --> A

    D --> G
    G -.No callbacks.-> A

    style C fill:#9f9,stroke:#090
    style D fill:#fc9,stroke:#f60
    style E fill:#9cf,stroke:#06f
    style F fill:#9cf,stroke:#06f
```

### Foreign Export Flow

```mermaid
sequenceDiagram
    participant C as C Code
    participant Init as hs_init()
    participant RTS as Haskell RTS
    participant HS as Haskell Function
    participant Exit as hs_exit()

    C->>Init: Initialize RTS
    Init->>RTS: Start GC, Scheduler, Heap
    RTS-->>Init: Ready
    Init-->>C: RTS Started

    C->>HS: Call Haskell function
    HS->>RTS: Allocate, evaluate thunks
    RTS-->>HS: Provide GC, threads
    HS-->>C: Return result

    C->>HS: Another call
    HS->>RTS: Reuse existing RTS
    HS-->>C: Return result

    C->>Exit: Shutdown RTS
    Exit->>RTS: Wait for threads, flush I/O
    RTS->>RTS: Run finalizers
    RTS-->>Exit: Cleanup complete
    Exit-->>C: Done
```

---

## Capability Architecture (Parallelism)

```mermaid
graph TB
    subgraph "Single Capability Default"
        A1[1 OS Thread] --> B1[1 Capability]
        B1 --> C1[Run Queue]
        C1 --> D1[T1]
        C1 --> D2[T2]
        C1 --> D3[T3]
    end

    subgraph "Multi-Capability -N4"
        E1[OS Thread 1] --> F1[Cap 1]
        E2[OS Thread 2] --> F2[Cap 2]
        E3[OS Thread 3] --> F3[Cap 3]
        E4[OS Thread 4] --> F4[Cap 4]

        F1 --> G1[Local Queue]
        F2 --> G2[Local Queue]
        F3 --> G3[Local Queue]
        F4 --> G4[Local Queue]

        G1 --> H1[T1, T2]
        G2 --> H2[T3, T4]
        G3 --> H3[T5, T6]
        G4 --> H4[T7, T8]

        I[Global Queue<br/>Overflow & Work Stealing]
        G1 -.-> I
        G2 -.-> I
        I -.-> G3
        I -.-> G4
    end

    style A1 fill:#fc9,stroke:#f60
    style F1 fill:#9f9,stroke:#090
    style F2 fill:#9f9,stroke:#090
    style F3 fill:#9f9,stroke:#090
    style F4 fill:#9f9,stroke:#090
    style I fill:#9cf,stroke:#06f
```

---

## RTS Variants

```mermaid
graph LR
    A[GHC Compiler] --> B{Which RTS?}

    B -->|Default| C[libHSrts.a<br/>Single-threaded]
    B -->|-threaded| D[libHSrts_thr.a<br/>Multi-core]
    B -->|-prof| E[libHSrts_p.a<br/>Profiling]
    B -->|-debug| F[libHSrts_debug.a<br/>Debugging]
    B -->|-eventlog| G[libHSrts_l.a<br/>Event Log]
    B -->|-dynamic| H[libHSrts.so<br/>Shared Library]

    C --> I[Link appropriate variant]
    D --> I
    E --> I
    F --> I
    G --> I
    H --> I

    I --> J[Executable]

    style B fill:#fc9,stroke:#f60
    style J fill:#9f9,stroke:#090
```

### RTS Feature Matrix

| Feature | Vanilla | Threaded | Profiling | Debug |
|---------|---------|----------|-----------|-------|
| Single-threaded | ✅ | ❌ | ✅ | ✅ |
| Multi-core (`-N`) | ❌ | ✅ | ❌ | ✅ |
| Profiling data | ❌ | ❌ | ✅ | ✅ |
| Debug output | ❌ | ❌ | ❌ | ✅ |
| Smallest size | ✅ | ❌ | ❌ | ❌ |
| Best performance | ✅ | ✅ | ❌ | ❌ |

---

## Stack Architecture

```mermaid
graph TB
    subgraph "Haskell Thread Stack"
        A[Stack Pointer SP] --> B[Top Frame]
        B --> C[Return Address]
        B --> D[Info Table Ptr]
        B --> E[Local Variables]
        B --> F[Live Pointers<br/>for GC]

        B --> G[Update Frame]
        G --> H[Thunk to Update]
        G --> I[Return Continuation]

        G --> J[Function Call Frame]
        J --> K[Arguments]
        J --> L[Return Info]

        J --> M[Stack Bottom]
    end

    style A fill:#f99,stroke:#f00
    style D fill:#9cf,stroke:#06f
    style F fill:#9f9,stroke:#090
    style G fill:#fc9,stroke:#f60
```

**Key Features**:
- **Dynamic sizing**: Stacks start small (~1 KB) and grow as needed
- **GC awareness**: Every frame has an info table telling GC which slots are pointers
- **Update frames**: Ensure lazy values are only computed once
- **Cheap thread creation**: Small initial stack enables millions of threads

---

## Profiling Architecture

```mermaid
graph TB
    subgraph "Cost Centre Stack Profiling"
        A[Source Code] --> B[Cost Centres<br/>Annotated Functions]
        B --> C[Runtime Tracking]
        C --> D[Time Spent]
        C --> E[Memory Allocated]
        C --> F[Call Graph]

        D --> G[Profiling Report<br/>.prof file]
        E --> G
        F --> G
    end

    subgraph "Heap Profiling"
        H[Running Program] --> I[Heap Snapshots]
        I --> J[Object Types]
        I --> K[Cost Centres]
        I --> L[Modules]

        J --> M[Heap Profile<br/>.hp file]
        K --> M
        L --> M

        M --> N[Visualization<br/>hp2ps]
    end

    subgraph "Event Logging"
        O[Program Events] --> P[GC Events]
        O --> Q[Thread Events]
        O --> R[User Events]

        P --> S[Eventlog<br/>.eventlog]
        Q --> S
        R --> S

        S --> T[ThreadScope<br/>Visualization]
    end

    style G fill:#9f9,stroke:#090
    style M fill:#fc9,stroke:#f60
    style S fill:#9cf,stroke:#06f
```

---

## RTS Initialization Sequence

```mermaid
sequenceDiagram
    participant Main as main()
    participant Init as RTS Init
    participant GC as Garbage Collector
    participant Sched as Scheduler
    participant Heap as Heap Manager
    participant Prog as Haskell Main

    Main->>Init: Program starts
    Init->>Init: Parse RTS options (+RTS -N4 etc.)
    Init->>Heap: Initialize heap (Gen 0, Gen 1)
    Heap-->>Init: Heap ready

    Init->>GC: Initialize GC structures
    GC-->>Init: GC ready

    Init->>Sched: Initialize scheduler & capabilities
    Sched->>Sched: Create N capabilities
    Sched-->>Init: Scheduler ready

    Init->>Prog: Run Haskell main

    loop Program Execution
        Prog->>Heap: Allocate
        Heap-->>GC: Nursery full
        GC->>GC: Minor GC
        GC-->>Prog: Continue

        Prog->>Sched: forkIO
        Sched->>Sched: Create green thread
        Sched-->>Prog: Continue
    end

    Prog->>Init: Exit
    Init->>Sched: Shutdown (wait for threads)
    Init->>GC: Final GC
    Init->>Heap: Free all memory
    Init-->>Main: Exit with code
```

---

## Back to Main Documentation

- [Main README](../README.md)
- [RTS Explained](../docs/rts-explained.md)
- [GHC Architecture](../docs/ghc-architecture.md)
- [Linking Process](../docs/linking-process.md)
