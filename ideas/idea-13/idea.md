# Idea 13: Pod Density Regression Bisect — AI-Driven Binary Search for Density Regressions

## One-line summary
When pod density drops, AI tools collaboratively bisect recent commits with targeted benchmarks to isolate the offending change within hours.

## Tags
density-research, perf-regression, jenkins, kubernetes, cross-tool-routing

## Problem
Density regressions — a service suddenly uses 20% more memory, reducing pods-per-node — are caught by weekly monitoring dashboards, not by the PR that caused them. By the time a regression is noticed, 50+ commits have merged. The team manually bisects by checking out commits, running benchmarks, and comparing results. This takes 1-2 days of an engineer's time. AI tools could automate this, but today no protocol exists for AI-driven bisection that leverages each tool's strengths.

The problem is compounded by cross-language effects: a Go code change may shift allocation patterns that only manifest when paired with a specific C++ allocator version. Bisection must sometimes test commit pairs, not individual commits, and the search space is large.

## Proposal
Introduce `.density-bisect/` as a protocol for AI-driven regression bisection:

1. **Trigger:** A density monitoring alert (from existing dashboards or manual detection) creates a `.density-bisect/active/<bisect-id>.yaml` file specifying: the regressed metric (RSS, CPU, pods-per-node), the expected vs. observed value, the commit range to bisect, and the benchmark command(s).
2. **Bisect execution:** A Jenkins job `density-bisect` picks up active bisect files and orchestrates a binary search. For each midpoint commit, it checks out the code, runs the specified benchmarks, records the result, and narrows the range. Results are written to `.density-bisect/results/<bisect-id>.jsonl`.
3. **AI acceleration:** Instead of naive binary search, AI tools analyze the commit log and diff sizes to suggest smarter midpoints. Claude Code analyzes which commits touch density-critical paths; Copilot checks if any commit carries a perf-witness ticket (idea 3) with a relevant prediction; Codex runs targeted benchmarks deterministically; Cursor displays the bisect state in the IDE for developers monitoring the process.
4. **Resolution:** When the offending commit is identified, the protocol writes a `.density-bisect/resolved/<bisect-id>.yaml` with the guilty commit, the tool attribution (via `AI-Tool:` trailer), the measured regression, and a suggested remediation path.

## Cross-AI-tool design

### Claude Code
- **Role:** Bisect strategist and smart midpoint selector. Claude Code reads the commit range, analyzes diffs for density-relevant changes (allocation patterns, Helm resource specs, cgo calls), and proposes the most likely guilty commits — skipping obviously-innocent ones (docs, tests, configs). A custom command (`/.claude/commands/density-bisect.md`) starts a bisect session from a density alert.
- **Shared contract it reads/writes:** Reads `.density-bisect/active/`. Writes midpoint suggestions to `.density-bisect/strategy/<bisect-id>.jsonl`. Reads results to refine strategy.
- **Fallback if unavailable:** Jenkins falls back to naive binary search (still works, just slower).

### GitHub Copilot
- **Role:** Perf-witness ticket correlator. When a bisect is active, Copilot checks if any commit in the range carries a perf-witness ticket (idea 3) with predictions that match the regressed metric. This immediately narrows the search: if a ticket predicted a 5% RSS increase and we're seeing a 20% increase, that commit is a prime suspect. `.github/prompts/density-bisect.prompt.md` provides a guided bisect interaction.
- **Shared contract it reads/writes:** Reads `.density-bisect/active/` and `perf-witness/tickets/`. Writes ticket-correlation hints to `.density-bisect/strategy/`.
- **Fallback if unavailable:** Correlation is skipped. Pure bisect still works.

### Codex
- **Role:** Deterministic benchmark executor. `AGENTS.md` provides a bisect-execution task template. Codex checks out each midpoint, runs the benchmark commands exactly, and records precise results. Its deterministic execution model ensures benchmark consistency across bisect iterations — no variance from interactive session differences.
- **Shared contract it reads/writes:** Reads `.density-bisect/active/` and strategy files. Writes results to `.density-bisect/results/`.
- **Fallback if unavailable:** Jenkins runs benchmarks directly. Codex's value is precision, not necessity.

### Cursor
- **Role:** IDE bisect monitor and remediation drafter. `.cursor/rules/density-bisect.mdc` instructs Cursor to display active bisect status when the developer opens files in the bisected range. A custom command `/bisect-status` shows current bisect state, narrowed range, and results. Once the guilty commit is identified, Cursor is the natural surface for drafting a fix or revert.
- **Shared contract it reads/writes:** Reads `.density-bisect/active/` and `.density-bisect/results/`. Displays status in IDE.
- **Fallback if unavailable:** `scripts/bisect-status.sh` from the terminal.

## Languages affected
All five: Go services (RSS regressions), C++ allocators (heap fragmentation), Python tools (pipeline memory), Node.js BFFs (heap growth), C primitives (allocation pattern changes). Benchmarks are language-specific but the bisect protocol is language-agnostic. The most valuable bisections span Go↔C++ boundaries where cgo allocation behavior is opaque.

## Infra impact
- **Jenkins:** New job `density-bisect` (triggered by active bisect files or manually). Runs benchmarks at each bisect midpoint. Resource-intensive (~30 min per bisect iteration) but runs off-peak or on dedicated agents. No per-PR cost.
- **Kubernetes:** Reads deployment resource specs for context. No new K8s objects. Benchmarks run in CI, not in cluster.
- **Density/perf research:** Core density tool. This is the primary mechanism for root-causing density regressions, which is the team's most expensive post-merge failure class.

## Concrete artifact

`.density-bisect/active/bisect-2026-04-19-rss-shard.yaml`:
```yaml
bisect_id: bisect-2026-04-19-rss-shard
metric: rss_mb
component: shard-api
expected: 1800
observed: 2200
regression_pct: 22.2
commit_range:
  from: abc1234  # last known good (2026-04-12)
  to: def5678    # first known bad (2026-04-19)
benchmarks:
  - command: "go test ./services/shard/... -bench=BenchmarkLoad -run=^$ -benchmem"
    metric_key: rss_mb
  - command: "./bench/allocator_bench --scenario=sustained-load --duration=60s"
    metric_key: peak_rss_mb
status: active
created_by: density-alert-bot
```

`.density-bisect/results/bisect-2026-04-19-rss-shard.jsonl`:
```jsonl
{"iteration":1,"commit":"mid1234","rss_mb":1850,"status":"good","range_remaining":25}
{"iteration":2,"commit":"mid5678","rss_mb":2150,"status":"bad","range_remaining":12}
{"iteration":3,"commit":"mid9012","rss_mb":2180,"status":"bad","range_remaining":6}
{"iteration":4,"commit":"guilty42","rss_mb":2200,"status":"bad","range_remaining":3}
{"iteration":5,"commit":"guilty42","rss_mb":2200,"status":"confirmed_guilty","tool_attribution":"copilot","message":"Replaced fixed-size buffer with dynamic slice in shard handler"}
```

## Success metric
- Time-to-root-cause for density regressions drops from 1-2 days to <4 hours, measured by bisect start-to-resolution timestamps.
- ≥80% of density regressions are bisected using the protocol within one quarter.
- Smart midpoint selection (via AI strategy) reduces bisect iterations by ≥30% vs. naive binary search, measured by average iteration count.
- Resolution files provide actionable remediation paths in ≥70% of cases.

## Risks & failure modes
- **Benchmark flakiness:** Memory measurements vary across runs, causing false bisect pivots. Mitigated by requiring 3-run median at each midpoint and configurable tolerance.
- **Cross-commit interactions:** The regression may be caused by the combination of two commits, not one. Mitigated by supporting "range-guilty" results and testing commit pairs when single-commit bisect fails.
- **Resource cost:** Each bisect iteration runs benchmarks (30-60 min). 5-10 iterations = 2.5-10 hours of CI time. Mitigated by scheduling off-peak and allowing early termination when smart midpoints converge.
- **Stale bisect files:** Active bisects may be abandoned. Mitigated by auto-closing after 7 days with a "timed-out" resolution.

## Originality statement

**Versus existing ideas in this repo:**
Idea 3 (Perf Witness Tickets) predicts perf impact pre-merge; this idea root-causes regressions post-merge. They're complementary: ticket predictions can accelerate bisection (if a ticket predicted incorrectly, that commit is suspect). Overlap: ~20% (both address density/perf, but at different lifecycle points). Idea 2 (Canary Identifiers) detects hallucinations, not regressions.

**Versus common industry proposals:**
`git bisect` exists, but it's manual, single-tool, and language-unaware. Automated bisection for performance regressions with AI-driven smart midpoints, cross-tool strategy (Claude analyzes, Copilot correlates, Codex executes, Cursor monitors), and density-research integration is novel. Not a generic metrics dashboard or observability tool. It satisfies heuristics #1 (new inter-tool interface: the bisect protocol), #2 (capability asymmetry exploitation), #3 (density-research coupling — this IS the density root-cause tool), #4 (Jenkins leverage), and #7 (shared evaluation surface: bisect results compare tool-attributed commits).
