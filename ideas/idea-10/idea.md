# Idea 10: Dependency Alibi Log — Append-Only Attribution for AI-Suggested Dependencies

## One-line summary
Record which AI tool proposed each dependency addition with rationale in an append-only ledger, enabling post-incident blame-free dependency audits.

## Tags
shared-protocol, cross-tool-routing, supply-chain, jenkins

## Problem
AI tools suggest dependency additions freely — a Copilot completion pulls in a new npm package, Claude Code adds a Go module for a utility function, Cursor's Agent mode introduces a Python library. These suggestions are accepted without recording *why* the dependency was added or *which tool* suggested it. When a dependency later causes a security incident, license conflict, or binary-size regression, the team has no record of the decision chain. Worse, they can't distinguish between deliberate human dependency choices and AI-suggested ones, making it impossible to evaluate whether a specific tool's dependency suggestions are trustworthy.

The package manager lock files record *what* was added, but not *why* or *by whom* (human vs. AI tool). This gap becomes critical at scale: the team adds 5-10 dependencies per month across five languages, and the fraction suggested by AI tools is growing.

## Proposal
Introduce `.dependency-alibis/log.jsonl` — an append-only ledger where every AI-assisted dependency addition is recorded before the dependency is committed. Each record contains:

1. **Package:** name, version, ecosystem (npm/go/pip/conan/apt).
2. **Tool:** which AI tool suggested the addition.
3. **Rationale:** the tool's stated reason for suggesting this dependency.
4. **Alternatives considered:** other packages the tool considered and rejected (if available).
5. **Size/security snapshot:** binary size impact estimate, known CVEs at time of addition.
6. **Developer decision:** accepted/modified/rejected, with developer's note.

All four tool rule files include the directive: "When suggesting a new dependency, check `.dependency-alibis/log.jsonl` for prior decisions on the same or similar packages. If adding a new dependency, append a record before committing."

A Jenkins stage `dependency-alibi-check` runs on every PR that modifies a lock file (package-lock.json, go.sum, requirements.txt, etc.). It verifies that every new dependency in the lock file has a corresponding alibi record. Missing records trigger a blocking warning.

## Cross-AI-tool design

### Claude Code
- **Role:** Dependency analyst and alibi author. Claude Code's terminal agentic mode is ideal for running `npm audit`, `go mod why`, `pip-audit`, and other analysis tools to populate the security/size snapshot fields. A custom command (`/.claude/commands/add-dependency.md`) wraps the alibi-recording workflow: analyze, record, then install.
- **Shared contract it reads/writes:** Reads/writes `.dependency-alibis/log.jsonl`. Reads `CLAUDE.md` alibi rules.
- **Fallback if unavailable:** Developer manually appends a record using `scripts/record-dependency-alibi.sh <package> <reason>`. Jenkins enforces presence.

### GitHub Copilot
- **Role:** Inline alibi prompter. When Copilot suggests an import that implies a new dependency, `.github/copilot-instructions.md` includes: "If this import introduces a new dependency, note it in `.dependency-alibis/log.jsonl`." Copilot Coding Agent PRs must include alibi records for any new dependencies. `.github/prompts/dependency-alibi.prompt.md` provides a structured recording prompt.
- **Shared contract it reads/writes:** Reads `.dependency-alibis/log.jsonl` for prior decisions. Writes alibi records in PRs.
- **Fallback if unavailable:** Jenkins catches missing alibis. Developer uses CLI script.

### Codex
- **Role:** Pre-submit alibi verifier. `AGENTS.md` instructs Codex to run `scripts/check-dependency-alibis.sh` before submitting any task that modifies lock files. If alibis are missing, Codex must create them before submitting. Codex's task-file determinism ensures compliance.
- **Shared contract it reads/writes:** Reads lock files and `.dependency-alibis/log.jsonl`. Writes missing alibi records.
- **Fallback if unavailable:** Jenkins is the gate. Alibi check runs regardless.

### Cursor
- **Role:** IDE-integrated dependency awareness. `.cursor/rules/dependency-alibis.mdc` instructs Cursor to check the alibi log when the developer adds an import for an uninstalled package. A custom command `/dep-alibi` records an alibi interactively. Cursor's real-time editing context makes it the best surface for catching dependency additions at the moment of suggestion.
- **Shared contract it reads/writes:** Reads `.dependency-alibis/log.jsonl`. Writes alibi records during editing sessions.
- **Fallback if unavailable:** CLI script or Jenkins gate.

## Languages affected
All five ecosystems: npm (Node.js), Go modules, pip (Python), Conan/apt (C++), and apt/manual (C). The alibi protocol is ecosystem-agnostic (JSONL records keyed by package name and ecosystem). Lock file detection is per-ecosystem: `package-lock.json`, `go.sum`, `requirements.txt`/`poetry.lock`, `conanfile.txt`, etc.

## Infra impact
- **Jenkins:** New stage `dependency-alibi-check` in the shared library. Runs when lock files change. Compares lock file diff to alibi log entries. Blocking on missing alibis. Adds <10 seconds (diffstat comparison).
- **Kubernetes:** No runtime impact.
- **Density/perf research:** Indirect benefit — catches dependencies that increase binary size or memory footprint, which are density-relevant. The alibi's size-impact field directly supports density-aware dependency decisions.

## Concrete artifact

`.dependency-alibis/log.jsonl`:
```jsonl
{"ts":"2026-04-15T09:00:00Z","package":"github.com/jemalloc/jemalloc-go","version":"v0.4.2","ecosystem":"go","tool":"claude-code","rationale":"Need cgo bindings for jemalloc arena management in density-critical shard allocator","alternatives":["manual mmap (rejected: too low-level)","tcmalloc (rejected: less arena control)"],"size_impact_kb":340,"cves":[],"developer":"alice","decision":"accepted","note":"Core density-research dependency"}
{"ts":"2026-04-17T14:30:00Z","package":"lodash","version":"4.17.21","ecosystem":"npm","tool":"copilot","rationale":"Utility functions for object deep-merge in BFF config handling","alternatives":["ramda (rejected: heavier)","native spread (rejected: doesn't deep-merge)"],"size_impact_kb":72,"cves":["CVE-2021-23337 (fixed in this version)"],"developer":"bob","decision":"accepted","note":"Pinned to patched version"}
```

Jenkins stage:
```groovy
stage('dependency-alibi-check') {
  when { changeset pattern: '**/package-lock.json,**/go.sum,**/requirements.txt,**/poetry.lock', comparator: 'GLOB' }
  steps {
    script {
      def missing = dependencyAlibiCheck(log: '.dependency-alibis/log.jsonl')
      if (missing) { error("Missing dependency alibis: ${missing.packages.join(', ')}. Record before merge.") }
    }
  }
}
```

## Success metric
- 100% of AI-suggested dependency additions have alibi records within 6 weeks, measured by Jenkins block rate trending to zero.
- Post-incident dependency audit time drops by 80% (from hours of git-blame archaeology to reading the alibi log).
- At least one dependency suggestion is rejected per month based on alibi log analysis (alternatives, CVEs, size impact), demonstrating the log's decision-support value.
- Per-tool dependency suggestion quality becomes measurable: which tool's suggestions lead to more CVE hits or size bloat.

## Risks & failure modes
- **Alibi quality:** Tools may write vague rationales ("needed for the task"). Mitigated by requiring the structured fields (alternatives, size impact) and auditing quality periodically.
- **Adoption friction:** Developers skip the alibi step. Mitigated by Jenkins blocking and IDE-integrated recording.
- **Lock file churn:** Transitive dependency updates flood the log. Mitigated by scoping alibis to direct dependencies only (not transitive).
- **Ecosystem coverage gaps:** Some languages (C/C++) lack standardized lock files. Mitigated by supporting manual lock file patterns and Conan/apt tracking.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) attributes hallucinations per tool; idea 11 (Rollback Fingerprinting, if it exists) would attribute rollbacks. This idea attributes *dependency decisions* — a different surface entirely. The tool-attribution pattern is shared (~15% overlap with idea 2), but the artifact (dependency alibi log vs. hallucination ledger), the failure mode (supply-chain risk vs. hallucination), and the CI check (lock-file comparison vs. canary scan) are all different.

**Versus common industry proposals:**
This is not an "AI that writes better commit messages" or a generic dependency scanner. Dependency audit tools (Dependabot, Snyk) detect vulnerabilities; this idea records *why a dependency was added* and *who suggested it*, which no current tool does. It creates an attributable decision trail specifically for AI-suggested dependencies — a novel cross-tool protocol. It satisfies heuristics #1 (new inter-tool interface: the alibi log), #2 (capability asymmetry: Claude analyzes, Copilot prompts, Codex verifies, Cursor warns), and #6 (failure mode as feature: turns supply-chain risk into attributable, measurable signal).
