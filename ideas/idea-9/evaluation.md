# Evaluation: Idea 9 — Context Handoff Protocol — Structured Session Transfer Between AI Tools

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

**Justification:** The idea explicitly distinguishes itself from "naïve AI memory" by being task-scoped, structured, and branch-bound. Structured session state transfer between AI tools is not a common pattern — tools today don't interoperate this way. However, "save and restore context" is a general concept. The novelty is in the specific cross-tool, YAML-based, repo-committed protocol. Hits heuristics #1 and #8.

**Evidence from idea.md:** Proposal defines a specific YAML schema with task-relevant sections (decisions, dead ends, remaining work). Originality statement explicitly distinguishes from tired "memory" ideas.

**Hard cap check:** Overlap with idea 4: ~15%. Below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All four tools have clear write/read roles. The artifact is plain YAML in the repo — universally accessible. Each tool has custom commands/prompts for generation. Graceful degradation is excellent: manual YAML creation works fine. No tool-specific dependency.

**Evidence from idea.md:** Four per-tool subsections with differentiated generation mechanisms. Template YAML for manual fallback.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Fully language-agnostic protocol. Handoffs track files and diffs regardless of language. Most valuable for cross-language tasks where context is richest.

**Evidence from idea.md:** Languages section notes applicability to all five languages. Example shows Go/C++/YAML cross-language task.

## 4. Long-term maintainability — Score: 8/10

**Justification:** Low maintenance: the protocol is simple YAML files that are auto-archived on merge. No schema evolution pressure — the YAML structure is stable. No CI integration needed. Cleanup is automated.

**Evidence from idea.md:** Risks address handoff rot (mitigated by archive) and quality variance (mitigated by template). No complex infrastructure.

## 5. Implementation simplicity — Score: 8/10

**Justification:** Very simple: a YAML template, per-tool commands/prompts to generate it, and an archive script. No Jenkins stage, no complex scoring. One-week implementation.

**Evidence from idea.md:** Concrete artifact is a single YAML file. Per-tool integration is a custom command/prompt each.

## 6. Workflow impact — Score: 7/10

**Justification:** Addresses a real pain point (context loss on tool switch) that costs 10-15 minutes per occurrence. Frequency depends on tool-switching habits. Indirect density-research benefit for multi-session research tasks. Not directly tied to density or perf regression.

**Evidence from idea.md:** Success metrics target 70% time reduction and 30% adoption. Developer survey-based measurement.

## Weighted total

```
(0.35 × 7) + (0.20 × 8) + (0.10 × 9) + (0.15 × 8) + (0.10 × 8) + (0.10 × 7)
= 2.45 + 1.60 + 0.90 + 1.20 + 0.80 + 0.70
= 7.7
```

**Total: 7.7 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 4 | Conflict Forecast Matrix | 15% | Both coordinate multi-tool work, but at different lifecycle points (pre-work intent vs mid-work state transfer). |
| 2 | Canary Identifiers | 5% | Minimal overlap — different domains entirely. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Add auto-generation from git state:** Instead of requiring the tool to summarize the session, auto-populate the handoff from git diff, recently opened files, and commit messages, reducing the generation burden to confirming/editing the draft.
2. **Include a "confidence map":** For each file touched, record the tool's confidence in its changes (high/medium/low). This helps the receiving tool prioritize what to re-examine vs. what to trust.
3. **Tie handoffs to perf-witness tickets:** If the task involves density-critical code, link the handoff to the perf-witness ticket (idea 3), ensuring performance context transfers alongside code context.
