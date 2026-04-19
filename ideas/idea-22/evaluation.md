# Evaluation: Idea 22 — Incident Replay Arena — AI Tools Compete on Reproducible Past-Incident Fix Scenarios

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

**Justification:** Team-specific, codebase-specific incident replay as an AI tool evaluation arena is genuinely novel. SWE-bench exists for public benchmarks, but using proprietary incidents with the team's own codebase, multi-language scenarios, and continuous expansion is a new application. The leaderboard + density-incident scoring + model-upgrade evaluation pipeline is creative. Hits heuristics #1, #2, #3, #5, #7.

**Evidence from idea.md:** The scenario format, Jenkins execution pipeline, and leaderboard with density-incident scoring are all specific innovations. The proprietary codebase advantage over public benchmarks is explicitly articulated.

**Hard cap check:** Overlap with ideas 2, 14, 16: each ≤15%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All tools have clear competition roles in their native modes: Claude in terminal, Copilot via Coding Agent PR, Codex via task file, Cursor via IDE with developer. The arena protocol is tool-agnostic (provide symptom, measure fix). Jenkins orchestrates all. Graceful degradation (skip unavailable tools) is natural.

**Evidence from idea.md:** Four per-tool subsections. Each tool competes in its strongest mode. Jenkins orchestrates.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Incidents span all five languages. Cross-language incidents (cgo boundary bugs) are prime scenarios. Per-language, per-tool performance is measurable from the results.

**Evidence from idea.md:** Example scenario involves Go + C++. Languages section covers all five. Scenarios are tagged by language.

## 4. Long-term maintainability — Score: 8/10

**Justification:** The scenario corpus grows naturally from incident retrospectives. Each scenario is a standalone YAML file. No schema evolution pressure. The leaderboard auto-regenerates from results. Main cost: authoring scenarios (30-60 min per incident, amortized across the retrospective process).

**Evidence from idea.md:** Risks address authoring effort and representativeness. Integration with incident retros amortizes the cost.

## 5. Implementation simplicity — Score: 3/10

**Justification:** Substantial effort: Jenkins job for multi-tool execution, per-tool invocation wrappers, scenario format with broken-state snapshots, validation framework, leaderboard generation, semantic comparison of fixes. Branch snapshot management is complex. ~4+ weeks.

**Evidence from idea.md:** Per-scenario execution involves checkout, tool invocation, validation, timing — each requiring custom orchestration. Branch snapshots need management.

## 6. Workflow impact — Score: 8/10

**Justification:** Enables data-driven tool selection for critical tasks — a strategic capability. Model upgrade evaluation is operationally important. Density-incident performance data directly informs density-research tool routing. The team moves from anecdotes to evidence.

**Evidence from idea.md:** Success metrics target statistically significant per-tool strengths and data-driven tool selection for density incidents.

## Weighted total

```
(0.35 × 9) + (0.20 × 8) + (0.10 × 9) + (0.15 × 8) + (0.10 × 3) + (0.10 × 8)
= 3.15 + 1.60 + 0.90 + 1.20 + 0.30 + 0.80
= 8.0
```

**Total: 8.0 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 10% | Both evaluate tools, but on different dimensions (hallucination vs incident-fixing). |
| 14 | Tool Confidence Calibration | 10% | Both produce per-tool quality data, but from different signals. |
| 16 | Cross-Tool Review Roulette | 15% | Both compare tools on the same task, but idea 16 is review quality and idea 22 is fix quality. |

## Verdict

**Strong** (≥ 8.0) — worth building.

## Top 3 improvements

1. **Auto-generate scenario stubs from incident tickets:** Integrate with the incident management system to auto-populate scenario YAML with commit ranges, component names, and symptoms, reducing the authoring effort to just adding the validation test and correct fix.
2. **Add a "progressive difficulty" dimension:** Tag scenarios by complexity (single-file fix, multi-file fix, cross-language fix, architecture-level fix) and track per-tool performance by difficulty tier, providing finer-grained capability insights.
3. **Run the arena on every model update:** When any AI tool ships a new model version, automatically run the full arena and generate a comparison report (old model vs. new model), providing an objective upgrade-or-wait decision for the team.
