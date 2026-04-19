# Idea 20: Behavioral Contract Snapshots — API Behavioral Assertions AI Tools Must Preserve

## One-line summary
Capture API behavioral contracts as executable snapshots that AI tools must verify still pass before submitting changes to service boundaries.

## Tags
multi-language, shared-protocol, density-research, jenkins, cross-tool-routing

## Problem
AI tools modify service APIs — Go handlers, Python endpoints, Node.js routes, C++/C library interfaces — without a clear understanding of the behavioral contracts those APIs uphold. A contract isn't just a type signature; it's "this endpoint returns results sorted by timestamp", "this allocator never returns more than maxBurst bytes", "this config loader falls back to defaults on missing keys." These contracts are documented (if at all) in prose comments or Slack threads, invisible to AI tools.

When a Claude Code refactor changes the allocator's return behavior from "sorted by arena ID" to "unsorted" (because sorting wasn't in the type signature), callers that depend on sorted output break silently — tests pass because they don't check sort order, and the regression surfaces in production. The type system catches structural breaks; nothing catches behavioral breaks.

## Proposal
Introduce `.contracts/` — a directory of executable behavioral contract snapshots for service and library APIs:

1. **Contract format:** Each contract is a small, executable test-like file (`.contracts/tests/<component>-<contract>.{go,py,js,cc}`) that asserts a specific behavioral property of an API. Unlike unit tests, contracts test *invariants* (properties that must hold regardless of implementation), not *specific implementations*.
2. **Contract registry:** `.contracts/registry.yaml` maps contracts to the files/functions they protect. Each entry links a contract to the source files whose modification should trigger re-verification of the contract.
3. **AI enforcement:** All four tool rule files include: "Before modifying a function listed in `.contracts/registry.yaml`, read and understand its behavioral contracts. After modification, verify all linked contracts pass." A Jenkins stage `contract-verify` runs contracts for any modified registered function.
4. **Contract discovery:** AI tools are tasked with discovering undocumented behavioral contracts by analyzing test patterns, code comments, and caller expectations.

## Cross-AI-tool design

### Claude Code
- **Role:** Contract discoverer and author. Claude Code's deep analysis capability makes it ideal for identifying undocumented behavioral contracts: reading callers, analyzing test assertions, and inferring invariants. A custom command (`/.claude/commands/discover-contracts.md`) scans a function and proposes behavioral contracts. Also the primary tool for writing complex multi-condition contracts.
- **Shared contract it reads/writes:** Reads/writes `.contracts/registry.yaml` and `.contracts/tests/`. Reads `CLAUDE.md` contract rules.
- **Fallback if unavailable:** Developer writes contracts manually. `scripts/scaffold-contract.sh` provides a template.

### GitHub Copilot
- **Role:** Contract-aware code modification. `.github/copilot-instructions.md` includes: "Before modifying a registered function, check `.contracts/registry.yaml` and verify contracts pass after your change." Copilot Coding Agent PRs that modify registered functions must include contract verification results.
- **Shared contract it reads/writes:** Reads `.contracts/registry.yaml`. Runs contract tests as part of PR verification.
- **Fallback if unavailable:** Jenkins `contract-verify` catches violations regardless.

### Codex
- **Role:** Contract verifier and regression sentinel. `AGENTS.md` instructs Codex to run `scripts/verify-contracts.sh --changed` before submitting any task that modifies registered functions. Codex's deterministic execution makes it the most reliable pre-submit contract checker.
- **Shared contract it reads/writes:** Reads `.contracts/registry.yaml` and `AGENTS.md`. Runs contract tests.
- **Fallback if unavailable:** Jenkins is the definitive verifier.

### Cursor
- **Role:** IDE contract display. `.cursor/rules/contracts.mdc` instructs Cursor to display linked contracts when the developer opens a registered function. A custom command `/contracts` shows all behavioral contracts for the current function, making the invisible behavioral expectations visible during editing.
- **Shared contract it reads/writes:** Reads `.contracts/registry.yaml`. Displays contracts in IDE.
- **Fallback if unavailable:** `scripts/show-contracts.sh <function>` from the terminal.

## Languages affected
All five: Go (handler behavior, allocator invariants), C++ (memory allocator contracts, performance invariants), Python (data pipeline ordering, fallback behavior), Node.js (API response shape, error handling patterns), C (buffer handling, null termination guarantees). Contracts are written in each function's native language for maximum fidelity. The registry and Jenkins stage are language-agnostic.

## Infra impact
- **Jenkins:** New stage `contract-verify` in the shared library. Runs contract tests for modified registered functions. Blocking on contract failure. Adds 10-30 seconds per PR (only runs affected contracts, not all). 
- **Kubernetes:** No runtime impact. Contracts may test behaviors that manifest differently under K8s resource constraints (e.g., allocator behavior under memory pressure), but are tested in CI.
- **Density/perf research:** Directly relevant — allocator behavioral contracts (e.g., "never allocate more than maxBurst", "arena reuse rate ≥ 95%") encode density invariants that must survive refactoring.

## Concrete artifact

`.contracts/registry.yaml`:
```yaml
contracts:
  - function: AllocBurstPool
    file: services/shard/alloc.go
    language: go
    contracts:
      - name: "burst-pool-max-alloc"
        test: .contracts/tests/shard-alloc-max-burst.go
        description: "AllocBurstPool never allocates more than burstSize bytes in a single call"
      - name: "burst-pool-arena-reuse"
        test: .contracts/tests/shard-alloc-arena-reuse.go
        description: "After Free, subsequent Alloc reuses the same arena (no new mmap)"

  - function: read_counters
    file: tools/metrics/collector.py
    language: python
    contracts:
      - name: "counters-sorted-by-ts"
        test: .contracts/tests/metrics-counters-sorted.py
        description: "read_counters returns counters sorted by timestamp ascending"
      - name: "counters-fallback-empty"
        test: .contracts/tests/metrics-counters-fallback.py
        description: "read_counters returns empty list (not error) when no data available"
```

Contract test example (`.contracts/tests/shard-alloc-max-burst.go`):
```go
//go:build contract
package contracts

import (
    "testing"
    "services/shard"
)

func TestAllocBurstPool_MaxAlloc(t *testing.T) {
    // Behavioral contract: AllocBurstPool never allocates more than burstSize
    arena := setupTestArena(t)
    burstSize := 2 * 1024 * 1024
    pool, err := shard.AllocBurstPool(arena, burstSize)
    if err != nil { t.Fatal(err) }
    if pool.AllocatedBytes() > burstSize {
        t.Errorf("contract violated: allocated %d > burstSize %d", pool.AllocatedBytes(), burstSize)
    }
}
```

Jenkins stage:
```groovy
stage('contract-verify') {
  steps {
    script {
      def broken = contractVerify(registry: '.contracts/registry.yaml', diffAgainst: 'origin/main')
      if (broken) { error("Behavioral contract violated: ${broken.contracts.join(', ')}") }
    }
  }
}
```

## Success metric
- ≥30 behavioral contracts covering density-critical functions within 8 weeks.
- Zero behavioral regressions reach production on contracted functions (down from ~1/month estimated).
- AI tools discover at least 10 undocumented behavioral contracts in the first quarter, surfacing previously-invisible invariants.
- Contract verification adds <30 seconds to CI for most PRs.

## Risks & failure modes
- **Contract maintenance:** Contracts may become stale as behavior intentionally changes. Mitigated by requiring contract updates alongside intentional behavior changes (like updating test expectations).
- **Over-specification:** Contracts that are too specific lock in implementation details, not just behavior. Mitigated by reviewing contracts for "invariant vs. implementation detail" during authoring.
- **Discovery false positives:** AI tools may propose contracts for incidental behavior (not intentional invariants). Mitigated by human review of proposed contracts.
- **Cross-language contract gaps:** Some behaviors span languages (Go caller assumes C++ allocator behavior). Mitigated by supporting cross-language contracts that test the call chain.

## Originality statement

**Versus existing ideas in this repo:**
Idea 5 (FFI Boundary Contracts) tests type-safety at cross-language call sites; this idea tests *behavioral invariants* at API boundaries — a different layer (type vs. behavior). Overlap: ~25% (both use contract tests at boundaries). Idea 7 (Memory Budget Annotations) specifies numeric budgets; this idea specifies behavioral properties. Overlap: ~15%.

**Versus common industry proposals:**
Contract testing (Pact, etc.) exists for inter-service API schemas; property-based testing (Hypothesis, QuickCheck) tests random inputs. This idea applies *behavioral invariant contracts* specifically to functions that AI tools modify, with a registry linking functions to contracts and a CI verification gate. The AI-tool-aware aspect (tools must read contracts before modifying, tools discover new contracts) is the novel surface. It satisfies heuristics #1 (new inter-tool interface: the contract registry), #3 (density-research coupling: allocator behavioral invariants), #5 (language-stack specificity: per-language contract tests), and #6 (failure mode as feature: behavioral breaks become CI-detectable).
