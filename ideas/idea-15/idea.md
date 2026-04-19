# Idea 15: Dead Code Bounty Board — Cross-Tool Competition to Safely Eliminate Unused Code

## One-line summary
Maintain a shared board of suspected dead code targets; AI tools propose removal PRs with proof of non-use, competing on safe-removal success rate.

## Tags
density-research, cross-tool-routing, shared-protocol, multi-language, jenkins

## Problem
Dead code accumulates across all five languages. Unused Go handlers still run health checks, orphaned C++ allocator paths consume compile time and binary size, abandoned Python scripts clutter the tool directory, and stale Node.js routes bloat the BFF bundle. Every byte of dead code increases container image size, slows CI, and confuses AI tools (which treat dead code as live context and pattern-match against it, perpetuating its style).

The team knows dead code exists but nobody prioritizes removing it — the risk of breaking something by deleting seemingly-unused code is high, and the reward is diffuse. AI tools are uniquely suited to this: they can analyze call graphs, grep for references, check import chains, and propose removals with evidence. But no protocol exists for AI tools to systematically find, prove, and remove dead code in a coordinated, measurable way.

## Proposal
Introduce `.dead-code-bounty/board.yaml` — a structured file listing suspected dead code targets. Each entry specifies a file/function/module, the suspicion reason, and the required proof-of-non-use. AI tools compete to claim bounties: each tool proposes a removal PR with evidence, and Jenkins verifies the removal is safe (builds, tests pass, no runtime references in K8s configs or Helm charts).

The workflow:
1. **Discovery:** Any AI tool or human adds suspected targets to the board with evidence (no callers found, no imports, no runtime references).
2. **Claiming:** An AI tool claims a bounty by opening a PR that removes the code and includes the proof (call graph analysis, grep results, import chain, K8s config scan).
3. **Verification:** Jenkins `dead-code-verify` stage runs extended tests, checks K8s configs for runtime references, and validates no Helm chart or Jenkinsfile references exist.
4. **Scoring:** Successful removals are logged to `.dead-code-bounty/history.jsonl` with tool attribution. Failed attempts (removal broke something) are also logged.
5. **Metrics:** Per-tool success rate, total code removed (LOC, binary size delta), and density impact (image size reduction).

## Cross-AI-tool design

### Claude Code
- **Role:** Deep dead code discoverer. Claude Code's multi-file agentic analysis excels at tracing complex call graphs across languages (Go→C++ cgo chains, Python→C ctypes). A custom command (`/.claude/commands/find-dead-code.md`) runs a comprehensive dead code scan and proposes board entries. Also the preferred tool for removing dead code in density-critical C++/Go paths where the call graph is complex.
- **Shared contract it reads/writes:** Reads/writes `.dead-code-bounty/board.yaml`. Writes removal PRs. Reads `CLAUDE.md` bounty rules.
- **Fallback if unavailable:** `scripts/find-dead-code.sh` runs static analysis (unused imports, unreferenced exports) for basic discovery.

### GitHub Copilot
- **Role:** High-volume bounty claimer. Copilot Coding Agent can be tasked with claiming bounties — given a board entry, it opens a removal PR with evidence. `.github/prompts/dead-code-bounty.prompt.md` provides a structured bounty-claiming workflow. Copilot's PR-first model makes it the fastest path from bounty to PR.
- **Shared contract it reads/writes:** Reads `.dead-code-bounty/board.yaml`. Writes removal PRs via Coding Agent.
- **Fallback if unavailable:** Developer or other tools claim the bounty. Board remains available.

### Codex
- **Role:** Proof verifier. `AGENTS.md` includes a verification task template: given a claimed bounty and proposed removal, verify the proof-of-non-use independently (re-run call graph analysis, check all import chains, scan K8s configs). Codex's deterministic execution ensures consistent verification.
- **Shared contract it reads/writes:** Reads board entries and removal PRs. Writes verification results to `.dead-code-bounty/verifications/`.
- **Fallback if unavailable:** Jenkins extended tests serve as verification. Human review as final gate.

### Cursor
- **Role:** IDE-integrated dead code highlighter. `.cursor/rules/dead-code-bounty.mdc` instructs Cursor to highlight code that appears on the bounty board when the developer opens those files. A custom command `/dead-code` lists current bounties and their status. Cursor's inline display helps developers avoid writing new code that depends on soon-to-be-removed dead code.
- **Shared contract it reads/writes:** Reads `.dead-code-bounty/board.yaml`. Displays bounty status in IDE.
- **Fallback if unavailable:** `scripts/show-bounties.sh` from the terminal.

## Languages affected
All five: Go (unused handlers, stale service code), C++ (orphaned allocator paths, dead template instantiations), Python (abandoned scripts, unused imports), Node.js (stale routes, dead BFF endpoints), C (legacy driver functions no longer called). Each language has different dead-code detection tools (Go: `deadcode`, C++: `clang-tidy`, Python: `vulture`, Node: `ts-prune`/`knip`, C: custom grep). The bounty protocol is language-agnostic but proofs leverage language-specific tools.

## Infra impact
- **Jenkins:** New stage `dead-code-verify` runs on bounty-claim PRs. Extended test suite + K8s config scan + Helm reference check. Adds 5-10 minutes for bounty PRs (not all PRs). Per-tool metrics in history log.
- **Kubernetes:** Scans deployment manifests and Helm charts for runtime references to bounty targets. No new K8s objects.
- **Density/perf research:** Direct benefit — every removed dead code path reduces binary size and container image size, directly improving pod density. C++ dead code removal has the highest density impact.

## Concrete artifact

`.dead-code-bounty/board.yaml`:
```yaml
bounties:
  - id: bounty-001
    target:
      file: services/shard/legacy_alloc.go
      symbol: LegacyAllocPool
      type: function
      language: go
    suspicion: "No callers found in call graph. Last modified 2025-06-15. Not in any test."
    required_proof:
      - no_callers_in_go_callgraph
      - no_references_in_helm_charts
      - no_references_in_jenkinsfile
      - no_references_in_k8s_manifests
    status: open
    estimated_loc_removal: 85
    estimated_binary_delta_kb: -12

  - id: bounty-002
    target:
      file: lib/alloc/pool_v1.cc
      symbol: pool_v1_alloc
      type: function
      language: cpp
    suspicion: "Replaced by pool_v2_alloc in Q3 2025. Only test reference is in deprecated test file."
    required_proof:
      - no_callers_outside_deprecated_tests
      - no_cgo_references
      - no_dynamic_dlopen_references
    status: claimed
    claimed_by: claude-code
    claimed_at: "2026-04-18T14:00:00Z"
```

`.dead-code-bounty/history.jsonl`:
```jsonl
{"ts":"2026-04-18T16:00:00Z","bounty":"bounty-002","tool":"claude-code","result":"success","loc_removed":120,"binary_delta_kb":-18,"image_delta_mb":-0.5,"pr":"#4850"}
```

## Success metric
- ≥20 bounties claimed and successfully resolved in the first quarter.
- Total dead code removed: ≥5000 LOC and ≥500KB binary size reduction, measured by bounty history log.
- Container image size for density-critical services decreases by ≥2%, directly improving pods-per-node.
- Per-tool success rate (safe removals / total attempts) is trackable and ≥80% for the best tool.
- Zero regressions from dead code removal (all removals pass extended tests and 30-day monitoring).

## Risks & failure modes
- **False positives:** Code appears dead but is reached via reflection, dynamic loading, or external callers. Mitigated by requiring multi-source proof (static + dynamic + config scan) and extended test verification.
- **Board staleness:** Bounties are posted but never claimed. Mitigated by auto-assigning unclaimed bounties to tools during off-peak CI cycles.
- **Low-value bounties:** Small removals (3 lines) clog the board. Mitigated by minimum LOC threshold (≥20 lines) for board entries.
- **Cross-language dead code:** A Go function that only serves as a cgo export target appears dead to Go analysis but is called from C++. Mitigated by requiring cgo and dlopen reference checks in the proof.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) measures hallucination; idea 7 (Memory Budget Annotations) enforces allocation limits; idea 13 (Pod Density Regression Bisect) root-causes density regressions. This idea *prevents* density waste by removing code that shouldn't exist. Overlap with idea 13: ~15% (both serve density research). No idea in the repo addresses dead code specifically.

**Versus common industry proposals:**
Dead code detection tools exist per-language (`deadcode`, `vulture`, `ts-prune`), but a cross-tool *competition protocol* with bounties, proof requirements, verification, and per-tool scoring is novel. This is not a "generic lint agent" (tired idea) — it's a structured bounty system that coordinates AI tools to systematically eliminate dead code with evidence and safety verification. It satisfies heuristics #1 (new inter-tool interface: the bounty board), #2 (capability asymmetry: Claude discovers, Copilot claims, Codex verifies, Cursor highlights), #3 (density-research coupling: binary size → pod density), #5 (language-stack specificity: five languages with different detection tools), and #7 (shared evaluation surface: per-tool success rates).
