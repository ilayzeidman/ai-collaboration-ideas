# ai-collaboration-ideas

A multi-agent system for generating and evaluating novel, cross-AI-tool workflow ideas for the team. One agent drafts an idea, another scores it on a strict rubric where **originality dominates**, and a living summary file prevents duplication across runs.

The team uses **Claude Code, GitHub Copilot, Codex, and Cursor** across **Python, Go, Node.js, C++, C** with **Jenkins** and **Kubernetes**, plus active research on service density. Every idea must account for all four tools and all five languages.

## How it works

```
/new-idea  ──►  idea-generator  ──►  ideas/idea-N/idea.md
                     │
                     ▼
                idea-evaluator  ──►  ideas/idea-N/evaluation.md
                     │
                     ▼
              ideas/SUMMARY.md  (appended + themes regenerated)
```

One command, full cycle. The generator reads `SUMMARY.md` before drafting to avoid duplicating prior ideas; the evaluator enforces this with a hard originality cap.

## Using the system

### From Claude Code

- `/new-idea` — generate one new idea and evaluate it.
- `/refresh-summary` — rebuild `ideas/SUMMARY.md` from the existing evaluation files.

### From GitHub Copilot (VS Code)

- Run the prompt file `.github/prompts/new-idea.prompt.md` — equivalent to `/new-idea`.
- Run the prompt file `.github/prompts/refresh-summary.prompt.md` — equivalent to `/refresh-summary`.
- `.github/copilot-instructions.md` is auto-loaded by Copilot Chat on this repo.

Both paths produce identical artifacts because they share the same templates, context files, and rubric.

## Folder map

```
.
├── README.md
├── .claude/
│   ├── agents/
│   │   ├── idea-generator.md       # Subagent: drafts new idea
│   │   └── idea-evaluator.md       # Subagent: scores + updates SUMMARY
│   └── commands/
│       ├── new-idea.md             # /new-idea (auto-chained)
│       └── refresh-summary.md      # /refresh-summary
├── .github/
│   ├── copilot-instructions.md     # Repo instructions for Copilot Chat
│   └── prompts/
│       ├── new-idea.prompt.md
│       └── refresh-summary.prompt.md
├── context/
│   ├── team-stack.md               # Languages, Jenkins, K8s, density research
│   ├── ai-tools.md                 # Capability matrix for the four AI tools
│   ├── cross-tool-principles.md    # Hard rules an idea must satisfy
│   └── originality-guide.md        # Tired ideas + novelty heuristics
├── templates/
│   ├── idea.template.md
│   └── evaluation.template.md
├── scripts/
│   └── next-idea-num.sh            # Prints next idea number
└── ideas/
    ├── SUMMARY.md                  # Canonical dedup surface
    └── idea-*/                     # One folder per idea
        ├── idea.md
        └── evaluation.md
```

## Evaluation rubric

| # | Criterion | Weight |
|---|-----------|--------|
| 1 | Originality | 0.35 |
| 2 | Cross-AI-tool feasibility | 0.20 |
| 3 | Multi-language applicability | 0.10 |
| 4 | Long-term maintainability | 0.15 |
| 5 | Implementation simplicity (10 = trivial) | 0.10 |
| 6 | Workflow impact | 0.10 |

Weighted total out of 10. Verdicts: **Strong** ≥8.0, **Promising** 6.5–7.9, **Derivative** 5.0–6.4, **Reject** <5.0. Originality is hard-capped at 4/10 when thematic overlap with any prior idea exceeds 30%.

## Extending the system

- Add tired-idea patterns to `context/originality-guide.md` as the team learns what not to repropose.
- Update `context/team-stack.md` as the language mix, CI, or research threads evolve.
- Update `context/ai-tools.md` when any of the four tools gains or loses a capability.
- If you change the rubric, update both `templates/evaluation.template.md` and the two prompt/command entry points so Claude and Copilot stay in sync.
