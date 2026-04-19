# Idea 3: Perf Witness Tickets — Predict-Then-Verify Density Claims Per PR

## One-line summary
Require each AI-authored PR to carry a perf witness ticket that predicts and verifies pod-density impact in Jenkins before merge.

## Tags
density-research, perf-regression, jenkins, kubernetes, shared-protocol, cross-tool-routing, multi-language

## Problem
The team’s biggest late-stage failures are not syntax bugs; they are performance surprises discovered after merge. A Copilot-authored Node.js BFF change can increase request fan-out and memory, while a Codex-authored C++ allocator tweak can shift RSS under load, and neither change is compared against a common prediction contract before CI runs expensive benchmarks. Reviewers get prose like “should be faster,” but no machine-checkable claim.

Because tools are used unevenly across the stack (Cursor in frontend, Claude Code in terminal-heavy perf work, Copilot in PR flow, Codex in scripted tasks), performance intent is fragmented across chats, commit messages, and local notes. Jenkins catches regressions, but too late and without attribution of which tool predicted what. We need one shared artifact that all tools can write and Jenkins can verify.

## Proposal
Introduce a required repo artifact: `perf-witness/tickets/<branch>.json`. Every AI-assisted PR adds one ticket that declares predicted CPU/memory/latency impact for touched services, the benchmark commands to run, and the expected pod-density delta under existing Kubernetes requests/limits.

Jenkins adds a `perf-witness` stage that:
1. validates ticket schema,
2. executes listed benchmark commands,
3. runs a lightweight packing simulation from current Helm values (`resources.requests/limits`),
4. writes observed results to `perf-witness/history.jsonl`,
5. fails merge when absolute prediction error exceeds threshold without an explicit waiver.

The key protocol is “predict first, verify on the same fields.” This makes AI suggestions comparable across tools and turns perf claims into measurable data tied to real CI outcomes.

## Cross-AI-tool design

### Claude Code
- **Role:** Ticket strategist for backend/perf-sensitive diffs; drafts high-fidelity predictions for Go/C++/C changes and proposes benchmark command sets.
- **Shared contract it reads/writes:** Reads `perf-witness/schema.json` and `perf-witness/history.jsonl`; writes `perf-witness/tickets/<branch>.json`.
- **Fallback if unavailable:** Developer runs `python scripts/new_perf_ticket.py --from-diff` to scaffold the same ticket fields manually.

### GitHub Copilot
- **Role:** PR bootstrapper; when opening a Coding Agent PR, it must include an initial perf witness ticket linked in the PR description.
- **Shared contract it reads/writes:** Reads `.github/prompts/perf-witness.prompt.md` and `perf-witness/schema.json`; writes/updates the same ticket file in branch.
- **Fallback if unavailable:** Ticket is created from CLI scaffold script; Jenkins still enforces presence and schema regardless of tool.

### Codex
- **Role:** Deterministic verifier; executes the exact benchmark commands listed in the ticket locally before submit and amends predicted confidence fields.
- **Shared contract it reads/writes:** Reads `AGENTS.md` instructions plus the ticket; writes updated confidence and preflight timings into ticket metadata.
- **Fallback if unavailable:** Jenkins remains source of truth for verification; local preflight step is skipped but merge gate still applies.

### Cursor
- **Role:** IDE guardrail; checks whether edited files map to a ticket component and flags missing coverage during Compose/Chat edits.
- **Shared contract it reads/writes:** Reads `.cursor/rules/perf-witness.mdc`, `perf-witness/component-map.yaml`, and the ticket file; writes missing-component suggestions into the ticket.
- **Fallback if unavailable:** `scripts/check_perf_ticket_coverage.py` runs in pre-commit and CI to detect uncovered changed paths.

## Languages affected
Python (ticket scaffolding and validation scripts), Go/C++/C (primary density-sensitive services and allocators), Node.js (BFF/service latency and memory behavior). The ticket protocol itself is language-agnostic JSON, but each language contributes benchmark commands and expected metrics using the same schema, so no per-language rewrite of the core mechanism is needed.

## Infra impact
- **Jenkins:** Add `perfWitnessValidate()` and `perfWitnessVerify()` shared-library steps in a new `perf-witness` stage before merge.
- **Kubernetes:** No new cluster objects; pipeline reads existing Helm chart resource requests/limits and deployment replica defaults to run packing simulation.
- **Density/perf research:** Directly supports active density research by producing per-PR predicted vs observed density deltas as a versioned dataset.

## Concrete artifact

```json
// perf-witness/tickets/feature-shard-cache.json
{
  "schema_version": "1.0",
  "pr": "feature/shard-cache",
  "tool_attribution": {
    "authoring_tool": "copilot",
    "review_tool": "claude-code"
  },
  "components": [
    {
      "name": "services/shard-api",
      "languages": ["go", "c++"],
      "benchmarks": [
        "go test ./services/shard-api/... -bench=. -run=^$",
        "./bench/allocator_bench --scenario=burst"
      ],
      "predicted": {
        "p95_latency_pct": -6.0,
        "rss_mb_pct": -4.5,
        "pods_per_node_pct": 8.0
      },
      "max_abs_error_pct": 5.0
    }
  ]
}
```

```groovy
stage('perf-witness') {
  steps {
    script {
      perfWitnessValidate(ticket: "perf-witness/tickets/${env.BRANCH_NAME}.json")
      def result = perfWitnessVerify(ticket: "perf-witness/tickets/${env.BRANCH_NAME}.json")
      archiveArtifacts artifacts: 'perf-witness/history.jsonl', onlyIfSuccessful: false
      if (result.blocking) { error("Perf witness error too high: ${result.summary}") }
    }
  }
}
```

## Success metric
- 90% of AI-assisted PRs touching runtime code include valid tickets within 6 weeks.
- Prediction error (absolute) for `rss_mb_pct` and `pods_per_node_pct` drops below 7% median after 2 months as tools learn from history.
- Perf regressions detected post-merge (outside PR CI) decrease by 30% quarter-over-quarter.
- At least one weekly report compares prediction accuracy by tool attribution on the same metric fields.

## Risks & failure modes
- Developers may game predictions to pass thresholds; mitigate with periodic threshold recalibration and random manual audits.
- Benchmark commands can become flaky across languages; require command health checks and quarantine labels in Jenkins.
- Ticket maintenance burden may rise if schema grows too quickly; keep schema versioned and additive with migration tooling.
- Tool attribution can be noisy on mixed-tool PRs; allow multiple attribution fields and treat results as directional, not absolute ranking.
- If Kubernetes resource specs are stale, density simulation misleads; add a warning when chart values and production baselines diverge.

## Originality statement

**Versus existing ideas in this repo:**
Compared with Idea 2 (Canary Identifiers), this idea does not trap hallucinated symbols or measure invalid-token emission. It introduces a predict-then-verify performance contract for real changes, focused on density and perf regression outcomes. Overlap is limited to shared use of Jenkins and cross-tool attribution, while the core artifact, failure mode, and metrics are different.

**Versus common industry proposals:**
This is not a PR summarizer, commit-message bot, generic lint/test generator, or generic review bot from the tired-ideas list. It proposes a new shared protocol (`perf-witness` ticket + verify stage) that all four tools must write/read, explicitly exploits capability asymmetry (Copilot PR bootstrap, Codex deterministic preflight, Cursor IDE coverage checks, Claude perf-strategy authoring), and ties directly to the team’s density-research thread rather than generic developer productivity claims.
