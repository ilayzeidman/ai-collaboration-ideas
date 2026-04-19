# Idea 12: Cross-Language Refactor Choreographer — Coordinated Multi-Service Rename Manifests

## One-line summary
Use a shared rename manifest to coordinate symbol renames across Go/Python/Node/C++/C services so no AI tool renames one side without the other.

## Tags
multi-language, anti-coordination, shared-protocol, cross-tool-routing

## Problem
Cross-language renames are the team's most error-prone refactor class. Renaming a Go service's RPC method requires updating the Python client, the Node.js BFF consumer, the C++ performance test, and the Helm chart's health check path — all in one atomic PR. When an AI tool renames the Go side, it often misses the Python client or the Helm health check. Different developers using different tools on different parts of the stack create partial renames that compile individually but break integration.

Today, cross-language renames are coordinated by tribal knowledge ("remember to update the Python client when you rename a Go RPC") and manual checklists. AI tools have no way to discover that a symbol exists in multiple languages under different names that must be renamed in lockstep.

## Proposal
Introduce `.refactor-manifest/renames.yaml` — a structured file declaring multi-language symbol relationships that must be renamed together. Each entry maps a "concept" to its manifestations across languages:

1. **Concept:** The logical name (e.g., "shard-allocate-burst").
2. **Manifestations:** For each language, the file path, symbol name, and type (function, struct, config key, URL path, etc.).
3. **Rename constraints:** Rules like "all manifestations must be renamed in the same PR" or "Python and Go must match exactly, Helm may differ."

When an AI tool proposes a rename on any manifestation, the tool's rule file instructs it to consult the manifest and include all linked manifestations in the rename. A Jenkins stage `rename-consistency-check` verifies that if any manifestation of a concept was renamed in the PR, all other manifestations were also renamed (or explicitly waived).

A discovery script (`scripts/discover-rename-links.sh`) periodically scans for cross-language references (import paths, API endpoints, config keys) and proposes new manifest entries.

## Cross-AI-tool design

### Claude Code
- **Role:** Manifest curator and complex rename executor. Claude Code's multi-file agentic capability makes it ideal for executing renames that span 5+ files across languages. A custom command (`/.claude/commands/cross-rename.md`) takes a concept name and new name, reads the manifest, and applies the rename to all manifestations. Also the primary tool for maintaining the manifest itself.
- **Shared contract it reads/writes:** Reads/writes `.refactor-manifest/renames.yaml`. Reads `CLAUDE.md` rename rules.
- **Fallback if unavailable:** Developer renames manually following the manifest as a checklist. Jenkins catches missed manifestations.

### GitHub Copilot
- **Role:** Rename-aware inline suggestions. `.github/copilot-instructions.md` includes: "Before completing a rename, check `.refactor-manifest/renames.yaml` for linked manifestations." Copilot Coding Agent PRs that rename a manifest-linked symbol must include all linked renames. `.github/prompts/cross-rename.prompt.md` provides a structured rename prompt.
- **Shared contract it reads/writes:** Reads `.refactor-manifest/renames.yaml`. Writes renames across linked files in PRs.
- **Fallback if unavailable:** Jenkins consistency check catches incomplete renames.

### Codex
- **Role:** Rename verification and pre-submit check. `AGENTS.md` instructs Codex to run `scripts/check-rename-consistency.sh` before submitting any task that renames symbols. If the task affects a manifest-linked concept, Codex must rename all manifestations.
- **Shared contract it reads/writes:** Reads `.refactor-manifest/renames.yaml` and `AGENTS.md` directive. Runs consistency check.
- **Fallback if unavailable:** Jenkins is the gate.

### Cursor
- **Role:** IDE rename amplifier. `.cursor/rules/rename-manifest.mdc` instructs Cursor to check the manifest when the developer uses rename refactoring. A custom command `/cross-rename <concept> <new-name>` triggers renames across all manifestations from the IDE. Cursor's IDE integration is ideal for "rename here → auto-rename everywhere" workflows.
- **Shared contract it reads/writes:** Reads `.refactor-manifest/renames.yaml`. Writes renames across files in Agent mode.
- **Fallback if unavailable:** `scripts/apply-cross-rename.sh <concept> <new-name>` from the terminal.

## Languages affected
Maximally multi-language — this idea exists precisely because the team uses five languages. The manifest links Go functions to Python clients, Node.js consumers, C++ test utilities, C driver interfaces, YAML config keys, and Groovy Jenkinsfile references. Each language has different rename mechanics (Go: gorename, Python: rope, Node: IDE refactor, C++: clang-rename, C: manual) but the manifest coordinates them through a shared semantic layer.

## Infra impact
- **Jenkins:** New stage `rename-consistency-check` in the shared library. Runs on PRs that touch files listed in the manifest. Blocking on incomplete renames (unless explicitly waived). Fast (<10s, just a manifest lookup + diff check).
- **Kubernetes:** No runtime impact. Helm chart references are included in the manifest as a manifestation type.
- **Density/perf research:** Indirect benefit — density-research renames (e.g., renaming allocator functions during optimization) are the most cross-language and most risky.

## Concrete artifact

`.refactor-manifest/renames.yaml`:
```yaml
concepts:
  - name: shard-alloc-burst
    description: "Burst pool allocation for shard service"
    manifestations:
      - language: go
        file: services/shard/alloc.go
        symbol: AllocBurstPool
        type: function
      - language: cpp
        file: lib/alloc/burst_pool.cc
        symbol: burst_pool_alloc
        type: function
      - language: python
        file: tools/bench/shard_bench.py
        symbol: bench_alloc_burst
        type: function
      - language: yaml
        file: charts/shard/values.yaml
        symbol: allocator.burstPoolEnabled
        type: config-key
      - language: groovy
        file: Jenkinsfile
        symbol: benchAllocBurst
        type: stage-name
    constraints:
      atomicity: same-pr
      naming: "Go PascalCase, C++ snake_case, Python snake_case, YAML camelCase"

  - name: gateway-health-check
    description: "Health check endpoint for gateway service"
    manifestations:
      - language: go
        file: services/gateway/health.go
        symbol: HealthCheck
        type: function
      - language: nodejs
        file: apps/bff/src/health.ts
        symbol: checkGatewayHealth
        type: function
      - language: yaml
        file: charts/gateway/values.yaml
        symbol: livenessProbe.httpGet.path
        type: config-value
```

Jenkins stage:
```groovy
stage('rename-consistency-check') {
  steps {
    script {
      def incomplete = renameConsistency(manifest: '.refactor-manifest/renames.yaml', diffAgainst: 'origin/main')
      if (incomplete) { error("Incomplete cross-language rename: ${incomplete.concepts.join(', ')}. All manifestations must be renamed together.") }
    }
  }
}
```

## Success metric
- Incomplete cross-language renames caught pre-merge increase from 0 to ≥3/month, each representing a prevented integration break.
- Zero cross-language rename breaks reach integration testing (down from ~1-2/month), measured over one quarter.
- Manifest coverage: ≥50 concepts registered within 8 weeks, covering all active cross-language API surfaces.
- AI tools complete cross-language renames correctly ≥80% of the time when using the manifest, measured by Jenkins pass rate.

## Risks & failure modes
- **Manifest staleness:** New cross-language links are added without manifest entries. Mitigated by periodic discovery scans and Jenkins warnings for renamed-but-unmanifested symbols.
- **Manifest over-specification:** Too many weak links create false alarms on partial renames. Mitigated by requiring "strong" links (compile/runtime dependency) vs. "advisory" links.
- **Naming convention complexity:** Each language has different naming conventions. The manifest handles this by listing per-language symbol names explicitly, but the rename command must apply per-language transforms.
- **Merge complexity:** Large renames touching many files may cause merge conflicts. Mitigated by recommending renames as standalone PRs and by the conflict forecast (idea 4).

## Originality statement

**Versus existing ideas in this repo:**
Idea 5 (FFI Boundary Contracts) addresses cross-language *boundaries* with type-safety tests; this idea addresses cross-language *renames* with a symbol-link manifest. Overlap: ~25% (both track cross-language relationships in a registry). The key difference: idea 5 tests data contracts at call sites; this idea coordinates naming consistency across the full symbol graph. Idea 4 (Conflict Forecast) prevents file collisions; this prevents semantic inconsistency.

**Versus common industry proposals:**
IDE rename refactoring exists per-language (gorename, rope, clang-rename), but *cross-language* rename coordination via a shared manifest is novel. There is no standard tool that links a Go function name to a Python client function name to a YAML config key. This idea creates that link as a shared artifact all AI tools consume. It satisfies heuristics #1 (new inter-tool interface: the rename manifest), #2 (capability asymmetry: Claude executes, Copilot suggests, Codex verifies, Cursor amplifies), #5 (language-stack specificity: the five-language mix is the reason this exists), and #8 (anti-coordination: preventing partial renames).
