# Evaluation: Idea 8 — Semantic Merge Arbiter — Multi-Tool Consensus Protocol for Conflict Resolution

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

**Justification:** AI-assisted merge resolution exists in single-tool contexts, but a multi-tool consensus protocol with independent proposals, automated scoring, and cross-tool comparison is genuinely new. The structured conflict→proposal→score→history pipeline creates a novel inter-tool interface. Hits heuristics #1, #2, #7, #8.

**Evidence from idea.md:** The proposal defines a full lifecycle (conflict extraction → independent proposals → scoring → history logging) that doesn't exist in any current tool. The scoring criteria include cross-idea links (mem-budget from idea 7).

**Hard cap check:** Overlap with idea 4: ~20% (both address file conflicts but at different stages). Below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 7/10

**Justification:** All tools have roles, but the protocol requires actively soliciting proposals from multiple tools — operationally heavy for a developer to trigger. The "ask each tool separately" workflow may not be practical in daily use. Scoring automation and Jenkins optional stage mitigate this. Graceful degradation is good (works with 1-4 proposals).

**Evidence from idea.md:** Four per-tool subsections. Fallback: each slot can be empty. Scoring works with any number of proposals.

## 3. Multi-language applicability — Score: 8/10

**Justification:** Protocol is language-agnostic (JSON conflicts, patches). Scoring includes per-language compile/lint/test checks. Works across all five team languages. Most valuable for Go/C++ density conflicts.

**Evidence from idea.md:** Scoring criteria list language-specific checks for all five languages.

## 4. Long-term maintainability — Score: 7/10

**Justification:** Moderate maintenance: scoring criteria may need tuning, and the conflict extraction format must evolve with git merge behaviors. But the protocol is self-contained — it only activates on conflicts. History log provides data for continuous improvement.

**Evidence from idea.md:** Risks cover low volume, quality variance, and overhead. History log enables data-driven improvement.

## 5. Implementation simplicity — Score: 4/10

**Justification:** Significant effort: conflict extraction tool, proposal format, scoring script (compile + test + lint + intent check + mem-budget), per-tool integration (custom commands/prompts), history logging, IDE comparison display. Multi-week project.

**Evidence from idea.md:** Concrete artifacts show conflict JSON, scoring output, and Jenkins stage. Each requires non-trivial implementation.

## 6. Workflow impact — Score: 7/10

**Justification:** Addresses a real pain point (conflict resolution in opaque AI-authored code) but the frequency may be low. When it fires, the impact per event is high (60% time reduction). Indirect density-research benefit through mem-budget-aware scoring.

**Evidence from idea.md:** Success metrics target 60% time reduction and 50% adoption.

## Weighted total

```
(0.35 × 8) + (0.20 × 7) + (0.10 × 8) + (0.15 × 7) + (0.10 × 4) + (0.10 × 7)
= 2.80 + 1.40 + 0.80 + 1.05 + 0.40 + 0.70
= 7.2
```

**Total: 7.2 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 4 | Conflict Forecast Matrix | 20% | Both address multi-tool file conflicts — idea 4 prevents them, idea 8 resolves them. Different lifecycle stages, complementary. |
| 2 | Canary Identifiers | 5% | Minimal overlap — different failure modes entirely. |
| 3 | Perf Witness Tickets | 10% | Both use CI-based verification, but for different purposes. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Automate proposal solicitation:** Instead of requiring the developer to ask each tool, trigger proposals automatically via git hooks when a merge conflict is detected on a file with AI-Tool trailers. This removes the biggest adoption friction.
2. **Add a "fast path" for trivial conflicts:** Single-hunk, whitespace, or import-order conflicts should be auto-resolved without the full protocol, reducing overhead for the common case.
3. **Weight proposal scoring by tool track record:** Use the history log to weight scores by each tool's past resolution success rate on similar files/languages, making the recommendation smarter over time.
