# Evaluation: Idea 13 — Pod Density Regression Bisect — AI-Driven Binary Search for Density Regressions

## Rubric

Six criteria, weights sum to 1.00. Each criterion scored 1–10. Weighted total = Σ(weight × score), to one decimal place.

| # | Criterion | Weight |
|---|-----------|--------|
| 1 | Originality | 0.35 |
| 2 | Cross-AI-tool feasibility | 0.20 |
| 3 | Multi-language applicability | 0.10 |
| 4 | Long-term maintainability | 0.15 |
| 5 | Implementation simplicity (inverted effort — 10 = trivial) | 0.10 |
| 6 | Workflow impact | 0.10 |

## 1. Originality — Score: 8/10

**Justification:** `git bisect` is ancient, but AI-driven smart-midpoint selection with cross-tool strategy (one tool analyzes, another correlates, another executes, another monitors) for density-specific regressions is novel. The integration with perf-witness tickets (idea 3) for acceleration is a creative cross-idea link. Hits heuristics #1, #2, #3, #4, #7.

**Evidence from idea.md:** The smart midpoint strategy, perf-witness ticket correlation, and multi-tool execution pipeline are all specific innovations over plain `git bisect`.

**Hard cap check:** Overlap with idea 3: ~20%. Below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 7/10

**Justification:** Tool roles are well-differentiated (strategy, correlation, execution, monitoring), but the orchestration complexity is high — coordinating four tools across multiple bisect iterations requires robust protocol handling. Jenkins as the orchestrator simplifies this. Graceful degradation is solid (naive bisect works without any AI tool).

**Evidence from idea.md:** Four per-tool subsections with distinct roles. Jenkins orchestrates centrally. Each tool's absence degrades to a simpler mode.

## 3. Multi-language applicability — Score: 8/10

**Justification:** Bisect protocol is language-agnostic. Benchmarks are per-language. Most valuable for Go↔C++ density regressions. Applies to all five languages but with varying ROI.

**Evidence from idea.md:** Languages section covers all five. Example focuses on Go/C++ as highest-value target.

## 4. Long-term maintainability — Score: 7/10

**Justification:** Protocol is self-contained (only activates during regressions). Auto-closing stale bisects prevents rot. Benchmark commands must be maintained, but they already exist in the density-research tooling. Smart midpoint logic may need tuning as codebase evolves.

**Evidence from idea.md:** Risks address flakiness, cross-commit interactions, and stale files with concrete mitigations.

## 5. Implementation simplicity — Score: 3/10

**Justification:** Substantial effort: bisect orchestration job in Jenkins, smart midpoint strategy engine, benchmark execution per midpoint, result recording, perf-witness ticket correlation, resolution generation. Each bisect iteration involves a full checkout + build + benchmark. Multi-week project.

**Evidence from idea.md:** The orchestration pipeline (strategy → execution → result → next midpoint) is complex. Resource cost per bisect is high.

## 6. Workflow impact — Score: 9/10

**Justification:** Directly addresses the team's most expensive post-merge failure class: density regressions. Reducing root-cause time from 1-2 days to <4 hours is a massive productivity win. The density-research coupling is the strongest of any idea in the repo.

**Evidence from idea.md:** Success metrics target 75%+ reduction in time-to-root-cause for the team's #1 post-merge cost.

## Weighted total

```
(0.35 × 8) + (0.20 × 7) + (0.10 × 8) + (0.15 × 7) + (0.10 × 3) + (0.10 × 9)
= 2.80 + 1.40 + 0.80 + 1.05 + 0.30 + 0.90
= 7.3
```

**Total: 7.3 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 3 | Perf Witness Tickets | 20% | Both address density/perf but at different lifecycle points (pre-merge prediction vs post-merge root-cause). Cross-idea integration is a strength. |
| 7 | Memory Budget Annotations | 15% | Both relate to memory discipline, but idea 7 prevents regressions and idea 13 root-causes them. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Start with a simple Jenkins-only bisect:** Ship the protocol with naive binary search in Jenkins first (no AI strategy), then layer smart midpoints on top. This delivers value immediately with lower implementation cost.
2. **Cache benchmark results per commit:** Store benchmark results in `.density-bisect/cache/` so repeated bisects on overlapping commit ranges skip already-tested midpoints, reducing resource cost.
3. **Integrate with idea 7 memory budget annotations:** When the guilty commit is identified, automatically check if it violated a `@mem-budget` annotation, providing immediate context for remediation.
