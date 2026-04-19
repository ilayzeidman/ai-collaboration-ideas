# GitHub Copilot — Repo Instructions

This repo hosts a multi-agent system that generates and evaluates novel, cross-AI-tool workflow ideas for the team. When a teammate asks you (Copilot) to generate or evaluate an idea, follow the rules below. They are the same rules Claude Code uses, so both tools produce identical artifacts.

## Before generating or evaluating anything, read:

1. `ideas/SUMMARY.md` — the canonical dedup surface.
2. `context/team-stack.md` — team languages (Python, Go, Node.js, C++, C), Jenkins CI, Kubernetes, density research.
3. `context/ai-tools.md` — capability matrix for Claude Code, Copilot, Codex, Cursor.
4. `context/cross-tool-principles.md` — the four hard rules an idea must satisfy.
5. `context/originality-guide.md` — tired ideas to avoid + novelty heuristics.
6. `templates/idea.template.md` and `templates/evaluation.template.md` — the output schemas.

## Generating a new idea

Use the prompt file `.github/prompts/new-idea.prompt.md` (Copilot Chat in VS Code). The flow is:

1. Determine the next idea number by running `bash scripts/next-idea-num.sh` at the repo root.
2. Draft the idea, following `templates/idea.template.md` exactly. Originality dominates: reject any draft that overlaps >30% with an existing idea in `SUMMARY.md`, any tired idea in `originality-guide.md`, or any idea findable in a blog post from 2023.
3. Write the idea to `ideas/idea-N/idea.md` with every template section populated concretely.
4. Immediately after writing the idea, evaluate it against the rubric in `templates/evaluation.template.md`. Write the evaluation to `ideas/idea-N/evaluation.md`.
5. Update `ideas/SUMMARY.md`: add a sorted row, update `Total ideas`, `Avg score` (mean to one decimal), `Last updated` (today's ISO date), and regenerate the `Themes covered` section from all tags.

## Rules you must not violate

- Copy the one-line summary, title, and tags **verbatim** from `idea.md` into the SUMMARY row.
- Do not soften low scores. A derivative idea scoring 5.8 is `Derivative`, not `Promising`.
- Every idea must assign a named role AND a graceful-degradation behavior to all four tools (Claude Code, Copilot, Codex, Cursor). Missing any tool means the idea fails cross-tool feasibility.
- The idea must be a shared artifact/protocol, not a tool-specific feature.
- Do not modify files outside `ideas/idea-N/` and `ideas/SUMMARY.md` during a single generate+evaluate cycle.

## Refresh the summary

When asked to refresh or rebuild the summary, use `.github/prompts/refresh-summary.prompt.md`. Do not re-score; only reconstruct `SUMMARY.md` from the existing `ideas/idea-*/evaluation.md` files.
