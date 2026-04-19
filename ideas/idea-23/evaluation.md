# Evaluation: Idea 23 — Build Graph Advisor — AI-Optimized Jenkins Pipeline Parallelism from Dependency Analysis

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

## 1. Originality — Score: 7/10

**Justification:** Build pipeline optimization is a known practice, and dependency graph analysis is standard. The novelty is in AI-driven analysis with cross-tool roles, A/B verification on real builds, and automated Jenkinsfile updates via PR. The combination is moderately novel — the individual pieces are familiar but the orchestration is new. Hits heuristics #1, #2, #4, #5.

**Evidence from idea.md:** The build graph extraction → AI proposal → verification → promotion pipeline is specific and orchestrated. Cross-tool roles differentiate this from manual optimization.

**Hard cap check:** Overlap with ideas 2, 3: each ~10%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 7/10

**Justification:** Tool roles are clear but asymmetric: Claude does the analysis, Copilot edits Jenkinsfile, Codex extracts/verifies, Cursor visualizes. The build graph JSON is universally accessible. The optimization logic is the hard part, and it's concentrated in Claude's role. Other tools have lighter but concrete roles.

**Evidence from idea.md:** Four per-tool subsections with differentiated roles. Python fallback for optimization.

## 3. Multi-language applicability — Score: 9/10

**Justification:** The build graph spans all five languages' build systems. The idea is maximally multi-language because the parallelism opportunity arises from the five-language build pipeline. Cross-language dependencies (cgo-integration depending on both go-build and cpp-compile) are the key insight.

**Evidence from idea.md:** Graph example shows all five language build stages plus cross-language integration.

## 4. Long-term maintainability — Score: 7/10

**Justification:** Graph extraction can be automated. Proposals are ephemeral. The main ongoing cost is re-extracting and re-optimizing when the pipeline changes. The verification framework (replay builds) is reusable. Agent contention tuning may require periodic adjustment.

**Evidence from idea.md:** Risks address agent contention, flakiness, staleness, and complexity with mitigations.

## 5. Implementation simplicity — Score: 4/10

**Justification:** Significant effort: build graph extraction from Jenkinsfile + Makefile analysis, duration measurement from Jenkins API, optimization algorithm, verification via build replay, Jenkinsfile generation. Build replay is the hardest piece. ~3-4 weeks.

**Evidence from idea.md:** Multiple components: extraction script, proposal format, verification job, Jenkinsfile generation.

## 6. Workflow impact — Score: 8/10

**Justification:** CI speed directly affects every developer's feedback loop and density-research iteration speed. A 25%+ wall-clock reduction is a significant productivity win. Faster CI also accelerates the speculative density patch queue (idea 17) and perf witness verification (idea 3).

**Evidence from idea.md:** Success metrics target 25% CI time reduction and 10% agent hour reduction. Density-research feedback loop acceleration.

## Weighted total

```
(0.35 × 7) + (0.20 × 7) + (0.10 × 9) + (0.15 × 7) + (0.10 × 4) + (0.10 × 8)
= 2.45 + 1.40 + 0.90 + 1.05 + 0.40 + 0.80
= 7.0
```

**Total: 7.0 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 10% | Both add Jenkins stages, but for different purposes (hallucination detection vs pipeline optimization). |
| 3 | Perf Witness Tickets | 10% | Both use Jenkins, but idea 3 verifies perf predictions and idea 23 optimizes pipeline structure. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Start with a manual graph:** Instead of auto-extracting from Jenkinsfile (complex parsing), have the team manually define the initial build graph JSON and validate it. Auto-extraction can be added later as a convenience.
2. **Add incremental optimization:** Instead of re-analyzing the full graph each time, track which stages were added or modified and propose incremental parallelism adjustments, reducing analysis overhead.
3. **Integrate agent capacity into proposals:** Factor in actual Jenkins agent pool size and queue depth when proposing parallelism, ensuring proposals are realistic for the team's infrastructure. Over-parallelizing with limited agents can increase queue time and negate wall-clock gains.
