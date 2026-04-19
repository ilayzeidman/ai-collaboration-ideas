# Evaluation: Idea 7 — Memory Budget Annotations — Inline Allocation Caps Verified by CI Across All Languages

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

**Justification:** Per-function memory budgets as structured source annotations with cross-tool AI enforcement is genuinely novel. Web performance budgets (Lighthouse) exist but are page-level and not tied to AI tool compliance. Compiler pragmas are compile-time, not CI-verified. The combination of inline annotations + AI tool awareness + CI benchmark verification + density-research coupling is new. Hits heuristics #1, #3, #4, #5.

**Evidence from idea.md:** Proposal defines a specific annotation format across five languages, an auto-generated index, and a CI verification pipeline. Originality statement distinguishes from Lighthouse budgets and compiler pragmas.

**Hard cap check:** Overlap with idea 3: ~20%, idea 2: ~10%. Both below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 7/10

**Justification:** All four tools have roles, but the inline annotation relies heavily on tools reading and respecting structured comments — a weaker signal than a separate file. Copilot's inline completions may not consistently read nearby annotations. The Jenkins gate is the real enforcer. Graceful degradation is solid (CI catches everything).

**Evidence from idea.md:** Four per-tool subsections with roles. Jenkins as definitive verifier. Budget annotations are in the code context each tool reads.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Explicitly covers all five languages with language-specific comment syntax and benchmark tools. The annotation format is consistent across languages. Each language has a native benchmark mechanism.

**Evidence from idea.md:** Five language-specific annotation examples. Five benchmark tool mentions (go test, allocator_bench, pytest+memray, clinic, valgrind).

## 4. Long-term maintainability — Score: 6/10

**Justification:** Annotations can rot as workloads change. Benchmark flakiness adds noise. The `last_measured` staleness check mitigates rot, but ongoing curation of annotations and benchmark commands is needed. The system is self-enforcing (Jenkins) but requires human judgment on when to adjust budgets.

**Evidence from idea.md:** Risks section covers annotation rot, benchmark flakiness, and over-annotation with mitigations.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: annotation parser for five languages, index generator, Jenkins stage that runs targeted benchmarks, benchmark result comparison logic, waiver system. The benchmarks themselves already exist; the integration layer is the new work. ~2-3 weeks.

**Evidence from idea.md:** Concrete artifacts show parser, index, and Jenkins stage. Each language needs a benchmark integration point.

## 6. Workflow impact — Score: 9/10

**Justification:** Directly addresses the team's #1 research priority: density. Per-function memory budgets encode density targets at the code level, making them CI-enforceable. This is the most direct density-research tool in the repo. Prevents density regressions at the PR level rather than post-merge.

**Evidence from idea.md:** Success metrics target density-critical annotations, pre-merge catches, and zero post-merge regressions in annotated paths.

## Weighted total

```
(0.35 × 8) + (0.20 × 7) + (0.10 × 9) + (0.15 × 6) + (0.10 × 5) + (0.10 × 9)
= 2.80 + 1.40 + 0.90 + 0.90 + 0.50 + 0.90
= 7.4
```

**Total: 7.4 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 10% | Both use annotations in source code, but for different purposes (hallucination traps vs memory budgets). |
| 3 | Perf Witness Tickets | 20% | Both enforce performance discipline via CI, but at different granularity (per-PR ticket vs per-function annotation) and with different metrics. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Start with C++ and Go only:** Focus initial rollout on the two density-critical languages where memory budgets have the highest ROI, then expand to Python/Node/C. This cuts initial implementation effort in half.
2. **Auto-suggest budgets from historical benchmarks:** Use the `last_measured` data to propose initial budgets for unannotated hot-path functions, reducing the annotation bootstrapping effort.
3. **Link budgets to Helm resource requests:** When per-function budgets change significantly, auto-generate Helm resource request adjustment suggestions, closing the loop between code-level and pod-level density optimization.
