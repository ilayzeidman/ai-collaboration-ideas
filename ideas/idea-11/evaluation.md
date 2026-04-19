# Evaluation: Idea 11 — Rollback Fingerprinting — Attribute Production Rollbacks to AI Tool Provenance

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

**Justification:** Attributing production rollbacks to specific AI tools and closing the loop into instruction files is genuinely novel. Generic observability exists, but the commit-trailer → K8s-rollback → attribution-ledger → scorecard → instruction-file pipeline is a new inter-tool feedback mechanism. Hits heuristics #1, #3, #4, #6, #7. Explicitly not a generic metrics dashboard.

**Evidence from idea.md:** The proposal defines a full attribution pipeline from K8s rollout events to versioned scorecards to instruction-file updates. The feedback loop (production failure → tool behavior change) is the distinctive mechanism.

**Hard cap check:** Overlap with idea 2: ~20% (shared `AI-Tool:` trailer pattern). Below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 7/10

**Justification:** All four tools have roles, but the roles are asymmetric: Claude Code does the heavy analysis, while the others are primarily consumers of scorecard data. This is acceptable per cross-tool principles (capability-aware routing), but the consuming tools' behavior change depends on instruction-file updates, which is indirect.

**Evidence from idea.md:** Four per-tool subsections. Claude Code generates; others consume. Instruction files propagate the feedback.

## 3. Multi-language applicability — Score: 8/10

**Justification:** Attribution is per-component spanning all languages. Scorecards break down by language. Insights are multi-language ("tool X is fragile in Go but reliable in Python"). The value scales with language diversity.

**Evidence from idea.md:** Ledger records include language arrays. Scorecard example shows per-language breakdown.

## 4. Long-term maintainability — Score: 7/10

**Justification:** The ledger is append-only and automated. Scorecards are auto-generated. The main maintenance cost is keeping the `AI-Tool:` trailer convention alive and tuning feedback rules. Feedback rule expiry (2-quarter lifetime) prevents overfitting.

**Evidence from idea.md:** Risks address attribution noise, low volume, and overfitting with concrete mitigations.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: K8s rollout history monitoring, commit-to-trailer correlation, ledger writing, scorecard generation, instruction-file integration. The Jenkins watcher job requires K8s API access. ~2-3 weeks.

**Evidence from idea.md:** Multiple moving parts: Jenkins watcher, K8s API, ledger, scorecard generator, instruction-file updates.

## 6. Workflow impact — Score: 8/10

**Justification:** Directly creates a feedback loop from production failures to AI tool behavior. The density-research connection is strong (rollbacks in density components are the highest-cost failures). Enables data-driven tool selection. High impact when it fires, but depends on rollback frequency.

**Evidence from idea.md:** Success metrics target 20% rollback rate reduction via instruction-file feedback. Time-to-attribution improvement.

## Weighted total

```
(0.35 × 8) + (0.20 × 7) + (0.10 × 8) + (0.15 × 7) + (0.10 × 5) + (0.10 × 8)
= 2.80 + 1.40 + 0.80 + 1.05 + 0.50 + 0.80
= 7.4
```

**Total: 7.4 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 20% | Shared `AI-Tool:` trailer and attribution ledger pattern, but different failure domain (hallucination vs production rollback). |
| 3 | Perf Witness Tickets | 15% | Both relate to performance, but idea 3 predicts pre-merge and idea 11 attributes post-deploy. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Include staging failures, not just prod rollbacks:** Staging rollbacks are more frequent and provide faster signal. Include them with a severity weight to build statistical significance faster.
2. **Auto-generate instruction-file patches from patterns:** Instead of manually interpreting scorecards, have the analysis pipeline propose specific rule-file additions (e.g., "add: always check nil on new Go handler paths") and submit them as PRs via the drift-sentinel system (idea 6).
3. **Add a "reliability gate" for high-rollback components:** When a component's rollback rate exceeds a threshold, require extra review or expanded test coverage for AI-authored changes to that component, creating an automatic risk-proportional gate.
