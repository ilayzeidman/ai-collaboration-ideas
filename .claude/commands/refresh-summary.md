---
description: Rebuild ideas/SUMMARY.md from scratch by reading every ideas/idea-*/evaluation.md.
---

Invoke the `idea-evaluator` subagent with the instruction "rebuild SUMMARY from scratch".

The evaluator will:
- Read every `ideas/idea-*/evaluation.md`.
- Regenerate `ideas/SUMMARY.md` end-to-end: header counters, sorted ideas table, themes-covered section.
- Leave all idea and evaluation files untouched.

Use this after manual edits to SUMMARY, after deleting an idea folder, or any time the summary drifts from the evaluation files.

After the subagent returns, report to the user: total ideas counted, average score, and the path to the regenerated file.
