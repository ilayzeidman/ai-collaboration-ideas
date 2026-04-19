# Evaluation: Idea 20 — Behavioral Contract Snapshots — API Behavioral Assertions AI Tools Must Preserve

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

**Justification:** Behavioral contracts and property-based testing are known concepts. The novelty is in the specific application: AI-tool-aware contract registry + CI enforcement + AI-driven contract discovery. The idea that AI tools should *read* contracts before modifying code and *discover* new contracts is the creative contribution. Hits heuristics #1, #3, #5, #6. Partially overlaps with idea 5's contract testing concept.

**Evidence from idea.md:** The registry linking functions to behavioral (not type) contracts, and the AI discovery workflow, are specific innovations over standard contract testing.

**Hard cap check:** Overlap with idea 5: ~25% (both use contract tests). Below 30% but close. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All tools have clear roles. The contract registry is a simple YAML file. Contracts are standard test files in each language. Jenkins verification is straightforward. AI enforcement via rule files is well-specified. Contract discovery adds an active role beyond passive compliance.

**Evidence from idea.md:** Four per-tool subsections. Claude discovers, Copilot complies, Codex verifies, Cursor displays. CLI fallbacks for each.

## 3. Multi-language applicability — Score: 9/10

**Justification:** Contracts are written in each function's native language. The registry is language-agnostic. All five languages are covered with specific contract examples. Cross-language contracts are supported.

**Evidence from idea.md:** Examples show Go and Python contracts. Registry covers both. All five languages listed.

## 4. Long-term maintainability — Score: 6/10

**Justification:** Contracts require maintenance when behavior intentionally changes. Over-specification risk adds curation burden. Discovery of new contracts is ongoing work. However, contracts are standard test files with familiar tooling, reducing maintenance friction.

**Evidence from idea.md:** Risks address staleness, over-specification, and discovery false positives.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Moderate effort: registry schema, per-language contract test scaffolding, Jenkins stage with selective contract execution, per-tool rule file integration, discovery command. Most of the "effort" is in writing the initial contract corpus. ~2-3 weeks for infrastructure, ongoing for contracts.

**Evidence from idea.md:** Jenkins stage, registry, per-tool commands. Initial contract authoring is the bulk of effort.

## 6. Workflow impact — Score: 8/10

**Justification:** Prevents a costly failure class (behavioral regressions invisible to type checking and unit tests). Density-relevant allocator contracts directly protect the team's research investment. Contract discovery surfaces previously-invisible invariants, improving code understanding.

**Evidence from idea.md:** Success metrics target zero behavioral regressions on contracted functions. Density-critical allocator contracts explicitly covered.

## Weighted total

```
(0.35 × 7) + (0.20 × 8) + (0.10 × 9) + (0.15 × 6) + (0.10 × 5) + (0.10 × 8)
= 2.45 + 1.60 + 0.90 + 0.90 + 0.50 + 0.80
= 7.2
```

**Total: 7.2 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 5 | FFI Boundary Contracts | 25% | Both use contract tests at code boundaries, but idea 5 tests type safety at FFI sites and idea 20 tests behavioral invariants at API boundaries. |
| 7 | Memory Budget Annotations | 15% | Both specify invariants, but idea 7 is numeric (memory budget) and idea 20 is behavioral (functional properties). |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Auto-generate contracts from existing tests:** Analyze the test suite to identify assertions that function as behavioral invariants, and auto-promote them to contracts. This bootstraps the contract corpus with minimal effort.
2. **Merge with idea 5 for a unified contract system:** FFI boundary contracts (type safety) and behavioral contracts (invariant preservation) could share a registry and CI stage, reducing duplication and providing a single "contract" surface for AI tools.
3. **Add contract coverage metrics:** Track what percentage of density-critical functions have behavioral contracts, and set a target (e.g., 80% coverage within 6 months), creating sustained motivation for contract authoring.
