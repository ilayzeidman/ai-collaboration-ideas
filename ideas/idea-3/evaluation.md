# Evaluation: Idea 3 — Perf Witness Tickets — Predict-Then-Verify Density Claims Per PR

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

**Justification:** This is not in the tired-ideas set (not a summarizer/linter/test bot/review bot) and introduces a concrete shared protocol (predict-then-verify perf ticket + CI verification) across tools. The core concept is novel for this repo, though adjacent to known industry patterns like performance budgets and benchmark gates, so it is strong but not breakthrough-level.

**Evidence from idea.md:** Proposal defines `perf-witness/tickets/<branch>.json`, schema validation, benchmark execution, packing simulation, and prediction-error gating; originality statement explicitly differentiates from Idea 2 and tired ideas.

**Hard cap check:** Highest overlap is with Idea 2 at ~24% (shared Jenkins gate + cross-tool attribution pattern), below the 30% cap threshold. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** The idea satisfies cross-tool principles: shared repo artifact, explicit roles for all four tools, and fallback paths for each. Minor feasibility risk remains in role consistency (Cursor/Codex behaviors may depend on workflow discipline), but Jenkins enforcement keeps the protocol viable even with uneven tool capability.

**Evidence from idea.md:** Each of Claude Code, GitHub Copilot, Codex, and Cursor has Role + Shared contract + Fallback subsections tied to the same ticket/schema/history artifacts.

## 3. Multi-language applicability — Score: 9/10

**Justification:** It directly addresses Python/Go/Node/C++/C usage in one protocol by making benchmark commands and predictions language-agnostic schema entries. This matches the team’s mixed-language PR reality and does not require per-language core rewrites.

**Evidence from idea.md:**
Languages section explicitly covers Python, Go, Node.js, C++, and C; concrete artifact shows mixed Go/C++ benchmark commands under one JSON contract.

## 4. Long-term maintainability — Score: 6/10

**Justification:** The design is robust to tool churn because Jenkins is the source of truth, but ongoing upkeep is non-trivial: schema evolution, flaky benchmark curation, threshold recalibration, component-map maintenance, and attribution noise management. Sustainable, but operationally heavy.

**Evidence from idea.md:**
Risks mention gaming, benchmark flakiness, schema growth, attribution noise, and stale K8s specs; proposal adds history log plus error-threshold governance.

## 5. Implementation simplicity — Score: 4/10

**Justification:** This is a moderate-to-high effort integration: new schema/contracts, scaffolding and coverage scripts, Jenkins shared-library stages, packing simulation logic, and policy gates. Valuable, but clearly not trivial.

**Evidence from idea.md:**
Infra impact requires new Jenkins stage + shared library methods; proposal includes schema validation, benchmark orchestration, simulation, history writing, and merge blocking.

## 6. Workflow impact — Score: 9/10

**Justification:** It strongly targets active team priorities (density research + earlier perf regression detection) and turns subjective perf claims into measurable PR-time signals. If adopted, it should materially reduce late perf surprises and improve tool-comparison quality.

**Evidence from idea.md:**
Problem section centers on late perf failures; success metrics include ticket adoption, median prediction-error reduction, post-merge regression reduction, and weekly by-tool accuracy reports.

## Weighted total

```
(0.35 × 8) + (0.20 × 8) + (0.10 × 9) + (0.15 × 6) + (0.10 × 4) + (0.10 × 9)
= 2.80 + 1.60 + 0.90 + 0.90 + 0.40 + 0.90
= 7.50
```

**Total: 7.5 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers — Adversarial Hallucination Traps with a Shared Ledger | 24% | Shared pattern of cross-tool artifact + Jenkins enforcement + tool attribution, but different failure mode and artifact (hallucination traps vs perf prediction tickets). |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

If this idea were iterated, the three highest-leverage changes would be:

1. **Define a two-tier rollout path:** Start with required ticket presence + schema + non-blocking reporting, then enable blocking thresholds after baseline variance is measured to reduce adoption friction.
2. **Add benchmark reliability controls:** Introduce per-command stability metadata (sample size, warmup, quarantine state) so flaky benches do not create noisy false gates.
3. **Clarify mixed-tool attribution rules:** Support weighted multi-tool contribution fields in the ticket (not only single authoring/review labels) to improve fairness and analytical value.
