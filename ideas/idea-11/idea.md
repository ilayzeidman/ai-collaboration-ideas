# Idea 11: Rollback Fingerprinting — Attribute Production Rollbacks to AI Tool Provenance

## One-line summary
Tag AI-authored commits with tool provenance so production rollbacks auto-generate per-tool reliability scorecards fed back into tool instruction files.

## Tags
shared-evaluation, cross-tool-routing, kubernetes, jenkins, perf-regression

## Problem
When a Kubernetes deployment rolls back, the team scrambles to find the offending commit. If the commit was AI-authored, there's no systematic way to attribute the failure to the specific tool that wrote the code. This means the team can't answer basic questions: "Is Copilot-authored code more likely to cause rollbacks than Claude Code-authored code?" "Are Codex-authored changes safer in Go than in Python?" "Has Cursor's reliability improved this quarter?"

Today, rollback attribution is manual: someone reads the git log, guesses which commits caused the issue, and notes the AI tool (if they even check). There's no feedback loop — a tool that produces rollback-prone code keeps doing so because neither it nor its instruction files learn from the pattern.

## Proposal
Build on the `AI-Tool:` commit trailer convention (from idea 2) to create an automated rollback attribution pipeline:

1. **Tagging:** Every AI-assisted commit already carries `AI-Tool: <tool>`. Add `AI-Scope: <component>` to identify the service/component affected.
2. **Rollback detection:** A Jenkins job (`rollback-watcher`) monitors Kubernetes `Deployment` and `StatefulSet` rollback events via `kubectl rollout history`. When a rollback occurs, it identifies the rolled-back commits and their `AI-Tool` trailers.
3. **Attribution ledger:** Rollback events are recorded in `.rollback-fingerprints/ledger.jsonl` with: rolled-back commit SHAs, AI-Tool attribution, component, rollback reason (from the K8s rollout annotation or manual input), and environment.
4. **Scorecards:** A weekly script (`scripts/generate-rollback-scorecard.sh`) reads the ledger and generates per-tool reliability scorecards: rollback rate per tool, per language, per component. These are committed to `.rollback-fingerprints/scorecards/`.
5. **Feedback loop:** Scorecards are referenced in all four tool rule files: "Your recent rollback rate for Go services is X%. Pay extra attention to error handling and resource cleanup in Go code." The rule-file generator (idea 6) can incorporate scorecard data.

## Cross-AI-tool design

### Claude Code
- **Role:** Scorecard analyst and rule updater. Claude Code reads the rollback ledger and generates the weekly scorecard. It also proposes rule-file updates based on patterns (e.g., "Copilot rollbacks correlate with missing error handling in Go → add Go error-handling emphasis to Copilot's instructions"). A custom command (`/.claude/commands/rollback-analysis.md`) runs the full analysis pipeline.
- **Shared contract it reads/writes:** Reads `.rollback-fingerprints/ledger.jsonl`. Writes scorecards to `.rollback-fingerprints/scorecards/`. Proposes rule-file updates.
- **Fallback if unavailable:** `scripts/generate-rollback-scorecard.sh` runs standalone. Rule updates are proposed manually.

### GitHub Copilot
- **Role:** Rollback-aware PR authoring. `.github/copilot-instructions.md` includes the latest scorecard data for Copilot's reliability areas. When Copilot Coding Agent opens a PR for a component with a high rollback rate, the instructions emphasize extra caution and require more comprehensive test coverage.
- **Shared contract it reads/writes:** Reads `.rollback-fingerprints/scorecards/copilot.md`. Reads `.github/copilot-instructions.md` (which embeds scorecard highlights).
- **Fallback if unavailable:** Scorecard data is in the repo — any tool or human can read it. The data persists even if Copilot is off.

### Codex
- **Role:** Pre-submit rollback risk checker. `AGENTS.md` instructs Codex to check the rollback scorecard for the component it's modifying. If the component has a high rollback rate for Codex-authored changes, Codex must run additional verification steps before submitting.
- **Shared contract it reads/writes:** Reads `.rollback-fingerprints/scorecards/codex.md` and `AGENTS.md` directive.
- **Fallback if unavailable:** Scorecard is a static file — no tool dependency for reading.

### Cursor
- **Role:** IDE rollback warning. `.cursor/rules/rollback-awareness.mdc` instructs Cursor to display a warning when editing a file in a component with a high rollback rate. A custom command `/rollback-stats` shows the scorecard for the current component. Cursor's IDE integration makes it the best "caution: fragile component" warning surface.
- **Shared contract it reads/writes:** Reads `.rollback-fingerprints/scorecards/`. Displays in IDE.
- **Fallback if unavailable:** `scripts/show-rollback-stats.sh <component>` from the terminal.

## Languages affected
All languages — rollback attribution is per-component, and components span Go services, Python tools, Node.js BFFs, C++/C libraries. The scorecard breaks down rollback rates by language, enabling insights like "Codex is reliable in Python but fragile in C++." Language-specific patterns (e.g., Go error handling, C++ memory management) inform the feedback rules.

## Infra impact
- **Jenkins:** New scheduled job `rollback-watcher` that queries K8s rollout history and writes to the ledger. Weekly `generate-rollback-scorecard` job. Both are lightweight (<1 min). No per-PR stage cost.
- **Kubernetes:** Reads `kubectl rollout history` for Deployments and StatefulSets. No new K8s objects. Requires read access to rollout annotations.
- **Density/perf research:** Directly relevant — density-research changes that cause rollbacks are the highest-cost failures. Scorecard data helps identify which tools are safest for density-critical components.

## Concrete artifact

`.rollback-fingerprints/ledger.jsonl`:
```jsonl
{"ts":"2026-04-12T03:15:00Z","env":"prod","component":"shard-api","deployment":"shard-api-v2.4.1","rolled_back_to":"shard-api-v2.4.0","commits":["abc123","def456"],"tools":["copilot","claude-code"],"languages":["go","cpp"],"reason":"OOMKilled: RSS exceeded 2GB limit after cache warmup change","severity":"P1"}
{"ts":"2026-04-18T11:30:00Z","env":"staging","component":"gateway","deployment":"gateway-v1.8.3","rolled_back_to":"gateway-v1.8.2","commits":["ghi789"],"tools":["cursor"],"languages":["go"],"reason":"Nil pointer panic in new handler path","severity":"P2"}
```

Per-tool scorecard (`.rollback-fingerprints/scorecards/copilot.md`):
```markdown
# Copilot Rollback Scorecard — Week of 2026-04-14

| Metric | Value |
|--------|-------|
| Total rollbacks attributed | 3 |
| Rollback rate (per 100 PRs) | 2.1% |
| Most fragile component | shard-api |
| Most fragile language | Go |
| Top failure pattern | Missing error handling in new handler paths |

## Recommendation for instruction file
Emphasize: wrap all new error paths with explicit nil checks and error returns in Go handlers.
```

## Success metric
- 100% of rollbacks in AI-touched components are auto-attributed within 24 hours, measured by ledger completeness.
- Per-tool rollback rates become trackable quarter-over-quarter, enabling data-driven tool selection for critical components.
- Rollback rate for the highest-rate tool decreases by 20% within one quarter after instruction-file feedback is applied.
- Team stops relying on manual post-mortem attribution (measured by reduced time-to-attribution from hours to minutes).

## Risks & failure modes
- **Attribution noise:** A rollback may be caused by multiple commits from multiple tools, making per-tool attribution fuzzy. Mitigated by recording all contributing commits and tools, treating attribution as multi-valued.
- **Low rollback volume:** If rollbacks are rare (<5/quarter), scorecards lack statistical significance. Mitigated by including staging rollbacks (more frequent) alongside prod.
- **Trailer compliance:** Missing `AI-Tool:` trailers make attribution impossible. Mitigated by the commit-msg hook from idea 2 and Jenkins trailer enforcement.
- **Feedback loop overfitting:** Tool instructions become too specific to past failures, missing new failure modes. Mitigated by keeping feedback rules general (patterns, not specific fixes) and expiring rules after 2 quarters.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) attributes hallucinations per tool; this idea attributes *production rollbacks* per tool — a different failure mode and a production-time signal (not CI-time). Overlap: ~20% (shared `AI-Tool:` trailer and attribution ledger pattern). Idea 3 (Perf Witness Tickets) predicts perf; this idea measures actual production failures. Overlap: ~15%.

**Versus common industry proposals:**
This is not a generic observability/metrics dashboard (the tired-ideas list warns against that). The key difference: the ledger and scorecards are versioned repo artifacts that feed back into AI tool instruction files, creating a closed loop from production failure → attribution → instruction update → improved AI behavior. Generic dashboards display metrics; this idea changes tool behavior based on metrics. It satisfies heuristics #1 (new inter-tool interface: the rollback ledger + scorecards), #3 (density-research coupling: rollbacks in density components are the highest-cost signal), #4 (Jenkins + K8s leverage), #6 (failure mode as feature: turns rollbacks into per-tool calibration data), and #7 (shared evaluation surface).
