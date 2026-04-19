# Idea 9: Context Handoff Protocol — Structured Session Transfer Between AI Tools

## One-line summary
Define a `.handoff/` directory where each tool writes a structured session summary so developers can switch tools mid-task without losing context.

## Tags
cross-tool-routing, shared-protocol, anti-coordination, developer-experience

## Problem
Developers frequently switch between AI tools mid-task. A developer starts a refactor in Cursor's Composer mode, hits a limitation, and switches to Claude Code's terminal. But Claude Code has zero context about what Cursor was doing — the refactor intent, the files already examined, the approach being taken, the dead ends already explored. The developer must re-explain everything, wasting 10-15 minutes per switch. Worse, the second tool may repeat work or take a conflicting approach because it doesn't know what the first tool already tried.

This is not "AI memory" in the tired-ideas sense (persisting conversations). This is a structured, machine-readable session snapshot that captures *task state* — what was being done, what was decided, what's left — in a format any tool can consume.

## Proposal
Introduce `.handoff/` as a repo directory containing structured session snapshots. When a developer is done with a tool session (or wants to switch), they invoke a "handoff" command that writes a `.handoff/<task-id>.yaml` file containing:

1. **Task description:** What the developer is trying to accomplish.
2. **Files examined:** List of files the tool read, with relevant line ranges.
3. **Changes made:** Diff of changes made so far (may be uncommitted).
4. **Decisions made:** Key decisions and their rationale.
5. **Dead ends:** Approaches tried and abandoned, with reasons.
6. **Remaining work:** What's left to do.
7. **Tool and timestamp:** Which tool created the snapshot.

The receiving tool reads the handoff file as context before starting. The handoff file is committed to the branch so it's available to any tool on any machine. A `.handoff/.gitkeep` ensures the directory exists. Completed handoffs are archived to `.handoff/archive/` on branch merge.

## Cross-AI-tool design

### Claude Code
- **Role:** Handoff writer and reader. A custom command (`/.claude/commands/handoff-write.md`) generates a structured handoff from the current session state. A companion command (`/.claude/commands/handoff-read.md`) loads a handoff file as context at session start. Claude Code's conversation compaction and `CLAUDE.md` persistent memory make it the most natural handoff author — it can summarize a long session into structured YAML.
- **Shared contract it reads/writes:** Writes `.handoff/<task-id>.yaml`. Reads existing handoffs on session start.
- **Fallback if unavailable:** Developer writes the handoff manually using the template at `.handoff/template.yaml`.

### GitHub Copilot
- **Role:** Handoff-aware Coding Agent. When Copilot Coding Agent starts a task, `.github/copilot-instructions.md` instructs it to check `.handoff/` for any active handoffs on the current branch. If one exists, it must read the handoff before starting and include the handoff context in its approach. `.github/prompts/handoff-write.prompt.md` lets a developer generate a handoff from a Copilot Chat session.
- **Shared contract it reads/writes:** Reads `.handoff/<task-id>.yaml` on task start. Writes via prompt file.
- **Fallback if unavailable:** Handoff file is plain YAML — any editor can create or read it.

### Codex
- **Role:** Task-file-integrated handoff consumer. `AGENTS.md` instructs Codex to check `.handoff/` before starting any task and incorporate handoff context into its execution plan. Codex's deterministic task-file model benefits most from explicit context — it doesn't have interactive chat to re-derive context.
- **Shared contract it reads/writes:** Reads `.handoff/<task-id>.yaml` per `AGENTS.md` directive. Writes a handoff on task completion if the task is incomplete.
- **Fallback if unavailable:** Handoff file is a repo artifact. Any subsequent tool or developer can read it.

### Cursor
- **Role:** IDE-integrated handoff generator. `.cursor/rules/handoff.mdc` instructs Cursor to offer a handoff write when the developer closes Agent/Composer mode mid-task. A custom command `/handoff` generates the YAML from the current session. Cursor's IDE tightness makes it the best "session ending, save state" surface — it can detect when a developer switches away.
- **Shared contract it reads/writes:** Writes `.handoff/<task-id>.yaml` on session end. Reads existing handoffs when opening a branch with active handoffs.
- **Fallback if unavailable:** Developer writes handoff manually or uses CLI: `scripts/create-handoff.sh`.

## Languages affected
Language-agnostic. The handoff protocol tracks files and diffs regardless of language. Handoff files are YAML. The protocol applies equally to Go, Python, Node.js, C++, and C work. Most valuable for cross-language tasks (e.g., refactoring a Go service + its C++ allocator + its Helm chart) where context loss on tool switch is most expensive.

## Infra impact
- **Jenkins:** No Jenkins stage needed. Handoff files are developer-workflow artifacts, not CI artifacts. A future enhancement could have Jenkins clean up stale handoffs on merged branches.
- **Kubernetes:** No runtime impact.
- **Density/perf research:** Indirect benefit — density-research tasks are often complex multi-session efforts where tool switching is common. Preserving context across switches saves hours of re-explanation.

## Concrete artifact

`.handoff/refactor-shard-alloc.yaml`:
```yaml
task_id: refactor-shard-alloc
description: "Refactor AllocBurstPool to use jemalloc arenas instead of sync.Pool for better density"
tool: cursor
timestamp: "2026-04-19T10:30:00Z"
developer: alice

files_examined:
  - path: services/shard/alloc.go
    lines: [1, 120]
    notes: "Current implementation uses sync.Pool; hottest allocation path"
  - path: lib/alloc/burst_pool.cc
    lines: [1, 80]
    notes: "C++ side needs matching arena API changes"
  - path: charts/shard/values.yaml
    lines: [45, 60]
    notes: "Memory limits may need adjustment after refactor"

changes_made:
  summary: "Replaced sync.Pool with arena.NewPool in alloc.go; tests pass locally"
  uncommitted_diff: |
    --- a/services/shard/alloc.go
    +++ b/services/shard/alloc.go
    @@ -42,3 +42,3 @@
    -  pool := sync.Pool{New: func() interface{} { return make([]byte, 4096) }}
    +  pool := arena.NewPool(arena.WithBurstSize(2 * 1024 * 1024))

decisions:
  - decision: "Use jemalloc arenas via cgo instead of Go's sync.Pool"
    rationale: "sync.Pool doesn't give us control over arena sizing; jemalloc does"
  - decision: "Keep the C++ API surface minimal — single alloc/free pair"
    rationale: "Reduces FFI complexity and cgo overhead"

dead_ends:
  - approach: "Tried using Go's mmap directly"
    reason: "Too low-level; would need custom allocator logic that jemalloc already provides"

remaining_work:
  - "Update burst_pool.cc to expose arena-based alloc/free"
  - "Update Helm values.yaml memory limits based on benchmark results"
  - "Run density benchmarks and update @mem-budget annotation"

next_tool_suggestion: "claude-code (terminal-native, good for C++ changes and benchmarking)"
```

## Success metric
- Tool-switch re-explanation time drops by 70% (from ~12 min to ~4 min average), measured by developer self-report survey.
- ≥30% of tool switches on multi-session tasks use the handoff protocol within 8 weeks, measured by `.handoff/` file count vs. branch count.
- Dead-end re-exploration (developer or tool repeating an already-abandoned approach) drops measurably, tracked via developer retro feedback.
- Handoff files contain actionable context in ≥80% of cases (not just boilerplate), measured by spot-check audit.

## Risks & failure modes
- **Handoff quality variance:** Tools may generate shallow or boilerplate handoffs. Mitigated by the template structure requiring specific sections (decisions, dead ends, remaining work) and by measuring actionability.
- **Handoff rot:** Files linger after tasks complete. Mitigated by archiving on branch merge and a periodic cleanup script.
- **Adoption friction:** Developers skip the handoff step. Mitigated by IDE integration (Cursor auto-prompts on session end) and CLI convenience scripts.
- **Confusion with "AI memory":** Developers may mistake this for persistent memory. Mitigated by clear naming (handoff, not memory) and the task-scoped, branch-scoped lifecycle.

## Originality statement

**Versus existing ideas in this repo:**
Idea 4 (Conflict Forecast Matrix) coordinates file intent before work starts. This idea transfers task state when switching tools mid-work. Overlap with idea 4: ~15% (both address multi-tool coordination, but at different lifecycle points — pre-work intent vs. mid-work state transfer). No overlap with ideas 2, 3, or 5-8 beyond shared use of repo artifacts.

**Versus common industry proposals:**
The tired-ideas list includes "Naïve 'memory' features — 'remember previous conversation' without a shared protocol that works across tools." This idea is explicitly NOT that: it is task-scoped (not conversation-scoped), structured (YAML, not free text), branch-bound (not persistent), and machine-readable (any tool can parse it, not just the writing tool). It proposes a new inter-tool handoff protocol, not a memory feature. It satisfies heuristics #1 (new inter-tool interface: the handoff YAML), #2 (capability asymmetry: each tool writes/reads handoffs in its own way), and #8 (anti-coordination: preventing re-work after tool switches).
