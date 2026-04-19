# Evaluation: Idea 12 — Cross-Language Refactor Choreographer — Coordinated Multi-Service Rename Manifests

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

**Justification:** Cross-language rename coordination via a shared manifest is novel — no existing tool does this. Per-language IDE rename exists but not cross-language. The symbol-link concept is genuinely new. However, the "manifest of linked things + CI check" pattern is used in ideas 5 (FFI boundaries) and this one, reducing the novelty of the mechanism itself. Hits heuristics #1, #5, #8.

**Evidence from idea.md:** The rename manifest format and Jenkins consistency check are specific to this problem. No existing tool coordinates renames across five languages.

**Hard cap check:** Overlap with idea 5: ~25% (shared cross-language registry pattern). Below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All tools have differentiated roles: Claude executes multi-file renames, Copilot provides inline awareness, Codex verifies, Cursor amplifies IDE rename. The manifest is a simple YAML file. Jenkins gate is straightforward.

**Evidence from idea.md:** Four per-tool subsections with capability-appropriate roles. CLI fallback script for manual execution.

## 3. Multi-language applicability — Score: 10/10

**Justification:** This is the most multi-language idea in the repo — it exists precisely because symbols span five languages plus YAML and Groovy. The manifest explicitly maps cross-language naming conventions.

**Evidence from idea.md:** Example manifest shows Go, C++, Python, YAML, and Groovy manifestations for one concept.

## 4. Long-term maintainability — Score: 6/10

**Justification:** The manifest requires active curation: new cross-language links must be added, stale links must be removed when APIs change. Discovery scripts help but don't fully automate. Naming convention handling adds complexity. Moderate ongoing cost.

**Evidence from idea.md:** Risks address staleness and over-specification. Discovery scripts provide partial automation.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: manifest schema, discovery script for cross-language references, per-language rename application logic, Jenkins consistency check, per-tool custom commands. The per-language naming convention handling is the most complex part. ~2-3 weeks.

**Evidence from idea.md:** Concrete artifacts show YAML schema, Jenkins stage, and rename script. Per-language transforms needed.

## 6. Workflow impact — Score: 7/10

**Justification:** Prevents a real and costly failure class (incomplete cross-language renames). The frequency is moderate (~1-2/month), but the impact per event is high (integration breaks). Indirect density-research benefit for allocator renames.

**Evidence from idea.md:** Success metrics target zero rename breaks reaching integration testing.

## Weighted total

```
(0.35 × 7) + (0.20 × 8) + (0.10 × 10) + (0.15 × 6) + (0.10 × 5) + (0.10 × 7)
= 2.45 + 1.60 + 1.00 + 0.90 + 0.50 + 0.70
= 7.2
```

**Total: 7.2 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 5 | FFI Boundary Contracts | 25% | Both track cross-language relationships in a registry, but idea 5 tests data contracts while idea 12 coordinates renames. |
| 4 | Conflict Forecast Matrix | 10% | Both prevent multi-tool collisions, but idea 4 is file-level intent and idea 12 is symbol-level consistency. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Merge with idea 5 into a unified cross-language registry:** The FFI boundary registry and rename manifest track overlapping information. A unified cross-language relationship graph could serve both use cases, reducing duplication and improving discovery.
2. **Auto-generate renames from the manifest:** Instead of just checking consistency, provide a `scripts/apply-cross-rename.sh` that reads the manifest and applies per-language rename tools automatically, making the manifest actionable, not just advisory.
3. **Add rename impact estimation:** Before executing a rename, estimate the blast radius (number of files, number of downstream consumers, deployment count) and surface it to the developer, enabling informed rename decisions.
