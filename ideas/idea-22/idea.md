# Idea 22: Incident Replay Arena — AI Tools Compete on Reproducible Past-Incident Fix Scenarios

## One-line summary
Record production incidents as reproducible repo snapshots; AI tools independently attempt fixes; a shared harness compares fix quality, speed, and correctness.

## Tags
shared-evaluation, cross-tool-routing, multi-language, density-research, jenkins

## Problem
The team has no empirical way to compare AI tools on *real* tasks. Tool selection is based on anecdotes: "I feel like Claude is better at Go" or "Copilot is faster for small fixes." When a new model version ships or a new tool is evaluated, there's no benchmark suite that reflects the team's actual codebase and problem types.

Meanwhile, production incidents generate a rich supply of real, solved problems: "this commit caused an OOM, here's the fix." Each incident is a natural evaluation case: given the broken state, can the tool produce the fix? How fast? How correct? How many iterations? But incident data is scattered across Slack threads, post-mortems, and Jira tickets — not in a format AI tools can consume.

## Proposal
Introduce `.incident-arena/` — a structured archive of past incidents converted into reproducible AI-tool evaluation scenarios:

1. **Scenario creation:** After each notable incident is resolved, the team creates a `.incident-arena/scenarios/<incident-id>.yaml` file containing: the broken commit (or branch state), the symptom (OOM, panic, latency spike, etc.), the correct fix (commit SHA), the files involved, and the benchmark/test that validates the fix.
2. **Challenge execution:** A Jenkins job `incident-arena-challenge` can be triggered to run a scenario against one or all AI tools. It checks out the broken state, provides the tool with the symptom description (not the fix), and measures: (a) does the tool produce a fix? (b) does the fix pass the validation test? (c) how many iterations did it take? (d) does the fix match the human fix in intent (semantic comparison, not exact match)?
3. **Leaderboard:** Results are logged to `.incident-arena/results.jsonl` and rendered as a leaderboard (`.incident-arena/leaderboard.md`) showing per-tool performance across all scenarios.
4. **Continuous expansion:** Each new incident adds a new scenario, growing the evaluation corpus over time.

## Cross-AI-tool design

### Claude Code
- **Role:** Primary arena contender and scenario author. Claude Code's agentic terminal mode makes it the most natural tool for tackling open-ended fix scenarios. A custom command (`/.claude/commands/arena-challenge.md`) loads a scenario and attempts a fix. Claude Code is also the preferred tool for authoring complex scenarios from incident post-mortems.
- **Shared contract it reads/writes:** Reads `.incident-arena/scenarios/`. Writes fix attempts. Reads `CLAUDE.md` arena rules.
- **Fallback if unavailable:** Scenario runs skip Claude Code. Other tools still compete.

### GitHub Copilot
- **Role:** PR-driven arena contender. Copilot Coding Agent is given the scenario as a task (via `.github/prompts/arena-challenge.prompt.md`) and opens a PR with its fix attempt. This tests Copilot's autonomous PR-creation capability on real problems.
- **Shared contract it reads/writes:** Reads scenarios via prompt file. Writes fix as PR.
- **Fallback if unavailable:** Copilot's slot is skipped in the leaderboard.

### Codex
- **Role:** Task-file-driven arena contender. `AGENTS.md` includes an arena-challenge task template. Codex receives the scenario description and produces a fix. Its deterministic execution provides a consistent baseline.
- **Shared contract it reads/writes:** Reads scenarios and `AGENTS.md`. Writes fix attempt.
- **Fallback if unavailable:** Slot skipped.

### Cursor
- **Role:** IDE-assisted arena contender. A developer uses Cursor Agent mode to tackle the scenario, with `.cursor/rules/arena.mdc` providing context. This tests the human-AI collaboration model (not fully autonomous). The result measures "developer + Cursor" as a team, providing a baseline for comparing fully autonomous tools against assisted workflows.
- **Shared contract it reads/writes:** Reads scenarios. Developer + Cursor produce fix.
- **Fallback if unavailable:** Slot skipped.

## Languages affected
All five — incident scenarios span the full language stack. Go service OOMs, C++ allocator bugs, Python pipeline failures, Node.js timeout issues, C driver panics. The arena is most valuable for cross-language incidents (e.g., a cgo boundary bug affecting Go and C++ simultaneously). Scenarios are tagged by language so per-tool, per-language performance is measurable.

## Infra impact
- **Jenkins:** New job `incident-arena-challenge` (manually triggered or scheduled). Per scenario: checks out broken state, provides symptom to tool, runs validation. Resource-intensive (~10-30 min per tool per scenario) but runs on-demand or off-peak.
- **Kubernetes:** No runtime impact. Scenarios may include K8s-config-related incidents (e.g., resource spec issues).
- **Density/perf research:** Strongly coupled — density-related incidents (OOMKill, RSS spikes, scheduling failures) are prime arena scenarios. Per-tool performance on density incidents directly informs tool selection for density work.

## Concrete artifact

`.incident-arena/scenarios/inc-2026-04-12-shard-oom.yaml`:
```yaml
incident_id: inc-2026-04-12-shard-oom
title: "Shard API OOMKilled after cache warmup change"
date: "2026-04-12"
severity: P1
component: shard-api
languages: [go, cpp]

broken_state:
  commit: abc123
  branch_snapshot: incident-arena/snapshots/inc-2026-04-12

symptom: |
  shard-api pods OOMKilled within 5 minutes of deployment.
  RSS grows from 800MB to 2.1GB during cache warmup phase.
  Previous version stable at 800MB.
  Error: signal: killed (OOMKilled, memory limit 2Gi)

hint: "The change introduced unbounded cache pre-allocation during warmup."
files_involved:
  - services/shard/cache.go
  - services/shard/alloc.go

validation:
  test: "go test ./services/shard/... -run=TestCacheWarmupMemory -timeout=120s"
  benchmark: "go test ./services/shard/... -bench=BenchmarkCacheWarmup -benchmem"
  success_criteria:
    rss_mb_max: 1000
    test_pass: true

correct_fix:
  commit: def456
  summary: "Bounded cache pre-allocation to maxCacheSize; added incremental warmup"
```

`.incident-arena/leaderboard.md`:
```markdown
# Incident Arena Leaderboard

Last updated: 2026-04-19 | Total scenarios: 12

| Tool | Scenarios attempted | Fixes passing validation | Avg iterations | Avg time (min) | Density incident score |
|------|-------|--------|-------|-------|--------|
| claude-code | 12 | 10 (83%) | 2.1 | 8.5 | 9/10 |
| copilot | 12 | 8 (67%) | 3.4 | 12.2 | 6/10 |
| codex | 12 | 9 (75%) | 2.8 | 10.1 | 8/10 |
| cursor+dev | 10 | 9 (90%) | 1.5 | 15.0 | 8/10 |
```

## Success metric
- ≥12 incident scenarios archived within the first quarter.
- All four tools compete on ≥80% of scenarios (availability permitting).
- The leaderboard reveals at least 2 statistically significant per-tool strengths/weaknesses (e.g., "Tool X is 40% more likely to fix Go OOM incidents than Tool Y").
- Tool selection for critical density incidents is informed by arena data, not anecdotes.
- New model versions are evaluated against the arena corpus before adoption.

## Risks & failure modes
- **Scenario authoring effort:** Creating a good scenario from an incident takes 30-60 minutes. Mitigated by making it part of the incident retrospective process and providing a scaffold script.
- **Scenario representativeness:** Past incidents may not represent future problem types. Mitigated by continuous scenario addition and tagging by category.
- **Tool "memorization":** Tools may learn the fixes from training data. Mitigated by using incidents specific to the team's proprietary codebase (not public OSS issues).
- **Measurement fairness:** Cursor+developer is a different mode (assisted vs. autonomous). Mitigated by labeling results clearly and comparing within-mode, not cross-mode.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) evaluates hallucination rate; idea 14 (Confidence Calibration) evaluates prediction accuracy; idea 16 (Review Roulette) evaluates review quality. This idea evaluates *incident-fixing capability* — a completely different signal that tests end-to-end problem-solving, not just code generation. Overlap with idea 2: ~10% (shared evaluation), idea 14: ~10%, idea 16: ~15%.

**Versus common industry proposals:**
Benchmarks like HumanEval and SWE-bench evaluate LLMs on standardized tasks. This idea uses the team's *own* incidents — proprietary, codebase-specific, multi-language — as the evaluation corpus. It's not a generic benchmark; it's a team-specific, continuously-growing evaluation surface that reflects the real problems the team faces. Not in the tired-ideas list. It satisfies heuristics #1 (new inter-tool interface: the arena protocol), #2 (capability asymmetry: each tool competes in its native mode), #3 (density-research coupling: density incidents are prime scenarios), #5 (language-stack specificity: multi-language incidents), and #7 (shared evaluation surface: the leaderboard).
