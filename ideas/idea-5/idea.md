# Idea 5: FFI Boundary Contracts — AI-Maintained Type-Safety Tests at Cross-Language Call Sites

## One-line summary
Maintain a registry of FFI boundary call sites with auto-generated contract tests that AI tools must update when modifying either side.

## Tags
multi-language, cross-tool-routing, density-research, shared-protocol, ffi-safety

## Problem
The team ships Go services that call C++ allocators via cgo, Python scripts that invoke C extensions, and Node.js BFFs that shell out to Go CLIs. These FFI boundaries are where bugs hide longest — a C++ struct layout change that silently corrupts the Go caller, a Python ctypes signature that drifts from the C header, or a Node child-process contract that assumes a JSON schema the Go CLI no longer emits. AI tools make this worse: they confidently modify one side of a boundary without realizing the other side exists, because the caller and callee live in different directories, different languages, and sometimes different repos.

Today there is no single artifact that lists these boundaries or tests them as pairs. Reviewers catch cross-language breaks by tribal knowledge. When a density-research C++ memory-layout change ships and the Go cgo caller segfaults in staging, the team loses a day.

## Proposal
Introduce `.ffi-boundaries/registry.yaml` — a structured file listing every cross-language call site in the repo. Each entry describes: (a) the caller (language, file, function), (b) the callee (language, file, function/symbol), (c) the data contract (struct layout, JSON schema, CLI arg format), and (d) a pointer to a generated contract test that exercises the boundary.

AI tools are instructed (via their respective rule files) to consult the registry before modifying any file listed as a caller or callee. When a tool modifies one side, it must also update the contract test and, if the data contract changed, flag the other side for review.

A Jenkins stage `ffi-boundary-check` runs the contract tests on every PR that touches a registered boundary file. It also runs a drift detector that compares the declared data contracts against the actual signatures/schemas in the code, catching cases where a tool modified the code without updating the registry.

## Cross-AI-tool design

### Claude Code
- **Role:** Boundary discoverer and contract generator. Claude Code's terminal-native agentic mode is best suited for deep cross-directory analysis. A custom command (`/.claude/commands/discover-ffi.md`) instructs it to scan for cgo imports, ctypes calls, subprocess invocations, and FFI headers, then propose new registry entries and generate contract tests. Also the primary tool for updating both sides of a boundary when doing density-research refactors.
- **Shared contract it reads/writes:** Reads/writes `.ffi-boundaries/registry.yaml` and `.ffi-boundaries/tests/`. Reads `CLAUDE.md` boundary-awareness rules.
- **Fallback if unavailable:** `scripts/discover-ffi.py` performs a static grep-based scan for known FFI patterns (cgo, ctypes, child_process, dlopen) and outputs candidate entries. Lower precision but maintains the registry.

### GitHub Copilot
- **Role:** Inline boundary-aware completions. `.github/copilot-instructions.md` includes the rule: "Before completing code in a file listed in `.ffi-boundaries/registry.yaml`, check the paired file and data contract." Copilot Coding Agent PRs that touch boundary files must include updated contract tests. `.github/prompts/ffi-check.prompt.md` lets developers verify boundary consistency on demand.
- **Shared contract it reads/writes:** Reads `.ffi-boundaries/registry.yaml` and data contract schemas. Writes updated contract tests in boundary-touching PRs.
- **Fallback if unavailable:** Jenkins `ffi-boundary-check` stage catches missing or failing contract tests regardless of which tool authored the change.

### Codex
- **Role:** Contract test executor and verifier. `AGENTS.md` instructs Codex to run `scripts/ffi-boundary-test.sh` before submitting any task that touches files in the registry. Codex's deterministic execution is ideal for running the full contract test suite as a pre-submit gate, ensuring both sides of each boundary agree before the PR is opened.
- **Shared contract it reads/writes:** Reads `.ffi-boundaries/registry.yaml` and `AGENTS.md` directives. Writes test results and updated contract metadata.
- **Fallback if unavailable:** Jenkins runs the same tests. Local execution is a convenience, not a requirement.

### Cursor
- **Role:** IDE boundary visualizer. `.cursor/rules/ffi-boundaries.mdc` instructs Cursor to highlight when the developer is editing a file that participates in a registered boundary. A custom command `/ffi-check` shows the paired file, the data contract, and the contract test status. Cursor's IDE tightness makes it the best surface for "you're about to break a boundary" warnings during editing.
- **Shared contract it reads/writes:** Reads `.ffi-boundaries/registry.yaml`. Writes updated contract tests when modifying boundary files in Agent mode.
- **Fallback if unavailable:** `scripts/ffi-boundary-check.sh <file>` provides the same information from the terminal.

## Languages affected
All five team languages are directly involved: Go↔C++ (cgo for density-critical allocators), Python↔C (ctypes/cffi for perf primitives), Node.js↔Go (child-process CLI calls), and C++↔C (direct FFI at the driver/library layer). The registry is language-agnostic YAML; the contract tests are written in whichever language is simplest for each boundary (typically Go test or Python pytest). This idea is maximally multi-language — it exists precisely because the team uses five languages.

## Infra impact
- **Jenkins:** New stage `ffi-boundary-check` in the shared library: validates registry consistency, runs contract tests for touched boundaries, and fails the PR if a boundary test fails. Adds ~30 seconds to CI for boundary-touching PRs; no impact on PRs that don't touch boundaries.
- **Kubernetes:** No runtime impact. Boundaries are tested at build time.
- **Density/perf research:** Strongly coupled. The most fragile boundaries are exactly the density-critical C++↔Go cgo call sites where memory layout changes have the highest cost. Catching these breaks before merge directly protects density-research velocity.

## Concrete artifact

`.ffi-boundaries/registry.yaml` (excerpt):
```yaml
boundaries:
  - id: shard-alloc-cgo
    caller:
      language: go
      file: services/shard/alloc.go
      function: AllocBurstPool
    callee:
      language: cpp
      file: lib/alloc/burst_pool.cc
      symbol: burst_pool_alloc
    contract:
      type: cgo-struct
      schema_file: .ffi-boundaries/schemas/burst_pool_args.json
    test: .ffi-boundaries/tests/test_shard_alloc_cgo.go

  - id: metrics-ctypes
    caller:
      language: python
      file: tools/metrics/collector.py
      function: read_counters
    callee:
      language: c
      file: lib/perf/counters.c
      symbol: perf_read_counters
    contract:
      type: ctypes-signature
      schema_file: .ffi-boundaries/schemas/perf_counters_sig.json
    test: .ffi-boundaries/tests/test_metrics_ctypes.py
```

Jenkins stage:
```groovy
stage('ffi-boundary-check') {
  when { changeset pattern: '**', comparator: 'GLOB' }
  steps {
    script {
      def touched = ffiBoundaryCheck(registry: '.ffi-boundaries/registry.yaml')
      if (touched.failing) { error("FFI boundary contract broken: ${touched.summary}") }
    }
  }
}
```

## Success metric
- 100% of known cgo and ctypes boundaries registered within 4 weeks of adoption.
- Zero cross-language boundary breaks reach staging (down from ~2/month currently), measured over one quarter.
- AI tools update both sides of a boundary in >80% of boundary-touching PRs, measured by registry-aware diffstat.
- Time to diagnose cross-language bugs drops by 60%, measured by issue-resolution timestamps on boundary-tagged bugs.

## Risks & failure modes
- **Registry staleness:** New boundaries are added without registry entries. Mitigated by periodic `discover-ffi` scans and a Jenkins warning for unregistered FFI patterns in diffs.
- **Contract over-specification:** Overly strict contracts cause false failures. Mitigated by supporting flexible contract types (struct layout, JSON schema, CLI arg pattern) with appropriate tolerance.
- **Maintenance burden:** The registry grows as the codebase grows. Mitigated by auto-discovery scripts and the convention that boundary owners maintain their entries.
- **Incomplete language coverage:** Some FFI patterns (e.g., gRPC between services) are not traditional FFI. Mitigated by scoping to in-process boundaries initially and expanding later.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) traps hallucinated symbols; idea 3 (Perf Witness Tickets) predicts perf impact. This idea detects cross-language boundary breaks caused by one-sided AI modifications — a fundamentally different failure mode. Overlap with idea 2: ~10% (both use Jenkins gates). Overlap with idea 3: ~15% (both touch density-research and cross-language code).

**Versus common industry proposals:**
This is not a lint agent, test generator, review bot, or documentation generator from the tired-ideas list. While contract testing (Pact, etc.) exists for service-to-service APIs, applying it to in-process FFI boundaries (cgo, ctypes, dlopen) with AI-tool-aware discovery and per-tool roles is novel. The idea specifically targets the team's five-language FFI surface — a real and underserved pain point — and ties it to density-research velocity. It satisfies novelty heuristics #1 (new inter-tool interface: the boundary registry), #2 (capability asymmetry: Claude discovers, Cursor warns, Codex verifies), #3 (density-research coupling via cgo boundaries), and #5 (language-stack specificity: the five-language mix is the reason this idea exists).
