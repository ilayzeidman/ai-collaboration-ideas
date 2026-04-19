# Idea 2: Canary Identifiers — Adversarial Hallucination Traps with a Shared Ledger

## One-line summary
Commit fake-but-plausible identifiers into the repo and scan AI-authored diffs for them to get a shared, per-tool hallucination rate.

## Tags
hallucination-detection, shared-evaluation, density-research, jenkins, rule-file-parity, anti-coordination

## Problem
All four tools hallucinate — they confidently reference functions, package paths, Helm values, or Kubernetes fields that do not exist. On this team, the pain is sharpest in two places: (1) density-research C++/Go diffs where a plausible-sounding `mallctl` knob or `runtime.SetMemoryLimit`-alike can waste a reviewer's day before they realize the symbol is invented, and (2) Helm values and Jenkins shared-library calls, where the wrong-but-plausible path passes local lint and only fails in a nightly pipeline. Today we have no factual, comparable per-tool hallucination rate. Reviewers argue by vibe about which tool is "worse" this week. There is no shared signal a Jenkinsfile or a teammate can test against.

The root cause is that every tool's indexing picks up whatever is in the repo and in open tabs, and the tools will happily extrapolate from that context to identifiers that *should* exist given the naming conventions. We can turn this bug into a measurement.

## Proposal
A committed file `.canaries.jsonl` contains fabricated-but-plausible identifiers the codebase deliberately does not implement. Each record describes (a) the canary token, (b) an "attractor" — a nearby real comment, test stub, or TODO that would tempt an AI to reach for the canary, and (c) which surface it targets (Go package, C++ symbol, Helm value, Jenkinsfile stage, Python module path).

All four tool rule-files (`CLAUDE.md`, `.github/copilot-instructions.md`, `AGENTS.md`, `.cursorrules`) embed a generated "DO_NOT_EMIT" block listing every canary token and the rule: *these identifiers are bait; never emit them; if context seems to require one, stop and ask*. A single source of truth (`.canaries.jsonl`) generates the four blocks via a pre-commit hook (`scripts/render-canary-rules.sh`).

A Jenkins stage, `canary-scan`, runs on every PR. It greps the PR diff for any canary token. The commit trailer (`AI-Tool: claude-code|copilot|codex|cursor|none`) attributes the hit. Hits are appended to a shared append-only ledger `.hallucination-ledger.jsonl` (committed, not a metrics backend — it's versioned alongside the code so any tool can read its own history). The ledger yields a weekly per-tool hallucination rate that any of the four tools can load as context next time it drafts a change.

Canaries rotate: a monthly Jenkins job retires canaries that any human has accidentally cited in real code (they became real or the attractor was bad) and proposes new ones themed around the current density-research push (e.g., a fake `memctl.ReserveBurstPool` when the team is actively tuning jemalloc arenas). This gives the attack surface a fresh signal even as tools memorize old traps.

## Cross-AI-tool design

### Claude Code
- **Role:** Canary author and rotator. Run as a scheduled agent (e.g., `claude -p` invoked by Jenkins monthly) that proposes new canaries in PR form, using the density-research backlog as input. Also the primary tool that *interprets* the ledger when drafting new work, using the per-tool hit history as context to avoid repeating prior team-wide failure patterns.
- **Shared contract it reads/writes:** Reads `.canaries.jsonl`, `.hallucination-ledger.jsonl`, density-research backlog files. Writes proposed canary additions via a PR.
- **Fallback if unavailable:** A Python script (`scripts/propose-canaries.py`) uses a static template to generate candidate canaries from recent PR titles and the density backlog. Lower-quality bait, but the contract holds.

### GitHub Copilot
- **Role:** Primary subject under test. Copilot Coding Agent PRs are the most autonomous and therefore the most likely to emit canaries undetected. Every Copilot-opened PR must carry the `AI-Tool: copilot` trailer. Inline Copilot completions are also scanned via a client-side hook (`scripts/copilot-pre-accept.sh`) that is triggered by a `.github/prompts/check-canaries.prompt.md` prompt file the dev can manually run before merging a big block.
- **Shared contract it reads/writes:** Reads the DO_NOT_EMIT block in `.github/copilot-instructions.md`. Writes into diffs that are then scanned by `canary-scan`.
- **Fallback if unavailable:** If Copilot is off for a dev, the scan still runs against any PR they open with no trailer; trailerless PRs just log under `AI-Tool: unknown` bucket. The ledger keeps accumulating.

### Codex
- **Role:** Task-file-driven verifier. A recurring task file `AGENTS.md` directive instructs Codex runs to, before submitting, run `scripts/canary-scan.sh --staged` locally and refuse to submit if any canary appears. Because Codex is task-file-deterministic, its canary discipline is the cleanest baseline — it acts as the ground-truth "this tool respects the contract" reference against which Copilot and Cursor are compared.
- **Shared contract it reads/writes:** Reads `.canaries.jsonl` via the `AGENTS.md` pointer. Writes a line to `.hallucination-ledger.jsonl` with a `self-caught: true` flag when it catches its own near-miss pre-submit (rare but valuable signal).
- **Fallback if unavailable:** Cloud Codex runner is down: local runners still honor the `AGENTS.md` rule. If no Codex at all, the Jenkins-side `canary-scan` stage is still the gate and catches anything that slips through.

### Cursor
- **Role:** IDE-side real-time warning. `.cursor/rules/canaries.mdc` includes the DO_NOT_EMIT block. Cursor's Chat/Composer, being IDE-tight, is best placed to show a dev the canary list *while they are reviewing an AI suggestion*. A custom command `/check-canaries` (defined in `.cursor/commands/`) runs the same `scripts/canary-scan.sh` against open unsaved buffers, not just the committed diff. This means Cursor users catch hallucinations before they hit git.
- **Shared contract it reads/writes:** Reads `.canaries.jsonl` and `.cursor/rules/canaries.mdc`. Writes to the local buffer only; persistent hits still go through the same commit trailer + Jenkins pipeline.
- **Fallback if unavailable:** The `/check-canaries` command is mirrored as a plain shell script `scripts/canary-scan.sh` any dev can run in a terminal. No IDE, no problem — the gate is the Jenkins stage.

## Languages affected
Python (Jenkins shared-library helpers, scripts), Go (densest canary surface — fake package paths and runtime APIs), Node.js (BFF and CLI tool canaries such as fake config loaders), C++ (density-research memory-knob canaries — highest-leverage target), C (driver-adjacent canaries, e.g., fake syscall wrappers). Also covers YAML (Helm values), Groovy (Jenkinsfile stages). The canary concept is not language-specific; each record names its surface and the scan uses language-appropriate regex rules loaded from `.canaries/rules.d/`.

## Infra impact
- **Jenkins**: new stage `canary-scan` in the shared library, callable as `canaryScan()` from any `Jenkinsfile`. Runs after `build` and before `test`. Non-blocking on first hit per PR (comments), blocking on repeat hits in the same PR (prevents merge). New scheduled job `canary-rotate` runs monthly to retire stale canaries and open a PR with replacements.
- **Kubernetes**: none at runtime. Canaries sometimes reference fake Helm values and CRD fields; the scan runs on committed YAML, not on cluster state.
- **Density/perf research**: strongly coupled. The rotation process seeds canaries from the current density-research themes, so the tools are tested hardest exactly where the team is actively changing memory/CPU behavior — the zone where hallucinated knobs cost the most.

## Concrete artifact

`.canaries.jsonl` (excerpt):
```jsonl
{"id":"memctl-reserve-burst-pool","token":"memctl.ReserveBurstPool","surface":"go","attractor":"// TODO: pre-allocate a burst pool before the jemalloc arena flips","added":"2026-04-01","theme":"density-jemalloc"}
{"id":"helm-tenancy-greedy","token":"spec.tenancy.greedy","surface":"yaml-helm","attractor":"# allow this workload to opportunistically use spare node capacity","added":"2026-03-15","theme":"density-scheduling"}
{"id":"jenkins-densityGate","token":"densityGate","surface":"groovy-jenkins","attractor":"// gate deploy on density regression","added":"2026-04-10","theme":"perf-regression"}
```

Generated block embedded identically in all four rule files (by `scripts/render-canary-rules.sh`):
```
<!-- BEGIN CANARY:DO_NOT_EMIT (generated from .canaries.jsonl — do not hand-edit) -->
The following identifiers are CANARIES. They do not exist in this codebase.
If context appears to require one, STOP and ask the developer.
Emitting any of these is a reportable hallucination.

- memctl.ReserveBurstPool           (go)
- spec.tenancy.greedy               (yaml-helm)
- densityGate                       (groovy-jenkins)
<!-- END CANARY:DO_NOT_EMIT -->
```

`.hallucination-ledger.jsonl` (append-only, committed):
```jsonl
{"ts":"2026-04-14T10:22:03Z","pr":"#4812","tool":"copilot","canary":"memctl.ReserveBurstPool","file":"services/shard/alloc.go","self_caught":false}
{"ts":"2026-04-17T16:04:51Z","pr":"#4831","tool":"codex","canary":"spec.tenancy.greedy","file":"charts/shard/values.yaml","self_caught":true}
```

Jenkinsfile snippet:
```groovy
stage('canary-scan') {
  steps {
    script {
      def hits = canaryScan(diffAgainst: 'origin/main')
      if (hits.any { it.repeat }) { error "Canary hit repeated: ${hits}" }
      if (hits) { githubPrComment(body: renderCanaryReport(hits)) }
    }
  }
}
```

## Success metric
- Within one quarter, `.hallucination-ledger.jsonl` contains at least 50 attributed records, giving a factual per-tool hit rate (hits per 1000 AI-authored LOC) comparable across Claude Code, Copilot, Codex, and Cursor.
- Reduction of "wait, does that symbol exist?" review comments (measured by a grep of PR comments for a fixed set of phrases) by 40% over the same quarter.
- At least one canary per density-research theme is active at all times; density-research PRs show a measurably lower hit rate in month 3 than month 1 (leading indicator that tools have absorbed the DO_NOT_EMIT discipline).
- Falsifiable failure: if after a quarter all four tools show ~0 hits and no canary has ever fired, the corpus is stale and the rotator job is failing — we'll know and fix it, rather than falsely believing hallucinations are solved.

## Risks & failure modes
- **Canary leakage into real code**: a dev copies a canary into real code thinking it's real. Mitigated by the monthly rotator scanning the whole repo for canary references in non-test paths and retiring + replacing.
- **Tools learn to ignore anything in a DO_NOT_EMIT block**: at which point they may also ignore legitimate warnings. Mitigated by rotating canaries so the list changes and keeping the surrounding policy text consistent.
- **Over-indexing on one tool**: if Copilot Coding Agent dominates PR volume, the ledger will overweight it. Mitigated by normalizing the metric per 1000 AI-authored LOC, not per PR.
- **Trailer spoofing / missing attribution**: devs can forget the `AI-Tool:` trailer. Mitigated by a commit-msg hook that prompts for one; unknown-tool hits bucket into `unknown` and are investigated manually only if they spike.
- **Maintenance burden**: the corpus must stay fresh; without rotation it's worthless. The scheduled `canary-rotate` job owns this, and its own failure is alerted via the standard Jenkins health dashboard.
- **Ethical note**: this is deliberately adversarial to the tools. Team should be transparent with vendors that we publish aggregate hit rates internally only.

## Originality statement

**Versus existing ideas in this repo:**
`ideas/SUMMARY.md` currently lists zero scored ideas, so there are no thematically-adjacent prior ideas in this repo to reference. If future ideas propose hallucination detection, shared ledgers, or per-tool scoring, this idea should be cited as prior art.

**Versus common industry proposals:**
This is not any of the tired ideas in `context/originality-guide.md`. It is not a commit-message or PR-summary generator, not a lint/style agent, not a test-gen bot, not a review bot, not a doc generator, not a repo chatbot, not a naïve memory plugin, not a single-tool subagent marketplace, and not a metrics dashboard (the ledger is a versioned file, not a dashboard, though someone could build one on top). The closest adjacent industry pattern is "eval harnesses for LLMs", but those run in labs on held-out datasets; this runs in-repo on real PRs, uses deliberately-planted bait to induce the failure we want to measure, and uses the cross-tool capability asymmetry (Copilot Coding Agent as primary subject, Codex as disciplined baseline, Cursor as in-IDE early warning, Claude Code as rotator) as part of the design rather than treating the tools as interchangeable. It satisfies novelty heuristics #1 (new inter-tool interface: the canary file + ledger + trailer), #3 (density-research coupling via themed canaries), #6 (turns hallucination into measurable, actionable signal), and #7 (shared evaluation surface comparing all four tools on the same code).
