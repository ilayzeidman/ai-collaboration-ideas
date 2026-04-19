# Evaluation: Idea 18 — Stale Context Detector — Flag When AI Assumptions Become Invalid Post-Merge

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

**Justification:** "Assumption validity watching" for AI-generated code is a genuinely new concept. No current tool records what assumptions were made during code generation and then monitors whether those assumptions remain valid. This turns context staleness — a uniquely AI-workflow failure mode — into a detectable, alertable signal. Hits heuristics #1, #6, #8. Clearly not in the tired-ideas list.

**Evidence from idea.md:** The assumption recording format, the watcher job, and the invalidation alert mechanism are all specific innovations. The problem statement identifies a failure class unique to AI-assisted development.

**Hard cap check:** Overlap with idea 4: ~15%, idea 9: ~15%. Both below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 7/10

**Justification:** All tools have recording roles. The assumption format is simple YAML. The watcher is tool-independent. Main concern: tools may not consistently record detailed assumptions — the quality and granularity of assumptions will vary significantly across tools. Graceful degradation is good (watcher works with partial data).

**Evidence from idea.md:** Four per-tool subsections. YAML format is universal. Watcher is centralized in Jenkins.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Assumptions are about code facts in any language. The watcher uses language-appropriate validation (AST parsing for signatures, grep for values). All five languages are covered.

**Evidence from idea.md:** Example assumptions span Go signatures, YAML config, and C++ struct layouts. Watcher adapts to each language.

## 4. Long-term maintainability — Score: 7/10

**Justification:** Self-cleaning via 30-day expiry and archive on code modification. Watcher is a simple post-merge job. Main cost: tuning alert sensitivity and managing assumption quality. No complex infrastructure.

**Evidence from idea.md:** Risks address friction, alert fatigue, and false invalidations with mitigations. Auto-expiry prevents rot.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: assumption schema, per-tool recording integration, watcher job (signature comparison, config value checking, AST parsing for some languages), GitHub issue creation, archive logic. The watcher's fact-checking logic varies by assumption type. ~2-3 weeks.

**Evidence from idea.md:** Watcher must validate multiple assumption types (signatures, config values, API shapes) using different techniques.

## 6. Workflow impact — Score: 7/10

**Justification:** Catches a real and growing failure class (stale AI assumptions). As AI tool usage increases, so does the risk of stale assumptions causing silent bugs. Indirect density-research benefit through catching stale allocator assumptions. Impact scales with AI adoption.

**Evidence from idea.md:** Success metrics target ≥5 invalidated assumptions caught per month and zero stale-assumption bugs in production.

## Weighted total

```
(0.35 × 9) + (0.20 × 7) + (0.10 × 9) + (0.15 × 7) + (0.10 × 5) + (0.10 × 7)
= 3.15 + 1.40 + 0.90 + 1.05 + 0.50 + 0.70
= 7.7
```

**Total: 7.7 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 4 | Conflict Forecast Matrix | 15% | Both address multi-tool coordination, but idea 4 is pre-work intent and idea 18 is post-merge validity. |
| 9 | Context Handoff Protocol | 15% | Both deal with context, but idea 9 transfers mid-task context and idea 18 watches for post-merge staleness. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Auto-record assumptions from tool context:** Instead of requiring explicit recording, infer assumptions from the tool's file reads during the session — if the tool read `alloc.go:42` and then generated code calling `AllocBurstPool`, auto-record the signature as an assumption.
2. **Prioritize assumptions by fragility:** Track which files change most frequently and prioritize watching assumptions about those files. This focuses alerts where invalidation is most likely.
3. **Link to CI test coverage:** When an assumption is invalidated, check whether the dependent code is covered by tests that would catch the breakage. If covered, lower the alert severity; if uncovered, raise it to critical.
