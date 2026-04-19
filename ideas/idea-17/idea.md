# Idea 17: Speculative Density Patch Queue — Off-Peak Jenkins Testing of AI-Generated Optimizations

## One-line summary
AI tools speculatively submit density-improvement patches to a shared queue; Jenkins tests them during off-peak hours and promotes winners to real PRs.

## Tags
density-research, jenkins, kubernetes, cross-tool-routing, shared-protocol

## Problem
Density optimization is the team's top research priority, but it competes with feature work for developer time and CI resources. Developers often have intuitions about optimization opportunities ("this allocator could use arenas", "that cache could be smaller") but don't have time to benchmark them. AI tools could speculatively generate and test density patches, but there's no protocol for them to do so without consuming precious peak-hour CI capacity or cluttering the PR queue with unverified experiments.

The result: density improvements happen only when a developer explicitly prioritizes them, losing the long tail of small optimizations that individually save 1-3% memory but collectively could improve pods-per-node by 20%+.

## Proposal
Introduce `.density-queue/` — a speculative patch queue where AI tools submit density-improvement hypotheses for off-peak Jenkins testing:

1. **Submission:** AI tools write speculative patches to `.density-queue/pending/<patch-id>.yaml`, each containing: the patch diff, the hypothesis ("replacing sync.Pool with arena should save ~200KB RSS per shard"), the benchmark command(s), and the expected improvement.
2. **Off-peak execution:** A Jenkins scheduled job (`density-queue-runner`) runs during off-peak hours (nights, weekends). It picks up pending patches, applies each to a fresh checkout, runs the specified benchmarks, and records results to `.density-queue/results/<patch-id>.jsonl`.
3. **Promotion:** Patches that meet the improvement threshold (≥2% RSS reduction, ≥1% pods-per-node improvement) are auto-promoted: the runner opens a real PR with the patch, the benchmark results, and a request for human review.
4. **Rejection:** Patches that fail benchmarks, break tests, or show no improvement are moved to `.density-queue/rejected/` with the failure reason, preventing re-submission of the same hypothesis.

## Cross-AI-tool design

### Claude Code
- **Role:** Primary density hypothesis generator. Claude Code's deep analysis capability makes it the best tool for identifying non-obvious density optimization opportunities (arena substitution, allocation pattern changes, cgo overhead reduction). A custom command (`/.claude/commands/density-patch.md`) generates a speculative patch with hypothesis and benchmark commands. Claude Code can also analyze rejected patches to understand why they failed and propose improved versions.
- **Shared contract it reads/writes:** Writes patches to `.density-queue/pending/`. Reads `.density-queue/results/` and `.density-queue/rejected/`. Reads `CLAUDE.md` density-queue rules.
- **Fallback if unavailable:** Developer writes the patch manually using the template. Jenkins runner doesn't care about the source.

### GitHub Copilot
- **Role:** Quick-fix density patch submitter. When a developer is editing a density-critical path and Copilot suggests an optimization, the developer can submit it as a speculative patch via `.github/prompts/density-patch.prompt.md` without committing it to their branch. Copilot Coding Agent can also be tasked with generating density patches from a backlog of known optimization opportunities.
- **Shared contract it reads/writes:** Writes patches to `.density-queue/pending/`. Reads results via PR descriptions on promoted patches.
- **Fallback if unavailable:** Manual submission or other tools.

### Codex
- **Role:** Systematic patch generator. `AGENTS.md` includes a density-sweep task template: Codex scans for known optimization patterns (unnecessary allocations, oversized buffers, untuned GC parameters) and generates patches systematically. Its deterministic execution produces consistent, reproducible patches.
- **Shared contract it reads/writes:** Reads `AGENTS.md` density-sweep directive and `.density-queue/rejected/` (to avoid re-submission). Writes patches to `.density-queue/pending/`.
- **Fallback if unavailable:** Manual or other-tool submission.

### Cursor
- **Role:** IDE-integrated patch submission. `.cursor/rules/density-queue.mdc` instructs Cursor to offer "submit as density experiment" when the developer makes an optimization-related change in Agent mode. A custom command `/density-patch` packages the current unsaved changes as a speculative patch. Cursor's IDE integration makes it the lowest-friction submission surface.
- **Shared contract it reads/writes:** Writes patches to `.density-queue/pending/`. Reads results for patches the developer submitted.
- **Fallback if unavailable:** CLI: `scripts/submit-density-patch.sh <diff-file> <hypothesis>`.

## Languages affected
All five, with emphasis on Go and C++ (the density-critical languages). Speculative patches can target: Go memory patterns (sync.Pool → arena, buffer sizing, GC tuning), C++ allocators (jemalloc configuration, arena sizing, object pooling), Python pipeline memory (generator patterns, batch sizing), Node.js heap (cache sizing, stream vs. buffer), C primitives (allocation strategy, buffer reuse). Each language has native benchmark tools used in the results.

## Infra impact
- **Jenkins:** New scheduled job `density-queue-runner` running during off-peak hours (configurable schedule, default: 10 PM - 6 AM and weekends). Runs benchmarks for pending patches on dedicated or shared agents. Auto-opens PRs for winning patches. Resource-intensive but constrained to off-peak, so no impact on developer-facing CI.
- **Kubernetes:** No new K8s objects. Benchmark results include simulated pods-per-node based on current Helm resource specs.
- **Density/perf research:** Core density mechanism. This is the team's "density optimization factory" — a systematic, always-running pipeline for discovering and validating density improvements without consuming developer time or peak CI capacity.

## Concrete artifact

`.density-queue/pending/arena-shard-alloc.yaml`:
```yaml
patch_id: arena-shard-alloc
submitted_by:
  tool: claude-code
  developer: alice
  timestamp: "2026-04-19T14:00:00Z"

hypothesis: "Replacing sync.Pool with jemalloc arena in AllocBurstPool should reduce per-shard RSS by ~200KB (10%) due to better allocation locality"

diff: |
  --- a/services/shard/alloc.go
  +++ b/services/shard/alloc.go
  @@ -42,3 +42,3 @@
  -  pool := sync.Pool{New: func() interface{} { return make([]byte, 4096) }}
  +  pool := arena.NewPool(arena.WithBurstSize(2 * 1024 * 1024))

benchmarks:
  - command: "go test ./services/shard/... -bench=BenchmarkAllocBurst -run=^$ -benchmem"
    metric: alloc_bytes
    expected_improvement_pct: 10
  - command: "go test ./services/shard/... -bench=BenchmarkLoad -run=^$ -benchmem"
    metric: rss_mb
    expected_improvement_pct: 10

promotion_threshold:
  min_rss_reduction_pct: 2
  min_pods_per_node_improvement_pct: 1

priority: high
related_mem_budget: "services/shard/alloc.go:42:AllocBurstPool"
```

`.density-queue/results/arena-shard-alloc.jsonl`:
```jsonl
{"ts":"2026-04-20T02:30:00Z","patch":"arena-shard-alloc","benchmark":"BenchmarkAllocBurst","baseline":{"alloc_bytes":4096},"patched":{"alloc_bytes":2048},"improvement_pct":50.0}
{"ts":"2026-04-20T02:35:00Z","patch":"arena-shard-alloc","benchmark":"BenchmarkLoad","baseline":{"rss_mb":1.8},"patched":{"rss_mb":1.6},"improvement_pct":11.1}
{"ts":"2026-04-20T02:36:00Z","patch":"arena-shard-alloc","verdict":"promote","improvement_summary":"RSS -11.1%, estimated pods-per-node +3.2%","pr_opened":"#4855"}
```

## Success metric
- ≥50 speculative patches submitted in the first quarter, across all four tools.
- ≥10 patches promoted to real PRs (20% promotion rate), each delivering measurable density improvement.
- Cumulative pods-per-node improvement of ≥5% from promoted patches within one quarter.
- Zero off-peak CI capacity wasted on peak-hour work (all queue runs happen during scheduled windows).
- Per-tool density contribution becomes measurable: which tool generates the most successful density patches.

## Risks & failure modes
- **Queue flooding:** Tools submit too many low-quality patches. Mitigated by a per-tool daily submission limit and a priority system. Rejected patches with similar hypotheses are deduplicated.
- **Benchmark environment variance:** Off-peak CI agents may differ from production environments. Mitigated by running benchmarks on the same agent class used for regular CI.
- **Stale patches:** Pending patches may conflict with merged changes by the time they run. Mitigated by the runner rebasing each patch against main before testing.
- **False promotions:** A patch improves benchmarks but regresses something else. Mitigated by running the full test suite (not just the specified benchmarks) before promotion.

## Originality statement

**Versus existing ideas in this repo:**
Idea 3 (Perf Witness Tickets) predicts perf for developer-authored PRs; this idea generates and tests density patches *speculatively* without developer involvement. Idea 7 (Memory Budget Annotations) sets per-function budgets; this idea generates patches that improve within those budgets. Idea 13 (Pod Density Regression Bisect) root-causes regressions; this idea proactively generates improvements. All are complementary. Overlap with idea 3: ~15%, idea 7: ~15%, idea 13: ~15%.

**Versus common industry proposals:**
This is not a "generic test generation bot" (tired idea) — it generates *optimization patches*, not tests. It's not a generic CI pipeline — it's a speculative execution system specifically for density research. The combination of AI-generated optimization hypotheses + off-peak CI testing + automated promotion is novel. It satisfies heuristics #1 (new inter-tool interface: the density queue), #2 (capability asymmetry: Claude hypothesizes deeply, Codex sweeps systematically, Copilot submits quickly, Cursor captures ad-hoc ideas), #3 (density-research coupling: this IS the density optimization factory), and #4 (Jenkins leverage: uses existing CI infrastructure during idle hours).
