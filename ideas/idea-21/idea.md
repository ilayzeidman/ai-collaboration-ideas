# Idea 21: Resource Request Calibrator — AI-Tuned K8s Resource Requests from Production Utilization

## One-line summary
Feed production pod utilization data to AI tools so they propose tighter Kubernetes resource requests, with Jenkins verifying the tightened values in load tests.

## Tags
density-research, kubernetes, jenkins, cross-tool-routing, shared-protocol

## Problem
Kubernetes resource requests (CPU and memory) are the primary lever for pod density: tighter requests = more pods per node. But requests are set conservatively during initial deployment and rarely updated. A service launched with `requests.memory: 2Gi` may actually use 800MB at p99, wasting 1.2GB per pod. Across 50 pods, that's 60GB of wasted node capacity — enough for 30-75 additional pods.

The team knows this gap exists (it's visible in monitoring) but narrowing requests is risky manual work: set them too tight and pods get OOMKilled or throttled. AI tools could analyze utilization data and propose tighter requests, but no protocol exists for them to do so safely — there's no structured input (production data in a format AI tools can read), no verification pipeline (load-test the proposed values before deploying), and no rollback safety net.

## Proposal
Introduce `.resource-calibration/` — a structured pipeline for AI-driven resource request optimization:

1. **Utilization snapshots:** A scheduled job exports production utilization data (CPU/memory p50, p75, p95, p99, max over 7 days) per deployment to `.resource-calibration/utilization/<deployment>.json`. This makes production data accessible to AI tools as a repo artifact.
2. **Proposal generation:** AI tools read utilization snapshots and current Helm chart values, then propose tightened resource requests in `.resource-calibration/proposals/<deployment>.yaml`. Each proposal includes: current values, proposed values, the utilization data justifying the change, the expected density improvement (pods-per-node delta), and a safety margin percentage.
3. **Load test verification:** A Jenkins job `resource-calibrate-verify` applies proposed values to a staging deployment, runs the standard load test suite, and records the results (OOM events, CPU throttle events, latency impact) to `.resource-calibration/results/<deployment>.jsonl`.
4. **Promotion:** Proposals that pass load tests (zero OOM, throttle rate below threshold, latency within SLA) are auto-promoted to a PR updating the Helm chart. Proposals that fail are logged with failure reasons.
5. **Feedback loop:** Actual production behavior after deployment is compared to the proposal predictions, calibrating the safety margin for future proposals.

## Cross-AI-tool design

### Claude Code
- **Role:** Sophisticated proposal generator. Claude Code reads utilization snapshots, Helm charts, and historical calibration results to generate nuanced proposals. It considers workload patterns (burst vs. steady-state, diurnal cycles), cross-service dependencies, and historical OOM events. A custom command (`/.claude/commands/calibrate-resources.md`) generates proposals for a specified deployment.
- **Shared contract it reads/writes:** Reads `.resource-calibration/utilization/`, Helm charts, and historical results. Writes proposals to `.resource-calibration/proposals/`.
- **Fallback if unavailable:** `scripts/propose-resource-calibration.py` generates conservative proposals using simple percentile-based rules (p99 + 20% margin).

### GitHub Copilot
- **Role:** Helm chart updater. When a proposal is promoted, Copilot Coding Agent can be tasked with updating the Helm chart values and opening the PR. `.github/prompts/resource-calibrate.prompt.md` provides a guided proposal-to-PR workflow.
- **Shared contract it reads/writes:** Reads promoted proposals. Writes Helm chart updates as PRs.
- **Fallback if unavailable:** Developer updates Helm chart manually from the promoted proposal.

### Codex
- **Role:** Load test executor. `AGENTS.md` includes a resource-calibration verification task template. When a proposal is submitted, Codex applies the proposed values to a staging environment and runs the full load test suite deterministically. Its deterministic execution ensures consistent load test results.
- **Shared contract it reads/writes:** Reads proposals and `AGENTS.md`. Runs load tests. Writes results to `.resource-calibration/results/`.
- **Fallback if unavailable:** Jenkins runs load tests directly. Codex's value is deterministic local pre-test.

### Cursor
- **Role:** IDE utilization visualizer. `.cursor/rules/resource-calibration.mdc` instructs Cursor to display current utilization data and active proposals when the developer opens a Helm chart's values.yaml. A custom command `/resource-calibrate <deployment>` shows the gap between current requests and actual utilization, motivating action.
- **Shared contract it reads/writes:** Reads utilization snapshots and proposals. Displays in IDE.
- **Fallback if unavailable:** `scripts/show-utilization-gap.sh <deployment>` from terminal.

## Languages affected
The protocol itself is language-agnostic (YAML proposals, JSON utilization, Helm charts). It affects all services regardless of language — Go services, Python services, Node.js BFFs, C++/C components. The density impact varies by language: Go and C++ services tend to have the largest request-vs-utilization gaps due to conservative initial sizing. Python services have more predictable memory patterns.

## Infra impact
- **Jenkins:** New scheduled job `resource-utilization-export` that queries monitoring and exports utilization to the repo. New verification job `resource-calibrate-verify` that runs load tests with proposed values. Both run off-peak.
- **Kubernetes:** Reads Prometheus/monitoring data for utilization. Applies proposed values to staging deployments for load testing. No new K8s objects — modifies existing Helm values.
- **Density/perf research:** Core density mechanism. Resource request calibration is the most direct lever for pod density improvement. Tightening requests by 20% across the fleet could increase pods-per-node by 10-25%.

## Concrete artifact

`.resource-calibration/utilization/shard-api.json`:
```json
{
  "deployment": "shard-api",
  "period": "2026-04-12T00:00:00Z/2026-04-19T00:00:00Z",
  "cpu": {
    "current_request": "500m",
    "p50": "180m", "p75": "240m", "p95": "310m", "p99": "380m", "max": "450m"
  },
  "memory": {
    "current_request": "2Gi",
    "p50": "620Mi", "p75": "710Mi", "p95": "800Mi", "p99": "850Mi", "max": "920Mi"
  },
  "replicas": { "current": 12, "min_hpa": 8, "max_hpa": 20 },
  "oom_events_7d": 0,
  "throttle_events_7d": 3
}
```

`.resource-calibration/proposals/shard-api.yaml`:
```yaml
proposal_id: calibrate-shard-api-2026-04-19
deployment: shard-api
tool: claude-code
timestamp: "2026-04-19T14:00:00Z"

current:
  cpu_request: "500m"
  memory_request: "2Gi"

proposed:
  cpu_request: "400m"   # p99 380m + 5% margin
  memory_request: "1Gi" # p99 850Mi + 18% margin

justification: "p99 CPU is 380m (76% of 500m request), p99 memory is 850Mi (42% of 2Gi request). Memory is most over-provisioned. Propose 1Gi with 18% margin above p99."
expected_density_improvement:
  pods_per_node_pct: 15.0
  memory_saved_per_pod: "1Gi"
  total_fleet_memory_saved: "12Gi (12 pods × 1Gi)"

safety_margin_pct: 18
load_test_required: true
```

Jenkins verification:
```groovy
stage('resource-calibrate-verify') {
  steps {
    script {
      def result = resourceCalibrateVerify(
        proposal: ".resource-calibration/proposals/${DEPLOYMENT}.yaml",
        loadTest: "tests/load/${DEPLOYMENT}_load.sh"
      )
      if (result.oomEvents > 0 || result.throttleRate > 0.05) {
        error("Calibration failed: ${result.summary}")
      }
      archiveArtifacts artifacts: ".resource-calibration/results/${DEPLOYMENT}.jsonl"
    }
  }
}
```

## Success metric
- ≥5 deployments calibrated in the first quarter, each reducing memory requests by ≥20%.
- Fleet-wide memory request reduction of ≥15%, directly translating to more pods-per-node.
- Zero OOM events or SLA violations from calibrated deployments within 30 days of rollout.
- Per-tool proposal accuracy (predicted vs. actual density improvement) becomes trackable, enabling data-driven tool selection for calibration tasks.

## Risks & failure modes
- **OOMKill from too-tight requests:** The primary risk. Mitigated by mandatory load test verification, conservative safety margins, and a 30-day monitoring period before declaring success.
- **Workload pattern changes:** Utilization patterns may shift (e.g., seasonal traffic). Mitigated by using 7-day rolling windows and re-calibrating quarterly.
- **Staging vs. production divergence:** Load tests may not reproduce production load patterns. Mitigated by using production traffic replay where available and calibrating safety margins based on staging-vs-prod historical deltas.
- **Monitoring data access:** Exporting utilization to the repo requires monitoring API access from CI. Mitigated by a dedicated service account with read-only access.

## Originality statement

**Versus existing ideas in this repo:**
Idea 3 (Perf Witness Tickets) predicts per-PR perf impact; this idea optimizes fleet-wide resource requests from historical data — different granularity (PR vs. deployment) and different data source (predictions vs. production utilization). Idea 7 (Memory Budget Annotations) sets per-function budgets; this sets per-deployment budgets from production data. Idea 17 (Speculative Density Queue) generates code patches; this adjusts infrastructure configuration. Overlap with ideas 3, 7, 17: each ~15%.

**Versus common industry proposals:**
Kubernetes resource recommendation tools exist (VPA, Goldilocks), but they are single-tool, non-AI-aware, and don't integrate into a cross-tool workflow with load-test verification and AI-driven proposal generation. This idea routes production data through AI tools for nuanced proposals (considering burst patterns, cross-service dependencies, historical OOM events) and verifies in CI before applying. It satisfies heuristics #1 (new inter-tool interface: the calibration pipeline), #2 (capability asymmetry: Claude proposes, Codex verifies, Copilot applies, Cursor displays), #3 (density-research coupling: this IS the pod density improvement mechanism), and #4 (Jenkins + K8s leverage: uses existing infrastructure end-to-end).
