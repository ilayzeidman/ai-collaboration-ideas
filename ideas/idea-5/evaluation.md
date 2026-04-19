# Evaluation: Idea 5 — FFI Boundary Contracts — AI-Maintained Type-Safety Tests at Cross-Language Call Sites

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

**Justification:** Contract testing exists for service APIs (Pact, etc.), but applying it to in-process FFI boundaries (cgo, ctypes, dlopen) with AI-tool-aware discovery, per-tool roles, and cross-tool registry is genuinely novel. Hits heuristics #1 (new inter-tool interface), #2 (capability asymmetry), #3 (density-research coupling), and #5 (language-stack specificity). Not in the tired-ideas list.

**Evidence from idea.md:** The `.ffi-boundaries/registry.yaml` format and the per-boundary contract test pattern are specific to in-process FFI, not service APIs. The originality statement clearly distinguishes from Pact-style service testing.

**Hard cap check:** Overlap with idea 2: ~10%, idea 3: ~15%. Both below 30%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 8/10

**Justification:** All four tools have concrete roles exploiting capability asymmetries: Claude Code discovers boundaries, Copilot provides inline awareness, Codex runs verification, Cursor warns in IDE. The shared artifact (YAML registry + test files) is universally accessible. Graceful degradation is well-specified with Jenkins as the terminal gate.

**Evidence from idea.md:** Four per-tool subsections with differentiated roles. CLI fallbacks for each tool. Jenkins stage as universal backstop.

## 3. Multi-language applicability — Score: 10/10

**Justification:** This idea is maximally multi-language — it exists because the team uses five languages. Every FFI pair (Go↔C++, Python↔C, Node↔Go, C++↔C) is explicitly covered. The registry itself is language-agnostic YAML.

**Evidence from idea.md:** Registry example shows Go↔C++ and Python↔C boundaries. Languages section covers all five team languages plus their pairwise FFI surfaces.

## 4. Long-term maintainability — Score: 6/10

**Justification:** The registry grows with the codebase and requires active curation. Auto-discovery mitigates this, but new FFI patterns (gRPC, WASM, etc.) may emerge. Contract tests need maintenance when signatures change. Moderate ongoing cost.

**Evidence from idea.md:** Risks section addresses staleness, over-specification, and growth. Auto-discovery scripts provide some automation.

## 5. Implementation simplicity — Score: 4/10

**Justification:** Significant effort: registry schema design, discovery scripts for multiple FFI patterns (cgo, ctypes, child_process, dlopen), contract test generation per boundary type, Jenkins stage, and four tool integrations. Multi-week project.

**Evidence from idea.md:** Concrete artifacts show YAML schema, Jenkins stage, and test files — each requiring implementation. Discovery scripts must parse multiple languages.

## 6. Workflow impact — Score: 8/10

**Justification:** Directly prevents the team's most expensive bug class (cross-language boundary breaks in density-critical code). The cgo boundary between Go services and C++ allocators is the #1 fragile surface in density research. Catching breaks before merge saves days of staging debugging.

**Evidence from idea.md:** Problem section cites "a day lost" per staging segfault. Success metrics target zero boundary breaks reaching staging.

## Weighted total

```
(0.35 × 8) + (0.20 × 8) + (0.10 × 10) + (0.15 × 6) + (0.10 × 4) + (0.10 × 8)
= 2.80 + 1.60 + 1.00 + 0.90 + 0.40 + 0.80
= 7.5
```

**Total: 7.5 / 10.0**

## Originality cross-check

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| 2 | Canary Identifiers | 10% | Both use Jenkins gates and shared repo artifacts, but for different failure modes. |
| 3 | Perf Witness Tickets | 15% | Both touch density-research code and cross-language surfaces, but one predicts perf and the other enforces boundary contracts. |

## Verdict

**Promising** (6.5 – 7.9) — has legs; iterate.

## Top 3 improvements

1. **Start with cgo-only scope:** Ship the registry covering only Go↔C++ cgo boundaries first (the highest-value surface), then expand to ctypes and child-process. This halves implementation effort and delivers value faster.
2. **Auto-generate contract tests from registry entries:** Instead of requiring hand-written tests, generate stub contract tests from the schema declarations in the registry, reducing per-boundary setup cost.
3. **Add boundary-change impact scoring:** When a boundary is modified, estimate the blast radius (number of callers, deployment frequency, density sensitivity) and surface it in the PR review, helping reviewers prioritize.
