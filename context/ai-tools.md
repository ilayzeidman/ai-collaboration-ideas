# AI Tools Capability Matrix

Factual substrate every cross-AI-tool idea must respect. If an idea assumes a capability a tool does not have, it fails feasibility scoring.

## The four tools in use

1. **Claude Code** — Anthropic CLI + IDE integrations. Agentic, terminal-native.
2. **GitHub Copilot** — IDE inline completion + Copilot Chat + Copilot Coding Agent (PR-driven).
3. **Codex** — OpenAI's coding agent (cloud + local runners). Agentic, task-file driven.
4. **Cursor** — IDE (VS Code fork) with Chat, Composer/Agent mode, inline edits.

## Capability matrix

| Capability | Claude Code | Copilot | Codex | Cursor |
|---|---|---|---|---|
| Runs in terminal | Yes (primary) | Via `gh copilot` CLI (limited) | Yes (agent) | Limited |
| Runs in IDE | Yes (VS Code + JetBrains ext) | Yes (primary) | Via IDE extensions | Yes (primary) |
| Writes files autonomously | Yes | Coding Agent only | Yes | Yes (Agent mode) |
| Executes shell commands | Yes | Coding Agent only | Yes | Yes (Agent mode) |
| Subagents / multi-agent | Yes (native) | No first-class | No first-class | No first-class |
| MCP tool-use | Yes (native) | No | No | Yes |
| Repo-level instructions file | `CLAUDE.md`, `.claude/` | `.github/copilot-instructions.md`, `.github/prompts/*.prompt.md` | `AGENTS.md` | `.cursorrules`, `.cursor/rules/*.mdc` |
| Custom slash commands | Yes (`.claude/commands/`) | Prompt files (VS Code) | Task files | Custom commands |
| PR integration | Via MCP GitHub server | First-class (Coding Agent opens PRs) | First-class | Via GitHub CLI/MCP |
| Persistent memory | `CLAUDE.md` + conversation compaction | Custom instructions | `AGENTS.md` | `.cursorrules` + memories |
| Inline completion | No | Yes (primary) | No | Yes |

## Implications for idea design

- **Shared-artifact ideas are portable**: every tool reads markdown, JSON, YAML, and shell output. Ideas built on a shared file format work across all four.
- **Tool-specific agent frameworks are NOT portable**: if an idea depends on Claude Code subagents or Cursor Composer specifically, it fails the cross-tool test unless it degrades to a single-prompt equivalent for the others.
- **Capability asymmetries are opportunities**: Copilot's first-class PR integration + Claude Code's subagent depth + Cursor's IDE tightness + Codex's task-file determinism are complementary. Ideas that route work to the tool best suited for it (rather than forcing uniformity) often score well.
- **Instruction-file parity**: The same guidance must be replicated in `CLAUDE.md`, `.github/copilot-instructions.md`, `AGENTS.md`, and `.cursorrules` to reach all four tools. An idea that introduces instruction drift is a regression.
