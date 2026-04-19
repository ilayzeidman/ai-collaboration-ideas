# Idea 18: Stale Context Detector — Flag When AI Assumptions Become Invalid Post-Merge

## One-line summary
Record file-state assumptions each AI tool made when generating code; a post-merge watcher flags when those assumptions are invalidated by later changes.

## Tags
anti-coordination, shared-protocol, jenkins, cross-tool-routing

## Problem
AI tools generate code based on the state of the repo at generation time. A Claude Code refactor assumes `AllocBurstPool` takes two arguments; a Copilot completion assumes the Helm chart uses `spec.replicas` (not `spec.autoscaling.minReplicas`). These assumptions are implicit — they live in the tool's context window and disappear when the session ends.

When a subsequent PR changes the assumed state (renames `AllocBurstPool` to take three arguments, or restructures the Helm chart), the previously-generated code becomes subtly wrong. It still compiles and passes tests (the change was internal), but the semantic assumption is broken. This class of bug — "code generated under stale assumptions" — is unique to AI-assisted workflows and has no existing detection mechanism.

## Proposal
Introduce `.assumptions/` as a directory where AI tools record the key assumptions they made when generating code:

1. **Recording:** When an AI tool generates a non-trivial change, it writes a `.assumptions/<branch>-<file>.yaml` file listing: the files it read, the key facts it assumed (function signatures, config values, API shapes), and the generated file + line range that depends on these assumptions.
2. **Watching:** A Jenkins post-merge job (`assumption-watcher`) runs on every merge to main. For each recent assumption file, it checks whether the assumed facts still hold: are the function signatures the same? Are the config values unchanged? Are the API shapes intact?
3. **Flagging:** When an assumption is invalidated, the watcher creates a GitHub issue (or PR comment) linking the assumption to the invalidating change: "Warning: PR #4850 assumed `AllocBurstPool(arena, n int)` at services/shard/alloc.go:42. PR #4862 changed the signature to `AllocBurstPool(arena, n int, opts ...Option)`. The code at services/shard/handler.go:78 may need updating."
4. **Cleanup:** Assumptions are archived after 30 days or when the dependent code is modified (since any modification implies the developer re-evaluated the context).

## Cross-AI-tool design

### Claude Code
- **Role:** Primary assumption recorder. Claude Code's session model (long-running, multi-file) makes it the richest source of explicit assumptions. A custom command (`/.claude/commands/record-assumptions.md`) generates an assumption file from the current session's context. Claude Code can also analyze which of its assumptions are most fragile (depend on frequently-changed files).
- **Shared contract it reads/writes:** Writes `.assumptions/` files. Reads `CLAUDE.md` assumption-recording directive.
- **Fallback if unavailable:** Developer manually lists assumptions using `scripts/record-assumptions.sh`. The watcher runs regardless.

### GitHub Copilot
- **Role:** Assumption-aware PR authoring. `.github/copilot-instructions.md` includes: "When generating non-trivial changes, record key assumptions in `.assumptions/`." Copilot Coding Agent PRs should include assumption files. `.github/prompts/record-assumptions.prompt.md` provides a structured recording prompt.
- **Shared contract it reads/writes:** Writes `.assumptions/` files in PRs. Reads invalidation warnings on its own PRs.
- **Fallback if unavailable:** Assumption recording is optional — the watcher still monitors assumptions from other tools.

### Codex
- **Role:** Assumption-explicit task executor. `AGENTS.md` includes a directive: "Before submitting, list assumptions about external file states in `.assumptions/`." Codex's task-file structure makes it natural to enumerate input assumptions explicitly.
- **Shared contract it reads/writes:** Writes `.assumptions/` files per `AGENTS.md` directive.
- **Fallback if unavailable:** Assumption files from other tools are still watched.

### Cursor
- **Role:** IDE assumption surfacer. `.cursor/rules/assumptions.mdc` instructs Cursor to display active assumptions when the developer opens a file that has assumption records. A custom command `/assumptions` shows which assumptions depend on the current file, helping the developer understand what breaks if they change it.
- **Shared contract it reads/writes:** Reads `.assumptions/` files. Displays in IDE.
- **Fallback if unavailable:** `scripts/show-assumptions.sh <file>` from the terminal.

## Languages affected
Language-agnostic. Assumptions track facts about code in any language: Go function signatures, C++ struct layouts, Python module APIs, Node.js config shapes, C header declarations, YAML values, Groovy pipeline steps. The watcher checks assumption validity using language-appropriate tools (e.g., AST parsing for signatures, grep for config values).

## Infra impact
- **Jenkins:** New post-merge job `assumption-watcher` that checks recent assumptions against current file states. Lightweight — reads assumption files and compares signatures/values. Creates GitHub issues when assumptions are invalidated.
- **Kubernetes:** No runtime impact.
- **Density/perf research:** Indirect but valuable — density-research code changes frequently and AI-generated code in adjacent modules may hold stale assumptions about allocator interfaces or Helm resource specs.

## Concrete artifact

`.assumptions/feat-cache-services-shard-handler.yaml`:
```yaml
assumption_id: feat-cache-handler-alloc
branch: feat/cache-warmup
tool: copilot
developer: bob
timestamp: "2026-04-19T10:00:00Z"

generated_code:
  file: services/shard/handler.go
  lines: [78, 95]
  description: "Cache warmup handler calling AllocBurstPool"

assumptions:
  - fact: "AllocBurstPool signature: func AllocBurstPool(arena *jemalloc.Arena, n int) (*Pool, error)"
    source_file: services/shard/alloc.go
    source_line: 42
    type: function-signature

  - fact: "Helm value spec.resources.limits.memory = 2Gi"
    source_file: charts/shard/values.yaml
    source_line: 48
    type: config-value

  - fact: "shard-api deployment uses 3 replicas"
    source_file: charts/shard/values.yaml
    source_line: 12
    type: config-value

expires: "2026-05-19T10:00:00Z"
```

Watcher alert (GitHub issue):
```markdown
## ⚠️ Stale AI Assumption Detected

**Assumption:** `AllocBurstPool` signature is `func AllocBurstPool(arena *jemalloc.Arena, n int) (*Pool, error)`
**Recorded by:** copilot in PR #4850 (feat/cache-warmup)
**Invalidated by:** PR #4862 changed signature to `func AllocBurstPool(arena *jemalloc.Arena, n int, opts ...Option) (*Pool, error)`

**Potentially affected code:** `services/shard/handler.go:78-95` (cache warmup handler)

**Action needed:** Review whether the generated code at handler.go:78 still works with the new signature.
```

## Success metric
- ≥30% of AI-authored PRs include assumption records within 8 weeks.
- The watcher detects ≥5 invalidated assumptions per month that would otherwise have been silent bugs.
- Developer response time on invalidation alerts is <24 hours, measured by issue close timestamps.
- Zero "stale assumption" bugs reach production (all caught by watcher + developer response).

## Risks & failure modes
- **Assumption recording friction:** Tools may not consistently record assumptions. Mitigated by starting with a minimal format (just list file:line facts) and making the watcher useful even with sparse data.
- **Alert fatigue:** Too many invalidation alerts. Mitigated by focusing on high-confidence invalidations (signature changes, not comment edits) and by the 30-day expiry.
- **False invalidations:** Watcher flags a change that doesn't actually break the generated code. Mitigated by checking actual semantic impact (signature match) not just file modification timestamp.
- **Assumption quality:** Tools may record overly broad or overly narrow assumptions. Mitigated by providing examples and checking assumption specificity in the recording template.

## Originality statement

**Versus existing ideas in this repo:**
Idea 4 (Conflict Forecast Matrix) prevents collisions before work starts. Idea 9 (Context Handoff Protocol) transfers context between tools mid-task. This idea detects context *staleness* after merge — a different lifecycle point (post-merge validity checking). Overlap with idea 4: ~15% (both address multi-tool coordination). Overlap with idea 9: ~15% (both deal with context). Neither exceeds 30%.

**Versus common industry proposals:**
This is not "AI memory" (tired idea) — it records *falsifiable assumptions*, not conversations. It's not a review bot or linter — it watches for environmental changes that invalidate previously-generated code. The concept of "assumption validity watching" for AI-generated code doesn't exist in current tooling. It satisfies heuristics #1 (new inter-tool interface: the assumption protocol), #6 (failure mode as feature: turns context staleness into a detectable signal), and #8 (anti-coordination: prevents later changes from silently breaking earlier AI-generated code).
