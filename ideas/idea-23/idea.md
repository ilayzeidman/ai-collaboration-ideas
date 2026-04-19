# Idea 23: Build Graph Advisor — AI-Optimized Jenkins Pipeline Parallelism from Dependency Analysis

## One-line summary
AI tools analyze build dependency graphs and propose optimized Jenkins stage ordering and parallelism, verified by comparing pipeline wall-clock times.

## Tags
jenkins, cross-tool-routing, shared-protocol, multi-language, density-research

## Problem
The team's Jenkins pipelines grow organically. Stages are added in order of discovery, not optimal dependency order. Build and test stages that could run in parallel run sequentially because nobody has time to analyze the dependency graph and restructure the Jenkinsfile. A Go service build waits for an unrelated Python lint step to finish; C++ compilation blocks Node.js tests that have no dependency on the binary.

The result: CI wall-clock time is 30-60% longer than necessary. This slows the feedback loop for every developer, delays density-research benchmark results, and wastes Jenkins agent hours. The team's Jenkinsfile convention (one per repo, shared library stages) makes parallelism possible but under-utilized.

## Proposal
Introduce `.build-graph/` — a structured representation of the build dependency graph that AI tools analyze to propose optimal pipeline configurations:

1. **Graph extraction:** A script (`scripts/extract-build-graph.sh`) analyzes the Jenkinsfile, Makefiles, and build scripts to produce `.build-graph/current.json` — a DAG of build stages, their dependencies (which stage needs which stage's output), and their measured durations (from Jenkins build history).
2. **Optimization proposal:** AI tools read the graph and propose an optimized Jenkinsfile configuration: `.build-graph/proposals/<proposal-id>.yaml` containing recommended parallel groups, stage reordering, and the expected wall-clock time savings.
3. **Verification:** A Jenkins job `build-graph-verify` runs the proposed configuration on a representative set of recent PRs (replayed from build history) and compares wall-clock times against the current configuration. Results are recorded in `.build-graph/results/<proposal-id>.jsonl`.
4. **Promotion:** Proposals that demonstrate ≥10% wall-clock improvement are auto-promoted to a PR updating the Jenkinsfile.

## Cross-AI-tool design

### Claude Code
- **Role:** Graph analyzer and optimization strategist. Claude Code's multi-file analysis excels at tracing build dependencies across languages (Go build → C++ compile → link → test → Python integration test). A custom command (`/.claude/commands/optimize-build-graph.md`) reads the current graph and proposes an optimized configuration. Claude Code considers edge cases (flaky stages, resource contention on shared agents).
- **Shared contract it reads/writes:** Reads `.build-graph/current.json`. Writes proposals to `.build-graph/proposals/`. Reads historical results.
- **Fallback if unavailable:** `scripts/suggest-parallel-groups.py` uses a simple topological sort to propose parallelism. Less sophisticated but functional.

### GitHub Copilot
- **Role:** Jenkinsfile editor. When a proposal is promoted, Copilot's Jenkinsfile editing capability (Coding Agent or inline) applies the changes. `.github/prompts/build-graph-apply.prompt.md` provides a structured prompt for applying graph optimizations to the Jenkinsfile. Copilot's understanding of Groovy/Jenkinsfile syntax makes it the fastest editor for this format.
- **Shared contract it reads/writes:** Reads promoted proposals. Writes Jenkinsfile updates as PRs.
- **Fallback if unavailable:** Developer edits Jenkinsfile manually from the proposal.

### Codex
- **Role:** Graph extraction and verification executor. `AGENTS.md` includes tasks for both extracting the build graph (`scripts/extract-build-graph.sh`) and verifying proposals (replaying builds with proposed configuration). Codex's deterministic execution ensures consistent benchmark comparisons.
- **Shared contract it reads/writes:** Reads `AGENTS.md`. Writes `.build-graph/current.json` and verification results.
- **Fallback if unavailable:** Jenkins runs extraction and verification directly.

### Cursor
- **Role:** IDE build graph visualizer. `.cursor/rules/build-graph.mdc` instructs Cursor to display the build dependency graph when the developer opens a Jenkinsfile. A custom command `/build-graph` shows the current graph, highlighting sequential stages that could be parallelized. Cursor's visual display helps developers understand the optimization opportunity.
- **Shared contract it reads/writes:** Reads `.build-graph/current.json` and proposals. Displays in IDE.
- **Fallback if unavailable:** `scripts/show-build-graph.sh` renders a text-based graph from the terminal.

## Languages affected
All five — the build graph spans all language build systems: `go build`/`go test`, C++/C compilation (make/cmake), Python lint/test (pytest, mypy), Node.js build/test (npm run build, jest), and the cross-language integration tests. The graph captures dependencies across languages (e.g., C++ library must compile before Go cgo-dependent test). Language-specific build steps are the nodes; the idea is about their ordering and parallelism.

## Infra impact
- **Jenkins:** Core infrastructure change. Graph extraction reads Jenkinsfile and build history (API calls to Jenkins). Verification replays builds with modified stage ordering. Promotion modifies the Jenkinsfile. The verification job uses existing agents. Wall-clock time improvement directly reduces agent utilization.
- **Kubernetes:** No runtime impact.
- **Density/perf research:** Indirect but valuable — faster CI means faster density-research benchmark feedback loops. A 30% CI time reduction means density patches (idea 17) get tested 30% faster.

## Concrete artifact

`.build-graph/current.json`:
```json
{
  "stages": [
    {"name": "go-build", "duration_avg_s": 120, "deps": []},
    {"name": "cpp-compile", "duration_avg_s": 180, "deps": []},
    {"name": "python-lint", "duration_avg_s": 45, "deps": []},
    {"name": "node-build", "duration_avg_s": 60, "deps": []},
    {"name": "go-test", "duration_avg_s": 90, "deps": ["go-build"]},
    {"name": "cpp-test", "duration_avg_s": 150, "deps": ["cpp-compile"]},
    {"name": "python-test", "duration_avg_s": 120, "deps": ["python-lint"]},
    {"name": "node-test", "duration_avg_s": 75, "deps": ["node-build"]},
    {"name": "cgo-integration", "duration_avg_s": 60, "deps": ["go-build", "cpp-compile"]},
    {"name": "canary-scan", "duration_avg_s": 15, "deps": ["go-build", "cpp-compile", "node-build"]},
    {"name": "perf-witness", "duration_avg_s": 300, "deps": ["go-test", "cpp-test"]}
  ],
  "current_wall_clock_s": 1065,
  "theoretical_critical_path_s": 660
}
```

`.build-graph/proposals/parallel-v1.yaml`:
```yaml
proposal_id: parallel-v1
tool: claude-code
timestamp: "2026-04-19T14:00:00Z"

parallel_groups:
  - group: 1
    stages: [go-build, cpp-compile, python-lint, node-build]
    max_wall_clock_s: 180  # limited by cpp-compile
  - group: 2
    stages: [go-test, cpp-test, python-test, node-test, cgo-integration, canary-scan]
    max_wall_clock_s: 150  # limited by cpp-test
  - group: 3
    stages: [perf-witness]
    max_wall_clock_s: 300

expected_wall_clock_s: 630
improvement_pct: 40.8
```

Optimized Jenkinsfile snippet:
```groovy
stage('Build & Lint') {
  parallel {
    stage('go-build') { steps { goBuild() } }
    stage('cpp-compile') { steps { cppCompile() } }
    stage('python-lint') { steps { pythonLint() } }
    stage('node-build') { steps { nodeBuild() } }
  }
}
stage('Test & Scan') {
  parallel {
    stage('go-test') { steps { goTest() } }
    stage('cpp-test') { steps { cppTest() } }
    stage('python-test') { steps { pythonTest() } }
    stage('node-test') { steps { nodeTest() } }
    stage('cgo-integration') { steps { cgoIntegration() } }
    stage('canary-scan') { steps { canaryScan() } }
  }
}
stage('Perf Witness') { steps { perfWitness() } }
```

## Success metric
- CI wall-clock time decreases by ≥25% for the main pipeline after the first accepted proposal.
- Jenkins agent hours consumed per PR decrease by ≥10% (better parallelism → less agent idle time).
- Density-research benchmark feedback loops accelerate proportionally (faster CI → faster density patch testing).
- At least 2 optimization proposals are promoted per quarter as the codebase evolves.

## Risks & failure modes
- **Agent resource contention:** More parallel stages may compete for limited Jenkins agents, reducing the actual speedup. Mitigated by the verification job testing on real agent pools and measuring actual wall-clock times, not theoretical.
- **Flaky stages:** Parallelism may expose timing-dependent flakiness. Mitigated by quarantining flaky stages (running them sequentially) and gradually moving them to parallel as they stabilize.
- **Graph staleness:** The build graph changes as new stages are added. Mitigated by re-extracting the graph weekly and re-optimizing when it changes significantly.
- **Jenkinsfile complexity:** Highly parallel Jenkinsfiles are harder to read and debug. Mitigated by generating clean, well-commented Groovy with clear parallel groups.

## Originality statement

**Versus existing ideas in this repo:**
No prior idea addresses CI pipeline optimization. Idea 2 (Canary Identifiers) adds a Jenkins stage; idea 3 (Perf Witness) adds a Jenkins stage; this idea optimizes the *pipeline structure itself*. Overlap with ideas 2, 3: ~10% each (shared Jenkins surface).

**Versus common industry proposals:**
Jenkins Pipeline optimization is a known practice, but AI-driven build graph analysis with cross-tool proposal generation, A/B verification on real builds, and automated Jenkinsfile updates is novel. Existing tools (Jenkins Blue Ocean, Pipeline Stage View) visualize pipelines but don't propose optimizations. This idea uses AI tools to analyze the dependency graph and generate better parallelism — a cross-tool collaboration on infrastructure optimization, not code. It satisfies heuristics #1 (new inter-tool interface: the build graph protocol), #2 (capability asymmetry: Claude analyzes, Codex extracts/verifies, Copilot edits Jenkinsfile, Cursor visualizes), #4 (Jenkins leverage: optimizing the CI system the team already owns), and #5 (language-stack specificity: the five-language build graph is the reason parallelism is under-utilized).
