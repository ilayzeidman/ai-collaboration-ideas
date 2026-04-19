# Idea 16: Cross-Tool Review Roulette — Blind Comparative Reviews of the Same Diff

## One-line summary
Route each AI-authored diff to a second AI tool for independent review; compare review quality in a shared ledger to surface per-tool review blind spots.

## Tags
shared-evaluation, cross-tool-routing, anti-coordination, jenkins

## Problem
When a developer reviews AI-authored code, they use one AI tool to assist the review — typically the same tool that wrote the code. This creates a blind spot: a Copilot-authored change reviewed with Copilot's help is unlikely to catch Copilot-specific failure patterns (because the review tool shares the same model biases). The team suspects that different AI tools catch different categories of bugs, but has no data to confirm this.

Furthermore, AI review assistance today is ad-hoc: a developer might paste a diff into Cursor Chat or ask Claude Code to review, but there's no structured comparison. The team can't answer: "Would Claude Code have caught the bug that Copilot missed in review?"

## Proposal
Introduce a review-roulette protocol where every AI-authored PR is independently reviewed by a *different* AI tool than the one that wrote the code:

1. **Assignment:** When a PR with an `AI-Tool: X` trailer is opened, a routing file `.review-roulette/assignments.jsonl` assigns a different tool for review. Assignment rotates fairly across tools.
2. **Review execution:** The assigned tool reviews the diff against the repo's review checklist (`.review-roulette/checklist.yaml`). The checklist includes: correctness, style compliance, performance impact, security, cross-language consistency, and density impact. Reviews are written to `.review-roulette/reviews/<pr>-<tool>.md`.
3. **Comparison:** When both the authoring tool and the reviewing tool have produced output, a scoring script compares their findings: what did the reviewer catch that the author missed? What false positives did the reviewer generate? Results are logged to `.review-roulette/comparison.jsonl`.
4. **Blind spots ledger:** Over time, the comparison log reveals per-tool blind spots: "Copilot misses error-handling issues 40% more than Claude Code." "Cursor catches style violations but misses perf issues." This data feeds into tool routing decisions and instruction files.

## Cross-AI-tool design

### Claude Code
- **Role:** Deep-review specialist. When assigned as reviewer, Claude Code performs a thorough multi-file review using its agentic terminal mode, running tests and checking cross-file impacts. A custom command (`/.claude/commands/review-roulette.md`) loads the diff and checklist and produces a structured review. Also generates the weekly blind-spot analysis.
- **Shared contract it reads/writes:** Reads PR diffs and `.review-roulette/checklist.yaml`. Writes reviews to `.review-roulette/reviews/`. Writes blind-spot analysis.
- **Fallback if unavailable:** Its review slot is marked "skipped". Comparison runs with available reviews. Human review is always required alongside.

### GitHub Copilot
- **Role:** Fast-review specialist. When assigned, Copilot reviews using `.github/prompts/review-roulette.prompt.md` — a structured review prompt against the checklist. Copilot Coding Agent can be tasked with reviewing a diff and producing a structured review file. Copilot's speed makes it ideal for the initial fast-pass review.
- **Shared contract it reads/writes:** Reads diff and checklist. Writes review file.
- **Fallback if unavailable:** Slot skipped. Other tools and human review cover.

### Codex
- **Role:** Deterministic review executor. `AGENTS.md` includes a review task template. When assigned, Codex reviews the diff against each checklist item systematically, producing a yes/no/concern per item. Its deterministic nature provides the most consistent review baseline.
- **Shared contract it reads/writes:** Reads diff, checklist, and `AGENTS.md`. Writes structured review.
- **Fallback if unavailable:** Slot skipped.

### Cursor
- **Role:** IDE-context-rich reviewer. When assigned, Cursor reviews using `.cursor/rules/review-roulette.mdc` and the full IDE context (not just the diff, but surrounding code). A custom command `/review-roulette` loads the assignment and produces a review. Cursor's IDE context gives it an advantage on context-dependent issues.
- **Shared contract it reads/writes:** Reads assignment, diff, checklist. Writes review file.
- **Fallback if unavailable:** Slot skipped.

## Languages affected
Language-agnostic protocol. The review checklist includes per-language sections (Go error handling, C++ memory management, Python type hints, Node.js async patterns, C null checks). Reviews are structured consistently regardless of the code's language. Most valuable for cross-language PRs where different tools may have different language-specific strengths.

## Infra impact
- **Jenkins:** Optional stage `review-roulette-assign` runs on new AI-authored PRs to assign a reviewer tool and create the assignment record. No blocking — reviews are advisory alongside human review. Comparison scoring runs weekly as a scheduled job.
- **Kubernetes:** No runtime impact.
- **Density/perf research:** Indirect — the review checklist includes a "density impact" item, so review quality data includes density-relevant findings. Tools that consistently miss density issues are identified.

## Concrete artifact

`.review-roulette/checklist.yaml`:
```yaml
checklist:
  - id: correctness
    description: "Does the code do what the PR description claims?"
    weight: 3
  - id: error-handling
    description: "Are all error paths handled? (Go: wrapped errors, C++: RAII, Python: try/except)"
    weight: 2
  - id: perf-impact
    description: "Could this change regress latency, RSS, or pod density?"
    weight: 2
  - id: security
    description: "Any injection, overflow, or auth bypass risks?"
    weight: 2
  - id: cross-lang-consistency
    description: "If touching a cross-language boundary, are both sides updated?"
    weight: 1
  - id: density-impact
    description: "Does this change allocation patterns, image size, or resource requests?"
    weight: 2
```

`.review-roulette/reviews/4850-claude-code.md`:
```markdown
# Review Roulette: PR #4850 — Reviewed by claude-code

**Author tool:** copilot
**Reviewer tool:** claude-code

| Checklist item | Finding | Severity |
|---|---|---|
| correctness | PASS — logic matches PR description | — |
| error-handling | CONCERN — new Go handler at line 42 returns nil error on partial write | medium |
| perf-impact | CONCERN — dynamic slice allocation in hot path may increase RSS by ~5% | high |
| security | PASS | — |
| cross-lang-consistency | N/A — single-language change | — |
| density-impact | CONCERN — see perf-impact; may affect @mem-budget on AllocBurstPool | high |
```

`.review-roulette/comparison.jsonl`:
```jsonl
{"pr":4850,"author_tool":"copilot","reviewer_tool":"claude-code","author_findings":1,"reviewer_findings":3,"reviewer_unique":["error-handling:medium","perf-impact:high","density-impact:high"],"author_unique":[]}
```

## Success metric
- ≥80% of AI-authored PRs receive a cross-tool roulette review within 8 weeks of adoption.
- The comparison ledger identifies at least 3 statistically significant per-tool blind spots within one quarter (e.g., "Tool X misses error-handling issues 40% more often").
- At least one instruction-file update per month is informed by blind-spot data.
- Developer review time decreases by 15% when roulette reviews pre-flag issues, measured by PR review duration.

## Risks & failure modes
- **Review noise:** Tools may generate many low-value findings. Mitigated by the weighted checklist and severity filters.
- **Adoption friction:** Developers may ignore roulette reviews. Mitigated by surfacing only high-severity unique findings (not all findings).
- **Tool availability:** Not all tools may be available for review on every PR. Mitigated by graceful degradation — partial reviews are still valuable.
- **Bias in comparison:** The comparison is only meaningful if the checklist is well-calibrated. Mitigated by iterating the checklist based on team feedback.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) evaluates per-tool hallucination; idea 14 (Tool Confidence Calibration) tracks confidence accuracy. This idea evaluates per-tool *review* quality — what each tool catches and misses when reviewing (not authoring) code. Overlap with idea 14: ~20% (both evaluate tool quality). Overlap with idea 2: ~15% (both provide per-tool scorecards). The surface is different: authoring quality vs. review quality.

**Versus common industry proposals:**
The tired-ideas list includes "Reinvented code review bot — 'an agent that leaves review comments' without a new protocol, rubric, or coordination mechanism." This idea explicitly includes a new protocol (roulette assignment), a new rubric (structured checklist), and a new coordination mechanism (cross-tool comparison with blind-spot discovery). It's not "AI reviews code" — it's "AI tools review each other's code to discover per-tool blind spots." It satisfies heuristics #1 (new inter-tool interface: the roulette protocol), #2 (capability asymmetry: each tool reviews differently), #7 (shared evaluation surface: blind-spot ledger compares all tools), and #8 (anti-coordination: tools check each other's work).
