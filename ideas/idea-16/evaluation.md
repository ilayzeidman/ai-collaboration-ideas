# Evaluation: Idea 16 — Cross-Tool Review Roulette — Blind Comparative Reviews of the Same Diff

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

**Justification:** Cross-tool comparative review with blind-spot discovery is novel — no current tool does this. The roulette protocol and comparison ledger create a new inter-tool feedback mechanism. However, "AI reviews code" is close to the tired-ideas boundary. The distinguishing factor is the *comparison* — not the review itself but the structured discovery of per-tool blind spots. Hits heuristics #1, #2, #7, #8.

**Evidence from idea.md:** The roulette assignment, structured checklist, and comparison ledger are specific innovations. Originality statement explicitly addresses the tired-ideas boundary.

**Hard cap check:** Overlap with idea 14: ~20%, idea 2: ~15%. Both below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 7/10

**Justification:** All tools have review roles. The checklist and review format are universal. Main concern: triggering a review from a different tool than the one the developer is using requires operational setup (e.g., running Claude Code to review a Copilot PR). The protocol doesn't self-execute — someone must trigger each tool's review. Jenkins can automate for tools with CI integration.

**Evidence from idea.md:** Four per-tool subsections. Graceful degradation with "slot skipped." Human review is always required alongside.

## 3. Multi-language applicability — Score: 8/10

**Justification:** Review checklist includes per-language sections. Protocol is language-agnostic. Most valuable for cross-language PRs where per-tool language strengths differ.

**Evidence from idea.md:** Checklist example shows language-specific items (Go error handling, C++ RAII, Python try/except).

## 4. Long-term maintainability — Score: 7/10

**Justification:** The protocol is self-contained and only activates on AI-authored PRs. Checklist maintenance is needed as team conventions evolve. Comparison logic is simple (diff of findings). Blind-spot analysis requires periodic review to stay actionable.

**Evidence from idea.md:** Risks address noise, adoption, and checklist calibration.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: roulette assignment logic, per-tool review integration (custom commands/prompts for each), comparison scoring script, blind-spot analysis, checklist design. The operational challenge of triggering reviews across tools is the hardest part.

**Evidence from idea.md:** Multiple artifacts: assignment file, review files, comparison log, checklist. Per-tool custom commands/prompts.

## 6. Workflow impact — Score: 7/10

**Justification:** Per-tool blind-spot data informs tool selection and instruction-file updates. Review pre-flagging saves developer time. Density-impact checklist item ensures density issues are caught. Impact is indirect but valuable for long-term tool optimization.

**Evidence from idea.md:** Success metrics target blind-spot identification and review time reduction.

## Weighted total

```
(0.35 × 7) + (0.20 × 7) + (0.10 × 8) + (0.15 × 7) + (0.10 × 5) + (0.10 × 7)
= 2.45 + 1.40 + 0.80 + 1.05 + 0.50 + 0.70
= 6.9
```

**Total: 6.9 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 14 | Tool Confidence Calibration | 20% | Both evaluate tool quality, but idea 14 tracks authoring confidence and idea 16 tracks review quality. |
| 2 | Canary Identifiers | 15% | Both produce per-tool scorecards, but for different failure modes. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Automate review triggering via CI:** Instead of requiring manual review from each tool, use Jenkins to automatically trigger reviews from available tools (Claude via CLI, Codex via task file) on AI-authored PRs, removing the operational burden.
2. **Focus on high-value PRs only:** Route only PRs touching density-critical paths, security-sensitive code, or cross-language boundaries through roulette review, reducing volume and increasing signal-to-noise.
3. **Add a "review accuracy" feedback loop:** When a roulette-flagged concern is later confirmed by a human reviewer or a post-merge issue, update the comparison ledger with a "confirmed" field, enabling calibration of review quality.
