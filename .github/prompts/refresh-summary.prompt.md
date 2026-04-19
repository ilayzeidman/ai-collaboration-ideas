---
mode: agent
description: Rebuild ideas/SUMMARY.md from scratch by reading every ideas/idea-*/evaluation.md. No re-scoring.
---

Rebuild `ideas/SUMMARY.md` from scratch. Do not re-score anything; do not modify any `idea.md` or `evaluation.md` file.

## Steps

1. List every `ideas/idea-*/` directory.
2. For each directory that contains both `idea.md` and `evaluation.md`:
   - Read the idea's title, one-line summary, and tags (verbatim) from `idea.md`.
   - Read the weighted total score and verdict from `evaluation.md`.
3. Write `ideas/SUMMARY.md` from scratch:
   - Header:
     ```
     # Ideas Summary

     Total ideas: <count>  |  Avg score: <mean to one decimal>  |  Last updated: <today ISO date>
     ```
   - A one-paragraph note explaining the file's purpose (keep the existing wording if present).
   - The Ideas table header:
     ```
     | # | Title | One-line summary | Score | Verdict | Tags |
     |---|-------|------------------|-------|---------|------|
     ```
   - One row per idea, sorted by idea number ascending.
   - The `Themes covered` section: one line per tag, sorted alphabetically: `- <tag>: ideas (N, M, ...)`.
4. If no idea folders exist or none have evaluations, write the empty-state skeleton with `Total ideas: 0` and `_No ideas yet._` under the Themes section.

## Report

Report to the user: total ideas counted, average score, and the path to the regenerated file.
