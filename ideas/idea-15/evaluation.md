# Evaluation: Idea 15 — Dead Code Bounty Board — Cross-Tool Competition to Safely Eliminate Unused Code

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

**Justification:** Per-language dead code detectors exist, but a cross-tool competitive bounty protocol with structured proof requirements, multi-source verification, and per-tool success scoring is genuinely novel. The "bounty board" framing transforms a maintenance chore into a measurable, gamified cross-tool competition. Hits heuristics #1, #2, #3, #5, #7.

**Evidence from idea.md:** The bounty board, proof-of-non-use requirements, cross-tool verification, and competition scoring are all specific innovations. Not a "generic lint agent."

**Hard cap check:** No prior idea addresses dead code. Highest overlap: idea 13 at ~15%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** Excellent role differentiation: Claude discovers (deep analysis), Copilot claims (fast PR), Codex verifies (deterministic check), Cursor highlights (IDE display). The board is a simple YAML file. Jenkins verification is straightforward. Each tool can participate independently.

**Evidence from idea.md:** Four per-tool subsections with distinct, capability-respecting roles. Board is universally accessible.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Covers all five languages with per-language detection tools. The bounty protocol is language-agnostic. Dead code is a universal problem across the full stack. C++ dead code removal has the highest density impact.

**Evidence from idea.md:** Languages section lists per-language tools. Board entries include language metadata. Cross-language dead code (cgo) is explicitly addressed.

## 4. Long-term maintainability — Score: 7/10

**Justification:** The board is self-cleaning (completed bounties move to history). Discovery can be automated. Main cost is maintaining proof requirements as the codebase evolves and handling false positives. The protocol is self-contained — it only activates for bounty-claim PRs.

**Evidence from idea.md:** Risks address false positives, board staleness, and cross-language dead code with mitigations.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: board schema, per-language discovery scripts, proof verification in Jenkins (call graph + config scan + Helm check), history logging, per-tool scoring. Extended test stage for bounty PRs. ~2-3 weeks.

**Evidence from idea.md:** Multiple verification requirements per bounty. Per-language detection tools need integration.

## 6. Workflow impact — Score: 8/10

**Justification:** Direct density benefit via binary size reduction. Systematic dead code removal reduces CI time, confusion for AI tools, and container image size. The competition framing encourages sustained effort. High long-term value.

**Evidence from idea.md:** Success metrics target 5000 LOC / 500KB removal and 2% image size reduction. Direct pod density improvement.

## Weighted total

```
(0.35 × 8) + (0.20 × 8) + (0.10 × 9) + (0.15 × 7) + (0.10 × 5) + (0.10 × 8)
= 2.80 + 1.60 + 0.90 + 1.05 + 0.50 + 0.80
= 7.7
```

**Total: 7.7 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 13 | Pod Density Regression Bisect | 15% | Both serve density research, but idea 13 root-causes regressions and idea 15 prevents waste via removal. |
| 2 | Canary Identifiers | 10% | Both measure AI tool quality, but through different mechanisms (hallucination traps vs dead code removal success). |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Prioritize bounties by density impact:** Rank board entries by estimated binary size / image size reduction, ensuring the highest-density-impact dead code is removed first.
2. **Add continuous discovery:** Instead of manual board population, run discovery tools nightly in Jenkins and auto-populate the board with high-confidence candidates, keeping a steady pipeline of bounties.
3. **Link to AI context pollution metric:** Measure whether removing dead code improves AI tool suggestion quality (fewer hallucinated references to removed patterns), creating a measurable AI-productivity feedback loop.
