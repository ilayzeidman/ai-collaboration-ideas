# Cross-AI-Tool Principles

Hard rules an idea MUST satisfy to qualify as "cross-AI-tool collaboration". The evaluator uses this file to score `Cross-AI-tool feasibility`. If an idea violates any rule without an explicit, compelling justification, it fails that criterion.

## The four rules

### 1. Shared artifact, not tool-specific feature
The idea's core must be a file, protocol, schema, convention, or CI step that lives in the repo and is consumed identically by every tool. Building on top of one tool's proprietary surface (e.g., "a Claude Code subagent that...") is not cross-tool unless the subagent produces/consumes a shared artifact that the other tools can also read and write.

### 2. Named role for every tool
Every idea must assign a concrete role to Claude Code, GitHub Copilot, Codex, and Cursor. Roles may differ — in fact, differentiation that exploits capability asymmetries is preferred over forced uniformity. But a tool cannot be "not mentioned". If a tool genuinely cannot participate, the idea must state that explicitly and justify it against `context/ai-tools.md`.

### 3. Graceful degradation
For each tool, the idea must describe what happens when that tool is unavailable, turned off, or lacks the capability. The system cannot become broken for a dev just because their teammate uses a different AI. "Works with all four, fails closed if any one is down" is acceptable; "silently produces wrong output if Cursor isn't running" is not.

### 4. Consistent developer experience
Two devs on two different tools working the same task must see materially the same inputs, outputs, and conventions. If the idea introduces divergence — e.g., "Claude users get rich summaries, Copilot users get plain diffs" — that divergence itself must be explicitly accepted as a design choice and justified.

## Anti-patterns (automatic fails)

- **"Use X as the canonical tool and have others mimic it"** — this is a monoculture proposal, not cross-tool collaboration.
- **Instruction drift** — adding rules to only `CLAUDE.md` or only `.cursorrules`. Parity files must be updated together.
- **Agent-framework lock-in** — requiring subagents, MCP, or Composer specifically without a markdown/shell fallback.
- **Invisible coordination** — tools "coordinate" through something a dev can't inspect or version-control.

## Positive patterns

- **Append-only shared logs** that every tool reads and writes (e.g., a jsonl decision log committed to the repo).
- **Capability-aware routing** (e.g., a route file declaring which tool is expected to own which task type).
- **Shared schemas for evaluation/benchmarking** where any tool's output can be scored by the same harness.
- **Parity rule-file generators** that emit synchronized `CLAUDE.md` / `copilot-instructions.md` / `AGENTS.md` / `.cursorrules` from a single source of truth.
