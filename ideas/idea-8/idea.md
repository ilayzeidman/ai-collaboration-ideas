# Idea 8: Semantic Merge Arbiter — Multi-Tool Consensus Protocol for Conflict Resolution

## One-line summary
When merge conflicts arise in AI-touched files, solicit independent resolution proposals from multiple tools and pick by consensus scoring.

## Tags
anti-coordination, cross-tool-routing, shared-protocol, multi-language, shared-evaluation

## Problem
Merge conflicts on AI-authored code are doubly expensive: the original code was generated without the developer fully understanding every line, and now they must resolve a conflict in code they didn't write. When two AI tools produce conflicting changes to the same file — say, Copilot restructured a Go handler while Claude Code optimized its allocations — the developer is left manually merging two opaque transformations. Today this is a 30-minute to 2-hour manual process per conflict, and the result is often a compromise that satisfies neither tool's intent.

Worse, when a developer asks one AI tool to resolve the conflict, that tool only sees the conflict markers — it has no context about the other tool's intent. It guesses, and the guess is often wrong. There's no protocol for leveraging the fact that we have four AI tools with different strengths.

## Proposal
Introduce a merge conflict resolution protocol stored in `.merge-arbiter/`. When a merge conflict is detected on an AI-touched file (identified by `AI-Tool:` commit trailers), the protocol activates:

1. The conflict is extracted to `.merge-arbiter/conflicts/<branch>-<file>.json`, containing both sides (ours/theirs), the base version, and the commit trailers indicating which tools authored each side.
2. Each available AI tool is asked to independently propose a resolution, stored as `.merge-arbiter/proposals/<branch>-<file>-<tool>.patch`.
3. A scoring script (`scripts/score-merge-proposals.sh`) evaluates each proposal against criteria: (a) does it compile/lint, (b) do existing tests pass, (c) does it preserve the declared intent from both commit messages, (d) does it respect any `@mem-budget` annotations (linking to idea 7).
4. The highest-scoring proposal is surfaced to the developer as the recommended resolution. The developer can accept, modify, or reject it.
5. The outcome (which proposal was accepted, which tool "won") is logged to `.merge-arbiter/history.jsonl`.

## Cross-AI-tool design

### Claude Code
- **Role:** Primary resolution proposer for complex multi-file conflicts. Claude Code's agentic terminal mode and subagent capability make it best at reasoning about intent across files. A custom command (`/.claude/commands/resolve-conflict.md`) feeds the conflict JSON to Claude Code and captures its resolution patch.
- **Shared contract it reads/writes:** Reads `.merge-arbiter/conflicts/`. Writes to `.merge-arbiter/proposals/`. Reads `CLAUDE.md` merge-arbiter rules.
- **Fallback if unavailable:** Its proposal slot is simply empty. Other tools' proposals are still scored. If only one tool proposes, that proposal is the recommendation.

### GitHub Copilot
- **Role:** Fast inline resolution proposer. For simple conflicts (single-hunk, same language), Copilot's inline completion is the fastest resolution path. `.github/prompts/merge-arbiter.prompt.md` provides a structured prompt for conflict resolution. Copilot Coding Agent can be asked to resolve a conflict and submit its proposal as a patch.
- **Shared contract it reads/writes:** Reads conflict JSON via prompt file. Writes proposal patch.
- **Fallback if unavailable:** Slot empty. Other proposals and manual resolution remain available.

### Codex
- **Role:** Deterministic verifier of proposals. Rather than proposing its own resolution, Codex's primary role is to run the scoring script against all proposals — compile, lint, test, intent-preservation check. `AGENTS.md` includes a task-file directive for this verification role. If also asked to propose, it generates a conservative "minimal-change" resolution.
- **Shared contract it reads/writes:** Reads all proposals from `.merge-arbiter/proposals/`. Writes scores to `.merge-arbiter/scores/`. Reads `AGENTS.md` verification directive.
- **Fallback if unavailable:** Scoring script runs in Jenkins or locally via `scripts/score-merge-proposals.sh`.

### Cursor
- **Role:** IDE-integrated conflict resolver. `.cursor/rules/merge-arbiter.mdc` instructs Cursor to detect conflict markers and offer to run the arbiter protocol. A custom command `/resolve-conflict` feeds the conflict to Cursor's Agent mode and generates a proposal. Cursor's IDE tightness makes it the best surface for side-by-side comparison of proposals before the developer picks one.
- **Shared contract it reads/writes:** Reads conflict JSON and proposals. Writes its own proposal. Displays all proposals for developer selection.
- **Fallback if unavailable:** Terminal-based proposal comparison via `scripts/compare-proposals.sh`.

## Languages affected
Language-agnostic at the protocol level (JSON conflicts, patch proposals, shell scoring). The scoring criteria include language-specific checks: Go compile + `go vet`, C++ compile + sanitizer, Python lint + type check, Node.js build + eslint, C compile + warnings. Each language's test suite runs against proposals. The idea is most valuable for Go↔C++ conflicts in density-research code, where both tools' intents are performance-critical.

## Infra impact
- **Jenkins:** No new mandatory stage (conflict resolution happens pre-push, not in CI). Optional stage `merge-arbiter-score` can run proposals through the full test suite in CI if local scoring is insufficient. History log is committed and available for analysis.
- **Kubernetes:** No runtime impact.
- **Density/perf research:** High value for density-research conflicts where two tools optimize different aspects of the same hot path. The scoring criteria include `@mem-budget` compliance, directly linking to idea 7.

## Concrete artifact

`.merge-arbiter/conflicts/feat-cache-services-shard-alloc.json`:
```json
{
  "file": "services/shard/alloc.go",
  "base": "abc123",
  "ours": { "branch": "feat/cache-warmup", "tool": "copilot", "commit": "def456" },
  "theirs": { "branch": "feat/arena-tuning", "tool": "claude-code", "commit": "ghi789" },
  "conflict_hunks": [
    {
      "start_line": 42,
      "ours_content": "pool := sync.Pool{New: func() interface{} { return make([]byte, 4096) }}",
      "theirs_content": "pool := arena.NewPool(arena.WithBurstSize(2 * 1024 * 1024))"
    }
  ]
}
```

Scoring output:
```jsonl
{"file":"services/shard/alloc.go","tool":"claude-code","compiles":true,"tests_pass":true,"lint_clean":true,"intent_preserved":true,"mem_budget_ok":true,"score":5}
{"file":"services/shard/alloc.go","tool":"copilot","compiles":true,"tests_pass":true,"lint_clean":true,"intent_preserved":false,"mem_budget_ok":false,"score":3}
```

## Success metric
- Merge conflict resolution time for AI-touched files drops by 60% (from ~45 min to ~18 min average), measured by timestamp deltas between conflict detection and resolution commit.
- At least 50% of AI-touched merge conflicts use the arbiter protocol within 8 weeks.
- The "winning" proposal passes all scoring criteria ≥70% of the time, demonstrating protocol quality.
- Cross-tool resolution quality data (`.merge-arbiter/history.jsonl`) informs tool selection for future tasks.

## Risks & failure modes
- **Low conflict volume:** If the team rarely has AI-touched merge conflicts, the protocol sees little use. Mitigated by also supporting non-AI conflicts (any merge conflict can use the protocol).
- **Proposal quality variance:** Tools may produce low-quality resolutions. Mitigated by the scoring step — bad proposals are ranked low and the developer is always the final arbiter.
- **Overhead for simple conflicts:** Single-line conflicts don't need multi-tool proposals. Mitigated by a complexity threshold: trivial conflicts skip the protocol.
- **Intent interpretation errors:** Tools may misinterpret the "intent" criterion. Mitigated by using commit messages and PR descriptions as intent sources, not AI inference about what the code "should" do.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) is about hallucination detection, not conflict resolution. Idea 3 (Perf Witness Tickets) is about performance prediction. Idea 4 (Conflict Forecast Matrix) prevents collisions proactively; this idea resolves them after they occur — they're complementary, not overlapping (idea 4: prevention, idea 8: cure). Overlap with idea 4: ~20% (both address multi-tool file conflicts, but at different lifecycle stages).

**Versus common industry proposals:**
This is not a review bot (it resolves conflicts, not reviews code) or a PR summarizer. AI-assisted merge conflict resolution exists as a feature in some IDEs, but those use a single tool in isolation. The multi-tool consensus protocol — independent proposals + automated scoring + cross-tool comparison — is novel. It satisfies heuristics #1 (new inter-tool interface: the conflict/proposal/score protocol), #2 (capability asymmetry: Claude for complex resolution, Copilot for fast inline, Codex for verification, Cursor for IDE display), #7 (shared evaluation surface: which tool resolves conflicts best), and #8 (anti-coordination: managing the aftermath of tool collisions).
