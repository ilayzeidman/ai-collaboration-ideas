# Team Stack

Factual grounding for any idea this system generates. Every generator and evaluator must read this file before producing or scoring an idea. Keep it current.

## Languages and where they live

| Language | Primary surface area |
|----------|----------------------|
| **Go** | Backend services, API gateways, sidecars, control-plane daemons. Heaviest concentration of shipped code. |
| **Python** | Internal tooling, ML workflows, build/test scripts, data pipelines, Jenkins library helpers. |
| **Node.js** | Frontend apps, BFF layers, developer CLI tools, some automation services. |
| **C++** | Performance-critical services, density-research prototypes, components where memory layout matters. |
| **C** | Low-level drivers, perf-critical primitives, kernel-adjacent code, legacy modules still actively maintained. |

An idea is "multi-language applicable" only if it either works across most of these without per-language rewrites, or explicitly justifies scoping to a subset.

## CI / orchestration

- **Jenkins** is the build and orchestration system. Pipelines are defined in `Jenkinsfile` (declarative + shared library). Any idea that touches CI must describe the Jenkinsfile change concretely.
- Shared Jenkins library provides stage helpers for build/test/lint/deploy. Team convention: one `Jenkinsfile` per repo.

## Deployment

- **Kubernetes** is the deployment target for services. Helm charts in-repo for most services, some use raw manifests.
- Services run multi-tenant on shared clusters; density (how many workloads fit per node) is a first-class KPI.
- Standard K8s objects in use: `Deployment`, `StatefulSet`, `DaemonSet`, `Service`, `ConfigMap`, `Secret`, `HorizontalPodAutoscaler`, `NetworkPolicy`, `PodDisruptionBudget`.

## Active research threads

- **Density research**: reducing CPU and memory footprint of services (especially C++ and Go) so more pods fit per node. Tracked via benchmarks and perf regression tests. Ideas that tie AI tooling to this thread score higher on workflow impact.
- **Perf regression detection**: moving from after-the-fact alerts to earlier signals in the dev loop.

## Team shape

- Developers work across multiple languages in a single week. A single PR may touch Python tooling, a Go service, and a Helm chart.
- Code review is cross-language — an idea that only helps one language has limited reach.
- The team is split across users of four different AI coding tools; consistency of experience across tools is a real pain point.
