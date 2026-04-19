# Originality Guide

Originality is the dominant criterion in this system. An idea that is merely competent but derivative scores lower than an idea that is half-formed but genuinely new. Use this file as both a negative corpus (what to avoid) and a heuristics list (what makes an idea novel).

## Tired ideas — auto-reject

Any variation of these is derivative. The generator must not propose them. The evaluator must cap Originality at 4/10 for any idea that substantively overlaps:

- **"AI that writes better commit messages"** / conventional-commits enforcer / PR title generator.
- **"AI-powered PR summarizer"** / auto-generated PR descriptions / changelog bots.
- **Generic lint or style agents** — "an agent that runs the linter" is not an idea.
- **Generic test generation bots** — "agent that writes unit tests" without a novel surface or interaction model.
- **"AI pair programmer" reframes** — the tools already are this.
- **Reinvented code review bot** — "an agent that leaves review comments" without a new protocol, rubric, or coordination mechanism.
- **Documentation generators** without a novel contract (docstring-from-code, README-from-source, etc.).
- **Chatbots fronting the codebase** — yet another Q&A bot over the repo.
- **Naïve "memory" features** — "remember previous conversation" without a shared protocol that works across tools.
- **Single-tool agent marketplaces** — "a library of Claude Code subagents" is not cross-tool.
- **Generic observability / metrics dashboards** that happen to include AI output.

## Novelty heuristics — score higher if the idea answers YES

1. **New inter-tool interface?** Does the idea propose a protocol, format, or convention that didn't exist before and that multiple tools must conform to?
2. **Capability asymmetry exploited?** Does it route work to whichever tool is best at it (rather than forcing uniformity)?
3. **Density / perf research coupling?** Does it tie AI tooling to the team's active density and perf research, not just generic code tasks?
4. **Jenkins + K8s leverage?** Does it exploit an existing CI or runtime surface the team already owns, instead of introducing new infrastructure?
5. **Language-stack specificity?** Does it make meaningful use of the Py/Go/Node/C++/C mix (e.g., cross-language refactors, FFI boundaries, perf-critical C++ interacting with Go services)?
6. **Failure mode as a feature?** Does it turn a known AI failure mode (hallucination, context loss, divergent suggestions) into something measurable and actionable?
7. **Shared evaluation surface?** Can the same harness compare outputs across tools, creating a factual basis for "which tool is better at X for us"?
8. **Anti-coordination idea?** Does it prevent tools from stepping on each other (e.g., two agents modifying the same file simultaneously) — a class of problem that emerges specifically in multi-tool environments?

## Novelty test

Before committing to an idea, the generator asks: **"Could I have found this exact idea in a blog post from 2023?"** If yes, discard.
