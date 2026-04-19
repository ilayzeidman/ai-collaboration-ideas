# Evaluation: Idea 17 — Speculative Density Patch Queue — Off-Peak Jenkins Testing of AI-Generated Optimizations

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

## 1. Originality — Score: 9/10

**Justification:** Speculative AI-generated optimization patches tested during off-peak CI hours with automated promotion is a genuinely novel idea. No current tool or protocol combines AI-generated hypotheses + off-peak benchmark execution + auto-promotion. The "density optimization factory" concept — always-running, AI-driven, zero developer time cost — is creative and new. Hits heuristics #1, #2, #3, #4.

**Evidence from idea.md:** The queue/runner/promotion pipeline is specific and novel. The off-peak CI utilization is a clever resource optimization. The per-tool submission and contribution tracking add cross-tool evaluation.

**Hard cap check:** Overlap with ideas 3, 7, 13: each ~15%. All below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All tools have clear submission roles exploiting capability asymmetries. The queue is a simple YAML file — universally accessible. Jenkins handles all execution, so no tool needs to run benchmarks. Each tool submits patches in its own way (CLI, prompt, task file, IDE command).

**Evidence from idea.md:** Four per-tool subsections with differentiated submission patterns. Jenkins runner is the universal executor.

## 3. Multi-language applicability — Score: 8/10

**Justification:** Patches can target all five languages. Go and C++ are the primary density targets but Python/Node/C patches are supported. Benchmarks are per-language. The queue protocol is language-agnostic.

**Evidence from idea.md:** Languages section covers all five with per-language optimization examples.

## 4. Long-term maintainability — Score: 7/10

**Justification:** The queue is self-cleaning (promoted patches are removed, rejected patches are archived). Jenkins runner is a standard scheduled job. Main cost: keeping benchmark infrastructure healthy and managing queue volume. No schema evolution pressure.

**Evidence from idea.md:** Risks address flooding, staleness, and false promotions with concrete mitigations.

## 5. Implementation simplicity — Score: 4/10

**Justification:** Significant effort: queue schema, Jenkins runner with per-patch checkout/benchmark/result logic, auto-promotion to PR, submission scripts for each tool, priority/dedup system. The runner is the most complex piece — it must handle rebasing, benchmarking, and PR creation. ~3-4 weeks.

**Evidence from idea.md:** The runner must checkout, rebase, benchmark, compare, and optionally promote — a multi-step pipeline.

## 6. Workflow impact — Score: 9/10

**Justification:** Directly addresses the team's #1 research priority with zero developer time cost. The "always-running density factory" concept could deliver cumulative 5%+ pods-per-node improvement per quarter. The off-peak CI utilization is pure win — using idle infrastructure for the team's top priority. Maximum density-research coupling.

**Evidence from idea.md:** Success metrics target 5% cumulative pods-per-node improvement and per-tool density contribution tracking.

## Weighted total

```
(0.35 × 9) + (0.20 × 8) + (0.10 × 8) + (0.15 × 7) + (0.10 × 4) + (0.10 × 9)
= 3.15 + 1.60 + 0.80 + 1.05 + 0.40 + 0.90
= 7.9
```

**Total: 7.9 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 3 | Perf Witness Tickets | 15% | Both address density/perf but idea 3 validates developer PRs and idea 17 generates speculative patches. |
| 7 | Memory Budget Annotations | 15% | Both relate to memory discipline but idea 7 sets budgets and idea 17 generates improvements within them. |
| 13 | Pod Density Regression Bisect | 15% | Both serve density research but idea 13 root-causes problems and idea 17 generates improvements. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Add a "density backlog" as input:** Maintain a structured list of known optimization opportunities (from profiling, from rejected patches with "close but not enough" results) as fuel for AI tools, increasing patch quality.
2. **Chain with idea 7 memory budgets:** When a promoted patch changes memory usage, auto-update the relevant `@mem-budget` annotations, closing the loop between speculative optimization and budget enforcement.
3. **Add a feedback loop from production:** After a promoted patch is deployed, compare production metrics against the benchmark prediction. Use the delta to calibrate the benchmark environment, improving future promotion accuracy.
