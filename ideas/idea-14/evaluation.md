# Evaluation: Idea 14 — Tool Confidence Calibration — Self-Reported Certainty with Outcome-Based Tracking

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

**Justification:** LLM calibration is studied in academia but not implemented as a cross-tool, in-repo protocol with structured code annotations, CI-based outcome tracking, and per-tool/language/category curves. The confidence-as-code-annotation concept is genuinely new. The feedback loop (confidence → outcome → calibration → routing) doesn't exist in any current tooling. Hits heuristics #1, #2, #6, #7.

**Evidence from idea.md:** The confidence annotation format, calibration curve generation, Brier score tracking, and review-routing based on calibration are all novel mechanisms.

**Hard cap check:** Overlap with idea 2: ~15%, idea 11: ~15%. Both below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 6/10

**Justification:** The protocol depends on all four tools consistently emitting structured confidence comments — a behavioral requirement that may be hard to enforce. Current AI tools don't natively emit confidence scores in code output. The annotation is manual-adjacent (tools must be instructed to produce it). Jenkins outcome tracking works regardless, but the annotation compliance challenge is significant.

**Evidence from idea.md:** The risk section acknowledges annotation compliance. Fallback: unannotated code is "unknown." But the idea's core value requires annotations.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Language-agnostic annotation format. Per-language calibration curves provide cross-language insights. All five languages are independently calibrated. The annotation uses each language's comment syntax.

**Evidence from idea.md:** Five languages covered. Per-language calibration examples. Comment syntax adapts per language.

## 4. Long-term maintainability — Score: 6/10

**Justification:** Ongoing maintenance: calibration curves need regeneration, annotation cleanup must run, outcome tracking requires 30-day lookback. The annotation stripping step adds pipeline complexity. Category taxonomy may evolve. Calibration curves may invalidate when models update.

**Evidence from idea.md:** Risks address compliance, gaming, and measurement complexity. Pre-merge cleanup adds a pipeline step.

## 5. Implementation simplicity — Score: 4/10

**Justification:** Significant effort: annotation parsing across five languages, CI outcome tracking (30-day survival check), calibration curve generation, Brier score computation, annotation cleanup step, per-tool integration, weekly analysis job. Multi-week project.

**Evidence from idea.md:** Multiple pipeline stages, per-language parsers, outcome lookback logic, and calibration statistics.

## 6. Workflow impact — Score: 7/10

**Justification:** Review time reduction on high-confidence hunks is valuable. Tool routing based on calibration data is a strategic win. However, the impact depends on annotation adoption rate and calibration data volume. Indirect density benefit through perf-optimization calibration.

**Evidence from idea.md:** Success metrics target 30% review time reduction and data-driven tool routing.

## Weighted total

```
(0.35 × 9) + (0.20 × 6) + (0.10 × 9) + (0.15 × 6) + (0.10 × 4) + (0.10 × 7)
= 3.15 + 1.20 + 0.90 + 0.90 + 0.40 + 0.70
= 7.3
```

**Total: 7.3 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 15% | Both evaluate AI tools per-tool, but different signals (hallucination vs confidence calibration). |
| 11 | Rollback Fingerprinting | 15% | Both track outcomes, but idea 11 attributes rollbacks and idea 14 calibrates confidence. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Start with PR-level confidence instead of hunk-level:** Instead of per-hunk annotations (high adoption friction), start with a single confidence score per AI-authored PR in a sidecar file. This is easier for tools to emit and still provides useful calibration data.
2. **Use implicit confidence signals:** Instead of requiring explicit annotations, infer confidence from tool behavior: how many iterations did the tool take? Did it self-correct? Did it run tests before submitting? These implicit signals require no annotation compliance.
3. **Gamify calibration:** Publish a weekly "calibration leaderboard" in the repo, showing which tool is best-calibrated per language/category. This creates positive pressure for tools (via instruction-file tuning) to improve calibration.
