# Idea 14: Tool Confidence Calibration — Self-Reported Certainty with Outcome-Based Tracking

## One-line summary
Require AI tools to emit structured confidence scores on each suggestion; track actual outcomes to build per-tool calibration curves over time.

## Tags
shared-evaluation, cross-tool-routing, shared-protocol, jenkins

## Problem
AI tools present every suggestion with equal confidence. A Copilot completion that's 95% likely correct looks identical to one that's 50% likely correct. A Claude Code refactor that the tool is uncertain about reads the same as one it's confident in. This forces developers to evaluate every suggestion equally, wasting review effort on high-confidence suggestions and under-scrutinizing low-confidence ones.

The team has no data on which tools are well-calibrated (confidence matches actual correctness) and which are overconfident. Without calibration data, there's no way to build trust intelligently or to route work to the tool that's most reliable for a given task type.

## Proposal
Define a confidence annotation protocol that all AI tools must emit alongside their code suggestions:

1. **Confidence format:** Each AI-authored hunk includes a structured comment: `// @ai-confidence: 0.85 tool=copilot category=refactor lang=go`. This is a trailing comment on the first line of each non-trivial hunk, or a block comment before a multi-line change.
2. **Categories:** Predefined categories (new-code, refactor, bug-fix, perf-optimization, config-change, test-addition) allow per-category calibration.
3. **Outcome tracking:** A Jenkins stage `confidence-calibrate` runs on merged PRs. It checks whether each AI-authored hunk (a) passed CI on first try, (b) survived 30 days without revert or significant modification, (c) triggered any rollback (linking to idea 11). Outcomes are recorded in `.confidence/calibration.jsonl`.
4. **Calibration curves:** A weekly script generates per-tool, per-category, per-language calibration curves: "When Copilot says 0.8 confidence on a Go refactor, it's actually correct 72% of the time." These are committed to `.confidence/curves/`.
5. **Actionable output:** Calibration data feeds into tool instruction files and review routing: high-confidence hunks from well-calibrated tools get expedited review; low-confidence hunks get extra scrutiny.

## Cross-AI-tool design

### Claude Code
- **Role:** Calibration analyst and natural high-confidence provider. Claude Code's agentic depth often produces higher-confidence suggestions for complex refactors. A custom command (`/.claude/commands/confidence-report.md`) generates the weekly calibration analysis. `CLAUDE.md` includes the directive: "Annotate every non-trivial code change with `@ai-confidence` score."
- **Shared contract it reads/writes:** Reads `.confidence/calibration.jsonl` and `.confidence/curves/`. Writes confidence annotations in code. Writes calibration analysis reports.
- **Fallback if unavailable:** `scripts/generate-calibration-curves.sh` runs the analysis standalone.

### GitHub Copilot
- **Role:** Highest-volume confidence emitter. Copilot produces the most suggestions (inline completions + Coding Agent PRs), making it the richest data source. `.github/copilot-instructions.md` includes: "Annotate non-trivial code changes with `@ai-confidence` score." Coding Agent PRs must include confidence annotations. `.github/prompts/confidence-annotate.prompt.md` provides a bulk-annotation prompt.
- **Shared contract it reads/writes:** Writes confidence annotations. Reads `.confidence/curves/copilot.json` to self-calibrate.
- **Fallback if unavailable:** Unannotated code is treated as "unknown confidence" and excluded from calibration curves. Jenkins still tracks outcomes.

### Codex
- **Role:** Calibration baseline provider. Codex's task-file determinism makes it the most consistent confidence emitter — same task, same confidence. `AGENTS.md` includes the confidence annotation directive. Codex's calibration curves serve as the reference against which other tools are compared.
- **Shared contract it reads/writes:** Writes confidence annotations per `AGENTS.md`. Reads `.confidence/curves/codex.json`.
- **Fallback if unavailable:** Codex's absence just removes one data source. Other tools' curves are still generated.

### Cursor
- **Role:** IDE confidence display. `.cursor/rules/confidence.mdc` instructs Cursor to display confidence scores prominently when reviewing AI-authored code. A custom command `/confidence-check` overlays calibration data on AI-authored hunks: "This tool says 0.8, but historically it's only 0.65 for this category." Cursor's inline display is ideal for making confidence actionable during review.
- **Shared contract it reads/writes:** Reads confidence annotations and `.confidence/curves/`. Writes confidence annotations during Agent mode.
- **Fallback if unavailable:** Confidence annotations are visible as code comments in any editor.

## Languages affected
Language-agnostic annotation format (structured comment using each language's comment syntax). Calibration curves are per-language: "Copilot at 0.9 confidence in Go is 88% accurate; in C++ it's only 71%." This cross-language calibration data is uniquely valuable for a team that works across five languages. All five languages (Go, Python, Node.js, C++, C) are calibrated independently.

## Infra impact
- **Jenkins:** New stage `confidence-calibrate` runs on merged PRs (not on open PRs). Compares confidence annotations to outcomes (CI pass, 30-day survival, no rollback). Low cost — reads git history and CI results. Weekly calibration curve generation job.
- **Kubernetes:** No runtime impact.
- **Density/perf research:** Indirect benefit — calibration data for perf-optimization category changes is especially valuable, revealing which tool's density suggestions are actually reliable.

## Concrete artifact

Source annotation:
```go
// @ai-confidence: 0.85 tool=copilot category=perf-optimization lang=go
pool := arena.NewPool(arena.WithBurstSize(2 * 1024 * 1024))
```

`.confidence/calibration.jsonl`:
```jsonl
{"commit":"abc123","file":"services/shard/alloc.go","hunk_start":42,"tool":"copilot","confidence":0.85,"category":"perf-optimization","lang":"go","ci_pass":true,"survived_30d":true,"rollback":false,"actual_correct":true}
{"commit":"def456","file":"apps/bff/src/health.ts","hunk_start":15,"tool":"cursor","confidence":0.70,"category":"bug-fix","lang":"nodejs","ci_pass":true,"survived_30d":false,"rollback":false,"actual_correct":false}
```

`.confidence/curves/copilot-go-refactor.json`:
```json
{
  "tool": "copilot",
  "language": "go",
  "category": "refactor",
  "data_points": 142,
  "calibration": [
    {"reported": 0.5, "actual": 0.48, "n": 12},
    {"reported": 0.7, "actual": 0.63, "n": 35},
    {"reported": 0.9, "actual": 0.82, "n": 67}
  ],
  "brier_score": 0.08,
  "verdict": "slightly_overconfident"
}
```

## Success metric
- ≥60% of AI-authored hunks carry confidence annotations within 8 weeks.
- Calibration curves stabilize (Brier score variance < 0.02 between weeks) after 100+ data points per tool/language/category bucket.
- Review time on high-confidence, well-calibrated hunks decreases by 30%, measured by PR review timestamps.
- At least one tool-routing decision per month is informed by calibration data (e.g., "route C++ perf work to the tool with the best calibration for perf-optimization/cpp").

## Risks & failure modes
- **Annotation compliance:** Tools may not consistently emit confidence scores. Mitigated by treating unannotated code as "unknown" and measuring annotation rate separately.
- **Confidence gaming:** Tools may inflate confidence to avoid extra scrutiny. Mitigated by tracking calibration (inflation shows up as overconfidence) and by the 30-day outcome check.
- **Outcome measurement complexity:** "Correct" is hard to define (code may work but be suboptimal). Mitigated by using a simple proxy: CI pass + 30-day survival + no rollback.
- **Annotation noise:** Confidence comments add visual clutter. Mitigated by a pre-merge cleanup step that strips annotations after recording them (they're captured in `calibration.jsonl` before removal).

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) measures hallucination rate; this measures confidence calibration — a different signal (binary trap vs. continuous confidence). Idea 11 (Rollback Fingerprinting) attributes rollbacks; this attributes confidence and tracks whether confidence predicts outcomes. Overlap with idea 2: ~15% (shared per-tool evaluation), idea 11: ~15% (shared outcome tracking). Neither exceeds 30%.

**Versus common industry proposals:**
LLM calibration research exists in academic settings, but applying it as a cross-tool, in-repo protocol with structured annotations, CI-based outcome tracking, and per-tool/language/category calibration curves is novel. This is not a generic metrics dashboard — the curves are versioned artifacts that feed back into tool instruction files and review routing. It satisfies heuristics #1 (new inter-tool interface: confidence protocol), #2 (capability asymmetry: each tool has different calibration), #6 (failure mode as feature: overconfidence becomes measurable), and #7 (shared evaluation surface: same metrics compare all tools).
