---
mode: agent
description: Generate one novel cross-AI-tool idea, evaluate it, and update the summary. Equivalent to Claude Code's /new-idea.
---

You are running the full generate-then-evaluate cycle for one new idea in this repo. You will produce three file modifications in one pass.

## Phase 1 — Required reading

Read these files before drafting anything:

- `ideas/SUMMARY.md`
- `context/team-stack.md`
- `context/ai-tools.md`
- `context/cross-tool-principles.md`
- `context/originality-guide.md`
- `templates/idea.template.md`
- `templates/evaluation.template.md`

## Phase 2 — Pre-draft enumeration

Internally list:
- Every theme already covered in `SUMMARY.md` (tags + Themes covered section).
- Every tired idea from `originality-guide.md` you will explicitly NOT propose.
- One or more novelty heuristics from `originality-guide.md` this new idea will satisfy.

## Phase 3 — Generate the idea

1. Determine the next idea number: run `bash scripts/next-idea-num.sh` in the repo root. Call the result `N`.
2. Create `ideas/idea-N/idea.md` following `templates/idea.template.md` exactly. Every section must be populated concretely — no placeholders.
3. Hard rules:
   - The idea must be a shared artifact/protocol, not a tool-specific feature.
   - Assign a named role AND fallback behavior for Claude Code, Copilot, Codex, Cursor.
   - Reject drafts overlapping >30% with existing ideas in `SUMMARY.md`.
   - Reject any tired idea from `originality-guide.md`.
   - One-line summary ≤140 chars; 3–6 lowercase hyphenated tags.

## Phase 4 — Evaluate the idea

Create `ideas/idea-N/evaluation.md` following `templates/evaluation.template.md`. Rubric:

| # | Criterion | Weight |
|---|---|---|
| 1 | Originality | 0.35 |
| 2 | Cross-AI-tool feasibility | 0.20 |
| 3 | Multi-language applicability | 0.10 |
| 4 | Long-term maintainability | 0.15 |
| 5 | Implementation simplicity (10 = trivial) | 0.10 |
| 6 | Workflow impact | 0.10 |

Score each criterion 1–10 integer, with 1–2 sentences of justification citing specific sections of `idea.md`. If thematic overlap with any prior idea exceeds 30%, Originality is capped at 4/10. Compute weighted total to one decimal. Assign verdict: Strong ≥8.0, Promising 6.5–7.9, Derivative 5.0–6.4, Reject <5.0. Do not soften low scores.

## Phase 5 — Update SUMMARY

Edit `ideas/SUMMARY.md`:

- Append a new row to the Ideas table, sorted by idea number ascending:
  ```
  | N | <title verbatim> | <one-line summary verbatim> | X.X | <Verdict> | <tags verbatim> |
  ```
- Update header: `Total ideas: <count>  |  Avg score: <mean to one decimal>  |  Last updated: <today ISO date>`.
- Regenerate the `Themes covered` section. Format: `- <tag>: ideas (N, M, ...)` one line per tag, sorted alphabetically. Include every tag from any row.

## Phase 6 — Report

Report to the user:
- Idea number and title.
- One-line summary.
- Weighted total score and verdict.
- One sentence naming the strongest and weakest rubric criteria.
- Paths: `ideas/idea-N/idea.md`, `ideas/idea-N/evaluation.md`.

Do not modify any other files in the repo.
