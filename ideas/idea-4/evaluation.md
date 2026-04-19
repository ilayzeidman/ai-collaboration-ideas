# Evaluation: Idea 4 — Conflict Forecast Matrix — Predict Multi-Tool File-Edit Collisions Before They Happen

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

**Justification:** Advisory intent-lock registries for AI tools are not a common industry pattern; traditional VCS locking is binary and blocking, not multi-tool-aware and advisory. However, the concept of "declare before you edit" is well-understood in distributed systems. The novelty is in applying it specifically to cross-AI-tool coordination with per-tool registration semantics. Hits heuristics #1 (new inter-tool interface) and #8 (anti-coordination).

**Evidence from idea.md:** Proposal defines `.intent-locks/active.jsonl` with per-tool registration, collision logging, and advisory Jenkins gate. Originality statement distinguishes from traditional file locks.

**Hard cap check:** Overlap with idea 2: ~15%, idea 3: ~10%. Both below 30% threshold. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All four tools have concrete, capability-respecting roles. The shared artifact is a simple jsonl file. Claude Code and Codex register at session start; Copilot registers at PR creation; Cursor warns in IDE. Each has a CLI fallback. The Jenkins gate is the universal backstop. Minor concern: inline Copilot completions can't easily auto-register, but the prompt file and pre-commit hook address this.

**Evidence from idea.md:** Four per-tool subsections with Role, Shared contract, and Fallback. CLI scripts as universal degradation path.

## 3. Multi-language applicability — Score: 10/10

**Justification:** Entirely language-agnostic — tracks file paths, not language constructs. Works identically across Go, Python, Node.js, C++, C, YAML, and Groovy files.

**Evidence from idea.md:** Languages section explicitly states language-agnostic design; example shows Go, YAML, and test files in one lock.

## 4. Long-term maintainability — Score: 7/10

**Justification:** The registry is self-cleaning (TTL expiration + cron GC). No schema evolution pressure — records are simple. Main maintenance cost is tuning the advisory threshold and managing false positives. Survives tool churn because the contract is just file I/O.

**Evidence from idea.md:** Risks section addresses stale locks, over-registration, and race conditions with concrete mitigations.

## 5. Implementation simplicity — Score: 7/10

**Justification:** Core implementation is straightforward: a shell script to register, a shell script to check, a Jenkins stage to compare. No complex infrastructure. The main effort is integrating registration into each tool's rule files and ensuring adoption.

**Evidence from idea.md:** Concrete artifacts are a bash script, a jsonl file, and a short Jenkins stage.

## 6. Workflow impact — Score: 6/10

**Justification:** Prevents wasted work from merge conflicts, which is real but not the team's top pain point. Indirect density-research benefit (prevents wasted perf-research PRs). Does not directly advance density or perf regression detection — the team's active research threads.

**Evidence from idea.md:** Success metrics target merge conflict reduction and adoption rate, not density or perf outcomes directly.

## Weighted total

```
(0.35 × 7) + (0.20 × 8) + (0.10 × 10) + (0.15 × 7) + (0.10 × 7) + (0.10 × 6)
= 2.45 + 1.60 + 1.00 + 1.05 + 0.70 + 0.60
= 7.4
```

**Total: 7.4 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 15% | Both use append-only jsonl registries and Jenkins gates, but for entirely different purposes (hallucination detection vs collision prevention). |
| 3 | Perf Witness Tickets | 10% | Both are pre-merge protocols, but one predicts performance and the other prevents file collisions. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Tie collision data to density-research outcomes:** Track whether prevented collisions were on density-critical files, creating a direct link to the team's active research thread and boosting workflow impact.
2. **Add smart scope inference:** Instead of requiring manual file lists, have each tool infer likely-touched files from the task description using the repo's file-dependency graph, reducing registration friction.
3. **Integrate with git worktrees:** For power users running multiple AI tools in parallel worktrees, auto-register intent from worktree creation, eliminating the manual step entirely.
