---
description: Generate one new idea and evaluate it in a single auto-chained flow.
---

Run the full generate-then-evaluate cycle for one new idea.

Steps:

1. Invoke the `idea-generator` subagent. Wait for it to complete. From its return message, capture the idea number `N`.

2. Immediately invoke the `idea-evaluator` subagent with the instruction "Evaluate `ideas/idea-N/idea.md`" (substituting the captured N). Wait for it to complete.

3. Report to the user:
   - Idea number and title
   - One-line summary
   - Weighted total score and verdict
   - One sentence of rationale from the evaluator's return message
   - Paths to the two written files: `ideas/idea-N/idea.md` and `ideas/idea-N/evaluation.md`

If either subagent fails or produces incomplete output, stop and surface the error to the user instead of proceeding.
