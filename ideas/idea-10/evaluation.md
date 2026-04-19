# Evaluation: Idea 10 — Dependency Alibi Log — Append-Only Attribution for AI-Suggested Dependencies

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

**Justification:** Dependency audit tools exist (Dependabot, Snyk), but recording *attribution and rationale* for AI-suggested dependencies in a cross-tool-shared ledger is novel. The combination of "why was this added" + "which AI suggested it" + "what alternatives existed" doesn't exist in current tooling. Hits heuristics #1 and #6. Not in the tired-ideas list.

**Evidence from idea.md:** The alibi log format captures rationale, alternatives, and tool attribution — fields no existing dependency tool records. Originality statement distinguishes from vulnerability scanners.

**Hard cap check:** Overlap with idea 2: ~15% (shared attribution ledger pattern). Below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All four tools have clear roles. The shared artifact is a simple JSONL file. Jenkins gate is trivial. Per-tool integration is lightweight (rule file directives + custom commands). Graceful degradation is strong (CLI script + Jenkins gate).

**Evidence from idea.md:** Four per-tool subsections with differentiated roles. CLI fallback. Jenkins blocking gate.

## 3. Multi-language applicability — Score: 8/10

**Justification:** Covers all five language ecosystems (npm, Go modules, pip, Conan, apt). Lock file detection is per-ecosystem. The alibi protocol is ecosystem-agnostic. C/C++ coverage is weaker due to less standardized lock files, hence not 10.

**Evidence from idea.md:** Languages section lists all five ecosystems. Example shows Go and npm alibis.

## 4. Long-term maintainability — Score: 7/10

**Justification:** Append-only log is simple to maintain. No schema evolution pressure. Main cost is ensuring alibi quality and managing log growth over years. Direct-dependency-only scoping keeps volume manageable.

**Evidence from idea.md:** Risks address quality, friction, and transitive churn with concrete mitigations.

## 5. Implementation simplicity — Score: 7/10

**Justification:** Core is a JSONL file, a CLI recording script, and a Jenkins diffstat comparison. Per-tool custom commands are lightweight. The lock-file-change detection in Jenkins is straightforward. ~1-2 weeks.

**Evidence from idea.md:** Concrete artifacts are a JSONL file, a Jenkins stage, and a CLI script.

## 6. Workflow impact — Score: 6/10

**Justification:** Reduces post-incident audit time significantly, but incidents are infrequent. Per-tool dependency quality data is valuable for tool evaluation. Indirect density benefit via size-impact tracking. Not directly tied to density research or perf regression.

**Evidence from idea.md:** Success metrics target audit time reduction and per-tool quality measurement.

## Weighted total

```
(0.35 × 7) + (0.20 × 8) + (0.10 × 8) + (0.15 × 7) + (0.10 × 7) + (0.10 × 6)
= 2.45 + 1.60 + 0.80 + 1.05 + 0.70 + 0.60
= 7.2
```

**Total: 7.2 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 15% | Shared pattern of append-only attribution ledger + Jenkins gate, but for different domains (hallucination vs dependency decisions). |
| 3 | Perf Witness Tickets | 5% | Minimal overlap — different surfaces entirely. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Auto-populate from tool output:** Instead of requiring manual alibi authoring, parse the AI tool's suggestion context (chat log, completion context) to auto-fill rationale and alternatives fields. This removes the biggest adoption friction.
2. **Add a "dependency health dashboard" from the log:** Aggregate alibis to show trends: which tools suggest the most dependencies, which ecosystems have the most CVE-at-addition hits, which rationale patterns correlate with later problems.
3. **Integrate with Dependabot/Snyk alerts:** When a dependency triggers a security alert, auto-link it to its alibi record, immediately showing who suggested it, why, and what alternatives existed — making the alibi log directly actionable in incident response.
