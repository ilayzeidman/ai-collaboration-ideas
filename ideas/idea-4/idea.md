# Idea 4: Conflict Forecast Matrix — Predict Multi-Tool File-Edit Collisions Before They Happen

## One-line summary
Publish a shared intent-lock registry so AI tools declare which files they plan to modify, preventing silent overwrites in multi-tool workflows.

## Tags
anti-coordination, shared-protocol, multi-language, cross-tool-routing

## Problem
When two developers use different AI tools on overlapping parts of the codebase, neither tool knows the other is active. A Cursor user refactors `services/gateway/handler.go` while a Copilot Coding Agent PR rewrites the same file for a different task. Both produce clean diffs against `main`, but they conflict on merge. Worse, if one merges first, the second tool's entire context is stale — it generated code against a file state that no longer exists. Today, the team discovers this only at merge time or during review, wasting hours of AI-assisted work.

The problem is acute in this team's multi-language PRs: a single task might touch a Go service, its Python test harness, and its Helm chart. Two tools working on adjacent tasks can collide on any of these files without warning.

## Proposal
Introduce `.intent-locks/active.jsonl`, an append-only file where each AI tool session registers the files it intends to modify before starting work. Each record contains: (a) the tool name, (b) the developer, (c) the branch, (d) the list of file paths, (e) a timestamp, and (f) an estimated duration. Records expire after their estimated duration or when the branch merges/closes.

Before starting a modification session, each tool reads `active.jsonl` and warns the developer if another session has declared intent on overlapping files. The tool may proceed (with an explicit override flag) but the collision is logged to `.intent-locks/collisions.jsonl` for post-hoc analysis.

A Jenkins pre-merge stage `conflict-forecast` checks whether the PR's changed files overlap with any active intent lock from another branch. If so, it adds a PR comment linking to the other branch and requesting explicit coordination. A lightweight cron job (`scripts/expire-intent-locks.sh`) runs hourly to garbage-collect stale locks.

## Cross-AI-tool design

### Claude Code
- **Role:** Session-level lock manager. Before executing a multi-file task, Claude Code reads `active.jsonl`, warns on overlaps, and appends its own intent record. Its agentic terminal nature makes it the most reliable pre-task checker because it controls the full session lifecycle.
- **Shared contract it reads/writes:** Reads/writes `.intent-locks/active.jsonl`. Reads `.intent-locks/collisions.jsonl` for historical context.
- **Fallback if unavailable:** The pre-commit hook (`scripts/check-intent-locks.sh`) catches unregistered file modifications and prompts the developer to register retroactively. Jenkins gate still runs.

### GitHub Copilot
- **Role:** PR-level lock registrant. When Copilot Coding Agent opens a PR, it registers all files in the PR diff as intent-locked for that branch. For inline completions, a `.github/prompts/check-locks.prompt.md` prompt file lets the developer manually check locks before a large edit session.
- **Shared contract it reads/writes:** Reads `.intent-locks/active.jsonl` via the prompt file. Writes intent records when Coding Agent starts a task.
- **Fallback if unavailable:** Developer runs `scripts/register-intent.sh <branch> <files...>` manually. Jenkins gate remains the backstop.

### Codex
- **Role:** Task-file-scoped lock registrant. `AGENTS.md` instructs Codex to parse the task description for target files and register intent before beginning work. Codex's deterministic task-file-driven execution makes it the cleanest registrant — it knows its file scope upfront.
- **Shared contract it reads/writes:** Reads/writes `.intent-locks/active.jsonl` per `AGENTS.md` directive.
- **Fallback if unavailable:** Same CLI fallback as other tools. The Jenkins stage catches unregistered modifications.

### Cursor
- **Role:** IDE-integrated collision warner. `.cursor/rules/intent-locks.mdc` instructs Cursor to check `active.jsonl` before starting Agent/Composer mode on any file. A custom command `/check-locks` shows current active locks in the IDE. Cursor's tight IDE integration makes it the best real-time collision detection surface.
- **Shared contract it reads/writes:** Reads `.intent-locks/active.jsonl`. Writes intent records when entering Agent mode on a file set.
- **Fallback if unavailable:** `scripts/check-intent-locks.sh` from the terminal. No IDE, no problem — the registry is just a file.

## Languages affected
Language-agnostic by design. The registry tracks file paths, not language constructs. It applies equally to Go services, Python scripts, Node.js BFFs, C++/C performance code, Helm charts (YAML), and Jenkinsfiles (Groovy). The highest-value files are those touched in cross-language PRs (e.g., a Go service + its Python test harness + its Helm chart), which is exactly where multi-tool collisions hurt most.

## Infra impact
- **Jenkins:** New stage `conflict-forecast` in the shared library, callable as `conflictForecast()`. Runs before `build`. Non-blocking (comments only), upgradeable to blocking after the team calibrates false-positive rate.
- **Kubernetes:** None at runtime. The registry is a repo artifact.
- **Density/perf research:** Indirect benefit — prevents wasted AI work on density-research PRs that would otherwise collide and require manual re-merge.

## Concrete artifact

`.intent-locks/active.jsonl` (excerpt):
```jsonl
{"tool":"claude-code","dev":"alice","branch":"feat/jemalloc-arena-tuning","files":["services/shard/alloc.go","services/shard/alloc_test.go","charts/shard/values.yaml"],"ts":"2026-04-19T08:00:00Z","est_hours":4}
{"tool":"copilot","dev":"bob","branch":"fix/gateway-timeout","files":["services/gateway/handler.go","services/gateway/handler_test.go"],"ts":"2026-04-19T09:15:00Z","est_hours":2}
```

`scripts/register-intent.sh`:
```bash
#!/usr/bin/env bash
BRANCH=$(git branch --show-current)
TOOL=${AI_TOOL:-unknown}
DEV=$(git config user.name)
FILES=$(printf '"%s",' "$@" | sed 's/,$//')
echo "{\"tool\":\"$TOOL\",\"dev\":\"$DEV\",\"branch\":\"$BRANCH\",\"files\":[$FILES],\"ts\":\"$(date -u +%FT%TZ)\",\"est_hours\":${EST_HOURS:-2}}" >> .intent-locks/active.jsonl
```

Jenkins stage:
```groovy
stage('conflict-forecast') {
  steps {
    script {
      def overlaps = conflictForecast(lockFile: '.intent-locks/active.jsonl')
      if (overlaps) { githubPrComment(body: renderConflictWarning(overlaps)) }
    }
  }
}
```

## Success metric
- Within 8 weeks, 70% of AI-assisted sessions register intent before starting, measured by comparing `active.jsonl` entries to PR file lists.
- Merge conflicts on AI-touched files decrease by 50%, measured by counting `git merge --abort` events in CI logs quarter-over-quarter.
- Collision log (`.intent-locks/collisions.jsonl`) contains actionable records that correlate with at least 3 prevented conflicts per month.

## Risks & failure modes
- **Stale locks:** Developers forget to close sessions. Mitigated by TTL-based expiration and the hourly garbage-collection cron.
- **Over-registration:** Tools register broad file sets "just in case", creating noise. Mitigated by tracking false-positive rate and tightening scope guidance in rule files.
- **Adoption friction:** Developers skip registration. Mitigated by the pre-commit hook fallback and Jenkins gate making unregistered modifications visible.
- **Race conditions on the lock file:** Two tools append simultaneously. Mitigated by using atomic append (single-line jsonl) and accepting that rare duplicates are harmless — the forecast is advisory, not a hard lock.
- **Privacy concerns:** Developers' work-in-progress is visible. Mitigated by only recording file paths and branches, not content or intent descriptions.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) detects hallucinations after the fact via planted bait. Idea 3 (Perf Witness Tickets) enforces performance predictions. This idea prevents work-waste *before* it happens by coordinating tool intent. The shared registry pattern is structurally similar (append-only jsonl), but the problem domain (collision prevention vs. hallucination detection vs. perf prediction) and the timing (pre-work vs. post-diff) are entirely different. Overlap with idea 2: ~15%. Overlap with idea 3: ~10%.

**Versus common industry proposals:**
This is not a PR summarizer, linter, test generator, review bot, doc generator, chatbot, memory plugin, or agent marketplace from the tired-ideas list. File-locking is an ancient concept (pessimistic locking in VCS), but applying it as a *voluntary, advisory, cross-AI-tool* coordination protocol with per-tool registration roles and a shared collision log is novel. Traditional file locks are binary and blocking; this is a forecast — advisory, multi-tool-aware, and designed to degrade gracefully. It satisfies novelty heuristics #1 (new inter-tool interface), #2 (capability-asymmetry exploitation — each tool registers differently based on its session model), and #8 (anti-coordination).
