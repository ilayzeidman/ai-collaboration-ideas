# Evaluation: Idea 19 — Diff Provenance Chain — Per-Hunk Tool Attribution in AI-Authored Diffs

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

**Justification:** Per-hunk AI tool attribution with prompt tracking and a pre-merge stripping workflow is genuinely novel. Git blame tracks human authors; no tool tracks AI tool provenance at hunk level. The stripping workflow (annotations during dev → record → strip before merge) is an elegant lifecycle design. Hits heuristics #1, #2, #6, #7.

**Evidence from idea.md:** The provenance annotation format, ledger, stripping workflow, and review routing are all specific innovations.

**Hard cap check:** Overlap with idea 2: ~20%, idea 14: ~20%. Both below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 6/10

**Justification:** All tools have roles, but the annotation compliance challenge is significant — especially for Copilot inline completions, which can't easily prepend comments. Coding Agent mode and other agentic modes can annotate, but inline completion is the highest-volume source. The "unknown" fallback degrades the data quality. Stripping workflow requires careful implementation.

**Evidence from idea.md:** Copilot inline completions require post-hoc annotation. The prompt file for bulk annotation is a workaround. Coding Agent and other agentic modes can annotate natively.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Language-agnostic annotation using each language's comment syntax. The protocol works identically across all five languages. Stripping script must handle five comment syntaxes but that's straightforward.

**Evidence from idea.md:** Annotation format adapts to each language's comment syntax. Ledger is language-agnostic.

## 4. Long-term maintainability — Score: 7/10

**Justification:** The ledger is append-only and auto-populated by the stripping step. No ongoing curation needed beyond maintaining the stripping script. The annotation format is simple and stable. Main risk: annotation compliance may degrade over time.

**Evidence from idea.md:** Risks address compliance, noise, and stripping errors.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: annotation format definition, per-language comment parsing, stripping script with sandboxed verification, ledger recording, per-tool custom commands/prompts, IDE overlay for Cursor. The stripping + verify step is the most delicate piece. ~2-3 weeks.

**Evidence from idea.md:** Stripping requires compile + test verification. Per-language comment parsing needed. IDE overlay for Cursor.

## 6. Workflow impact — Score: 6/10

**Justification:** Review routing based on hunk-level provenance is valuable but requires behavioral change from reviewers. The data enables finer-grained tool quality analysis. Indirect density benefit through better regression attribution. Impact is analytical more than immediately operational.

**Evidence from idea.md:** Success metrics target review time reduction and per-tool insights.

## Weighted total

```
(0.35 × 8) + (0.20 × 6) + (0.10 × 9) + (0.15 × 7) + (0.10 × 5) + (0.10 × 6)
= 2.80 + 1.20 + 0.90 + 1.05 + 0.50 + 0.60
= 7.1
```

**Total: 7.1 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 20% | Shared tool attribution concept, but idea 2 is per-commit and idea 19 is per-hunk. |
| 14 | Tool Confidence Calibration | 20% | Both annotate AI-authored code, but with different metadata (provenance vs confidence). Complementary. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Use git notes instead of inline comments:** Instead of code annotations that need stripping, store provenance metadata in `git notes` attached to commit hunks. This eliminates the stripping step entirely and keeps the code clean during development.
2. **Merge with idea 14 into a unified hunk metadata protocol:** Combine provenance (tool + prompt) and confidence (score + category) into a single annotation line, reducing annotation burden and creating a richer per-hunk metadata record.
3. **Auto-detect provenance from tool behavior:** Instead of requiring tools to self-annotate, infer provenance from editor telemetry (which tool was active when each hunk was written). This removes the compliance challenge for inline completions.
