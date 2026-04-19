# Evaluation: Idea 6 — Drift Sentinel — Continuous Parity Enforcement for AI Rule Files from a Single Source of Truth

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

## 1. Originality — Score: 6/10

**Justification:** Config-as-code generation is a well-known pattern. Applying it to AI rule files is a logical extension rather than a breakthrough. The novelty is in the specific cross-tool parity enforcement (Jenkins gate + per-tool override semantics), but the core mechanism (template rendering from YAML) is familiar. Partially overlaps with idea 2's `render-canary-rules.sh` concept. Hits heuristic #1 (new inter-tool protocol) but weakly.

**Evidence from idea.md:** The originality statement acknowledges the overlap with idea 2's rendering pattern and with general config-as-code. The YAML→multi-file generation is the standard approach.

**Hard cap check:** Overlap with idea 2: ~25% (shared rendering concept). Below 30% threshold, but close. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 9/10

**Justification:** This is perhaps the most feasible cross-tool idea possible — it directly addresses the instruction-file parity principle from `cross-tool-principles.md`. All four tools have clear roles. The generated files are exactly the files each tool already reads. The Jenkins gate is trivial. Per-tool overrides respect capability asymmetries.

**Evidence from idea.md:** Four per-tool subsections show tool-appropriate roles. The `source.yaml` schema includes per-tool overrides. Jenkins gate and pre-commit hook provide universal enforcement.

## 3. Multi-language applicability — Score: 8/10

**Justification:** The *protocol* is language-agnostic (YAML→markdown). The *content* includes per-language rules for all five team languages. The value scales with the number of languages because more languages means more rules that need cross-tool parity.

**Evidence from idea.md:** `source.yaml` excerpt shows `per_language` sections for Go and C++. Languages section notes all five languages have per-language convention rules.

## 4. Long-term maintainability — Score: 8/10

**Justification:** Self-enforcing by design — the Jenkins gate blocks drift automatically. Template maintenance is low (markdown injection). The main long-term cost is keeping `source.yaml` well-structured as rules grow, but the list-of-independent-blocks structure mitigates merge conflicts. Survives tool churn: if a fifth AI tool is added, only a new template is needed.

**Evidence from idea.md:** Risks section addresses template complexity and merge conflicts. The "add a new template" extensibility model is clean.

## 5. Implementation simplicity — Score: 8/10

**Justification:** Core implementation is a bash/Python script that reads YAML and writes four markdown files, plus a Jenkins stage that diffs outputs. The templates are straightforward. Pre-commit hook is a one-liner calling the render script with `--check`. One to two days of work for a working prototype.

**Evidence from idea.md:** Concrete artifacts are a YAML file, a render script, a header comment, and a short Jenkins stage. No complex infrastructure.

## 6. Workflow impact — Score: 7/10

**Justification:** Directly eliminates a documented pain point (instruction drift, called out in `cross-tool-principles.md`). Ensures density-research rules and conventions propagate consistently. However, the impact is on tool consistency rather than directly on code quality or density research.

**Evidence from idea.md:** Success metrics target zero drift incidents and atomic rule propagation. Problem section cites real drift examples.

## Weighted total

```
(0.35 × 6) + (0.20 × 9) + (0.10 × 8) + (0.15 × 8) + (0.10 × 8) + (0.10 × 7)
= 2.10 + 1.80 + 0.80 + 1.20 + 0.80 + 0.70
= 7.4
```

**Total: 7.4 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 25% | Idea 2 includes `render-canary-rules.sh` for generating canary blocks across four files. This idea generalizes that pattern to all rules. |
| 3 | Perf Witness Tickets | 5% | Minimal overlap — perf tickets are a different artifact. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Add semantic diffing, not just text diffing:** Instead of blocking on any text difference, diff the *semantic content* of rules (ignoring formatting, ordering). This reduces false positives from template reformatting.
2. **Include rule-effectiveness telemetry:** Track which rules are actually cited by tools in their outputs (via commit trailers or inline references), surfacing rules that no tool ever applies so they can be pruned.
3. **Support conditional rules:** Allow `source.yaml` rules to be conditional on branch patterns or directory paths, enabling density-research-specific rules that only activate in relevant paths. This increases precision and reduces rule-file bloat.
