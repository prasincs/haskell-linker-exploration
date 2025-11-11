# Chapter 12: Decision Framework

## Choosing the Right Approach

This chapter provides a **decision framework** for choosing between FFI, gRPC, and other integration approaches.

**No one-size-fits-all solution**. The right choice depends on your specific requirements.

## Decision Matrix

### Quick Reference

| Requirement | FFI | gRPC | Hybrid |
|-------------|-----|------|--------|
| **Latency < 1μs** | ✅ | ❌ | ⚠️ |
| **Latency < 1ms** | ✅ | ✅ | ✅ |
| **Horizontal scaling** | ❌ | ✅ | ✅ |
| **Independent deployment** | ❌ | ✅ | ✅ |
| **Multi-language** | ⚠️ | ✅ | ✅ |
| **Single binary** | ✅ | ❌ | ⚠️ |
| **Simplicity** | ⚠️ | ⚠️ | ❌ |

### Detailed Comparison

#### Performance

| Metric | FFI | gRPC |
|--------|-----|------|
| **Latency** | 50ns - 5μs | 100μs - 10ms |
| **Throughput (per instance)** | Millions/sec | Thousands/sec |
| **Memory overhead** | ~48 bytes/call | ~8 KB/call |
| **CPU overhead** | Minimal | Serialization + network |

**Winner**: **FFI** for raw performance

#### Scalability

| Aspect | FFI | gRPC |
|--------|-----|------|
| **Vertical scaling** | ✅ Excellent | ✅ Good |
| **Horizontal scaling** | ❌ Not possible | ✅ Excellent |
| **Load balancing** | ❌ N/A | ✅ Built-in |
| **Geographic distribution** | ❌ Not possible | ✅ Supported |

**Winner**: **gRPC** for scalability

#### Development & Operations

| Aspect | FFI | gRPC |
|--------|-----|------|
| **Build complexity** | ⚠️ High | ✅ Low |
| **Deployment** | ✅ Single binary | ⚠️ Multiple services |
| **Debugging** | ⚠️ Difficult | ✅ Standard tools |
| **Monitoring** | ⚠️ Custom | ✅ Standard metrics |
| **Team independence** | ❌ Tightly coupled | ✅ Independent |

**Winner**: **gRPC** for operations

## When FFI Makes Sense

### Use Case 1: High-Frequency Trading

**Requirements**:
- Sub-microsecond latency
- Millions of calls per second
- Single machine deployment
- Deterministic performance

**Why FFI**:
- ✅ 500ns latency (gRPC: 100μs = 200x slower)
- ✅ No network overhead
- ✅ Predictable performance
- ✅ Single binary (easier to certify)

**Architecture**:

```
┌─────────────────────────────┐
│    Trading Engine           │
│  ┌──────────────────────┐  │
│  │  Haskell Core Logic  │  │
│  └──────────┬───────────┘  │
│             │ FFI (unsafe) │
│  ┌──────────▼───────────┐  │
│  │  C Market Data Feed  │  │
│  └──────────────────────┘  │
└─────────────────────────────┘
```

### Use Case 2: Game Engine

**Requirements**:
- Low latency (< 16ms per frame)
- Calling C libraries (physics, graphics)
- Single deployment artifact
- No network dependency

**Why FFI**:
- ✅ Direct access to C libraries (OpenGL, Vulkan)
- ✅ No network round-trip delay
- ✅ Predictable frame timing
- ✅ Single executable

**Architecture**:

```
┌─────────────────────────────┐
│      Game Engine            │
│  ┌──────────────────────┐  │
│  │ Haskell Game Logic   │  │
│  └──────────┬───────────┘  │
│             │ FFI          │
│  ┌──────────▼───────────┐  │
│  │ C Graphics/Physics   │  │
│  └──────────────────────┘  │
└─────────────────────────────┘
```

### Use Case 3: Embedded System

**Requirements**:
- Resource-constrained (limited memory)
- Real-time requirements
- No network connectivity
- Single binary deployment

**Why FFI**:
- ✅ Minimal overhead
- ✅ No network stack needed
- ✅ Smaller memory footprint
- ✅ Deterministic timing

## When gRPC Makes Sense

### Use Case 1: Microservices Architecture

**Requirements**:
- Independent scaling of components
- Multiple teams/languages
- Geographic distribution
- Gradual migration from monolith

**Why gRPC**:
- ✅ Services scale independently
- ✅ Teams can deploy independently
- ✅ Language flexibility (Python ML, Go services, Haskell core)
- ✅ Can replace components without rebuild

**Architecture**:

```
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ Haskell Core  │────▶│  Python ML    │────▶│   Go API      │
│   Service     │ gRPC│   Service     │ gRPC│  Gateway      │
└───────────────┘     └───────────────┘     └───────────────┘
```

### Use Case 2: ML Inference Service

**Requirements**:
- Independent scaling of model servers
- Model updates without downtime
- Multiple model versions
- ~10ms latency acceptable

**Why gRPC**:
- ✅ Scale models independently
- ✅ A/B testing (route traffic to different versions)
- ✅ Blue-green deployment
- ✅ gRPC overhead (2ms) is small vs model time (10ms)

**Architecture**:

```
┌───────────────┐
│  Haskell API  │
└───────┬───────┘
        │ gRPC load balanced
    ┌───┼────┬────┬────┐
    ▼   ▼    ▼    ▼    ▼
  [Model v1.0] [Model v1.1] [Model v1.2]
  (Python servers, independently scaled)
```

### Use Case 3: Financial Settlement System

**Requirements**:
- Audit logging
- Distributed tracing
- Multiple regulatory domains
- Correctness > performance

**Why gRPC**:
- ✅ Built-in observability (tracing, metrics)
- ✅ Structured logging at service boundaries
- ✅ Can isolate regulatory components
- ✅ Easier to audit (network logs)

## Hybrid Approaches

Sometimes the best solution is **both**!

### Pattern 1: FFI for Hot Path, gRPC for Everything Else

```
┌─────────────────────────────┐
│    Core Trading Service     │
│  ┌──────────────────────┐  │
│  │  Haskell Order Book  │  │
│  └──────────┬───────────┘  │
│             │ FFI (hot path)
│  ┌──────────▼───────────┐  │
│  │  C Market Data       │  │
│  └──────────────────────┘  │
└────────────┬────────────────┘
             │ gRPC (cold path)
             ▼
┌─────────────────────────────┐
│   Reporting/Analytics       │
│   (Python/other languages)  │
└─────────────────────────────┘
```

**Hot path** (FFI):
- Order matching: 500ns
- Market data processing: 1μs

**Cold path** (gRPC):
- Reporting: 50ms acceptable
- Analytics: seconds acceptable

### Pattern 2: FFI Within Service, gRPC Between Services

```
Service A (Haskell + C via FFI)
┌─────────────────────────────┐
│ ┌─────────┐    ┌─────────┐ │
│ │Haskell  │◄──▶│    C    │ │
│ └─────────┘FFI └─────────┘ │
└────────────┬────────────────┘
             │ gRPC
             ▼
Service B (Python + C++ via FFI)
┌─────────────────────────────┐
│ ┌─────────┐    ┌─────────┐ │
│ │ Python  │◄──▶│   C++   │ │
│ └─────────┘FFI └─────────┘ │
└─────────────────────────────┘
```

**Within service**: FFI for tight integration
**Between services**: gRPC for flexibility

## Decision Tree

```
Start: Need to integrate Haskell with other code

├─ Latency requirement < 10μs?
│  ├─ Yes → Use FFI
│  └─ No → Continue

├─ Need horizontal scaling?
│  ├─ Yes → Use gRPC
│  └─ No → Continue

├─ Multiple teams/languages?
│  ├─ Yes → Use gRPC
│  └─ No → Continue

├─ Network deployment acceptable?
│  ├─ Yes → Use gRPC
│  └─ No → Use FFI

├─ Build complexity manageable?
│  ├─ Yes → Use FFI
│  └─ No → Use gRPC

└─ Default → Start with gRPC (easier to change later)
```

## Migration Strategies

### From Monolith to Microservices

**Phase 1**: Identify service boundaries

```
Monolith (Haskell + C via FFI)
└─ Core business logic
└─ Reporting
└─ Analytics
└─ User management
```

**Phase 2**: Extract non-critical services

```
Core Monolith (FFI)
└─ Core business logic

New Services (gRPC)
└─ Reporting service
└─ Analytics service
└─ User management service
```

**Phase 3**: Extract critical services (if needed)

```
All Services (gRPC)
└─ Core service
└─ Reporting service
└─ Analytics service
└─ User management service
```

### From gRPC to FFI (Performance Optimization)

**Identify hot path**:

```bash
# Profile gRPC calls
grpc_cli call localhost:50051 Profile

# Results:
# - calculateRisk: 1M calls/sec, 150μs avg
# - generateReport: 10 calls/sec, 2s avg
```

**Optimize hot path only**:

```
Before (all gRPC):
  calculateRisk: 150μs per call

After (FFI for hot path):
  calculateRisk: 2μs per call (75x faster!)
  generateReport: 2s per call (unchanged, gRPC)
```

## Further Reading

- **Best Practices**: [→ Chapter 13](./13-best-practices.md)
- **Benchmarking**: [→ Chapter 11](../part-4-interactive/11-benchmarking.md)
- **PoC Comparison**: [→ PoC 2](../part-2-proofs/04-poc2-ffi-integration.md) vs [PoC 3](../part-2-proofs/05-poc3-grpc-alternative.md)

---

## Summary

Key takeaways:

1. ✅ **No one-size-fits-all** solution
2. ✅ **FFI for performance**, gRPC for scalability
3. ✅ **Hybrid approaches** often work best
4. ✅ **Start with gRPC** (easier to optimize later)
5. ✅ **Profile before optimizing** (measure, don't guess)

**Next**: [Best Practices →](./13-best-practices.md)

---

## Quick Navigation

- **Previous**: [← Benchmarking](../part-4-interactive/11-benchmarking.md)
- **Next**: [Best Practices →](./13-best-practices.md)
- **Related**: [PoC 3 →](../part-2-proofs/05-poc3-grpc-alternative.md)
