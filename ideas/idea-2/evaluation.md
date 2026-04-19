# Evaluation: Idea 2 — Canary Identifiers: Adversarial Hallucination Traps with a Shared Ledger

## Rubric

Six criteria, weights sum to 1.00. Each criterion scored 1–10. Weighted total = Σ(weight × score), to one decimal place.

| # | Criterion | Weight |
|---|-----------|--------|
| 1 | Originality | 0.35 |
| 2 | Cross-AI-tool feasibility | 0.20 |
| 3 | Multi-language applicability | 0.10 |
| 4 | Long-term maintainability | 0.15 |
| 5 | Implementation simplicity (inverted effort — 10 = trivial) | 0.10 |
| 6 | Workflow impact | 0.10 |

## 1. Originality — Score: 9/10

**Justification:** Honeytoken/canary concepts exist in security (data-exfil detection, honeydocs), but repurposing them as deliberate adversarial bait for AI coding hallucination — coupled with a cross-tool ledger, a commit trailer attribution protocol, and themed rotation seeded from live density-research work — is genuinely new. The idea hits four of the eight novelty heuristics from `context/originality-guide.md` (#1 new inter-tool interface, #3 density-research coupling, #6 failure-mode-as-feature, #7 shared evaluation surface) and matches none of the tired-ideas list. The closest industry analog is LLM eval harnesses, but those are held-out lab benchmarks; running the trap in-repo on real PRs with rotating bait is the distinctive move.

**Evidence from idea.md:** The "Originality statement" section explicitly distinguishes this from the tired list and from standard eval harnesses; the "Proposal" section introduces a novel triplet (canary file + ledger + commit trailer); the "Cross-AI-tool design" assigns differentiated roles rather than forcing uniformity.

**Hard cap check:** No prior ideas exist in this repo (`ideas/SUMMARY.md` shows zero scored ideas). Overlap with prior ideas: 0%. No cap triggered.

## 2. Cross-AI-tool feasibility — Score: 9/10

**Justification:** The core is a shared artifact (`.canaries.jsonl` + `.hallucination-ledger.jsonl`) consumed identically by all four tools, with a parity-file generator emitting a DO_NOT_EMIT block into every rule file from a single source of truth — directly aligned with the positive pattern in `context/cross-tool-principles.md`. Each tool has a concrete, capability-respecting role (Claude Code rotator, Copilot primary subject via Coding Agent, Codex deterministic baseline via `AGENTS.md`, Cursor IDE-tight early warning), exploits rather than flattens capability asymmetry, and specifies graceful degradation per tool plus a Jenkins-side gate as the terminal failsafe. Mild deduction because the "DO_NOT_EMIT" instruction only deters compliant tools — but the Jenkins `canary-scan` stage is the actual gate, so feasibility is preserved if tools ignore the instruction.

**Evidence from idea.md:** The four per-tool subsections (Claude Code, GitHub Copilot, Codex, Cursor) each name a role, the shared contract they read/write, and a fallback; the `scripts/render-canary-rules.sh` generator + identical DO_NOT_EMIT block satisfy instruction-file parity; the Jenkinsfile snippet shows the shared gate.

## 3. Multi-language applicability — Score: 9/10

**Justification:** The canary concept is surface-agnostic — each record names its language/format surface and the scanner loads language-appropriate regex rules from `.canaries/rules.d/`. The "Languages affected" section explicitly covers every team language (Python, Go, Node, C++, C) plus YAML (Helm) and Groovy (Jenkinsfile), matching the full spread in `context/team-stack.md`. The example canaries span Go runtime APIs, Helm values, and Jenkinsfile stages — a cross-language refactor class the team already does in a single PR.

**Evidence from idea.md:** "Languages affected" section; the `.canaries.jsonl` excerpt shows `surface:"go"`, `surface:"yaml-helm"`, `surface:"groovy-jenkins"`; surface-specific regex loading via `.canaries/rules.d/`.

## 4. Long-term maintainability — Score: 7/10

**Justification:** The idea explicitly owns its maintenance cost via the monthly `canary-rotate` Jenkins job, has a built-in falsifiability check (zero hits for a quarter => corpus is stale, not tools fixed), and enumerates the main decay modes (canary leakage, tools memorizing the DO_NOT_EMIT block, trailer spoofing). However, non-trivial ongoing curation is required — the rotator must generate genuinely plausible bait themed to current research, and the list of surfaces/regex rules grows as the stack grows. Model upgrades could shift hallucination surfaces such that old canaries stop firing before the rotator notices. Acceptable long-term cost, but not zero.

**Evidence from idea.md:** "Risks & failure modes" section enumerates maintenance concerns; "Infra impact" section specifies the scheduled `canary-rotate` job; "Success metric" includes the falsifiable-failure clause for stale corpora.

## 5. Implementation simplicity — Score: 5/10

**Justification:** Multi-week integration effort across several surfaces: schema design for `.canaries.jsonl`, `scripts/render-canary-rules.sh` generator + pre-commit hook, a Jenkins shared-library stage `canaryScan()`, per-surface regex rule files, a commit-msg hook for the `AI-Tool:` trailer, the append-only ledger writer, a monthly rotator job (either Claude Code agent or Python fallback), four separate rule-file integrations (CLAUDE.md, copilot-instructions.md, AGENTS.md, .cursorrules/.cursor/rules/), plus Cursor `/check-canaries` command and Copilot prompt file. Each piece is simple, but the count and the cross-tool synchronization burden push effort above average. Not a multi-quarter project, but not a one-afternoon build either.

**Evidence from idea.md:** The "Cross-AI-tool design" section lists per-tool artifacts; "Infra impact" adds Jenkins stage + rotator job; "Concrete artifact" implies the schema work and generator.

## 6. Workflow impact — Score: 8/10

**Justification:** Directly couples to the team's active density-research thread (themed canaries seeded from the jemalloc/density backlog) — the heuristic most prized in `context/team-stack.md`. Converts a recurring, expensive review pattern ("does this symbol even exist?") into a falsifiable pre-merge signal, and provides the first factual per-tool comparison the team has ever had (replacing vibes-based tool debates). Concrete success metrics (50 attributed records/quarter, 40% drop in "does-that-symbol-exist" comments, leading indicator on density PRs) are measurable. Impact is not universal — devs who rarely touch density-research Helm or C++ see smaller gains — hence not a 9 or 10.

**Evidence from idea.md:** "Problem" section names density-research C++/Go and Helm/Jenkins as the two sharpest pain points; "Infra impact > Density/perf research" explicitly couples rotation to active research themes; "Success metric" section lists the measurable outcomes.

## Weighted total

```
(0.35 × 9) + (0.20 × 9) + (0.10 × 9) + (0.15 × 7) + (0.10 × 5) + (0.10 × 8)
= 3.15 + 1.80 + 0.90 + 1.05 + 0.50 + 0.80
= 8.20
```

**Total: 8.2 / 10.0**

## Originality cross-check

No prior ideas — originality judged against industry-common proposals only.

| Prior idea # | Title | Overlap % | Reason |
|--------------|-------|-----------|--------|
| —            | —     | —         | No scored prior ideas in `ideas/SUMMARY.md`. |

## Verdict

**Strong** (≥ 8.0) — worth building.

## Top 3 improvements

If this idea were iterated, the three highest-leverage changes would be:

1. **Front-load the scanner, defer the rule-file parity.** Ship `canary-scan` + the ledger + the commit trailer first with a tiny seed of five canaries, before investing in the four-way rule-file generator. The gate alone establishes measurement; the DO_NOT_EMIT instruction is only the *behavioral* nudge and can follow once the baseline hit-rate is known. This shrinks time-to-first-signal from weeks to days and lowers the implementation-simplicity drag.
2. **Decouple rotation cadence from a single agent.** The monthly rotator is currently framed as "Claude Code agent with a Python fallback". Better: every tool is eligible to propose canaries via a shared `scripts/propose-canaries.py` contract, and the ledger records which tool proposed which bait. That lets the same infrastructure produce a second signal — creativity of bait per tool — without extra machinery, and removes the Claude Code single-point dependency.
3. **Add a "near-miss" class distinct from "emitted".** Cursor's in-IDE check can record cases where the AI *offered* a canary but the dev rejected it before commit. That signal is strictly more informative than post-commit hits (it reveals tool intent without human filtering) and costs little extra — it just needs a second ledger channel (`.hallucination-ledger.jsonl` already has `self_caught`; add `offered_rejected`). Addresses the risk that once DO_NOT_EMIT discipline improves, post-commit hits trend to zero and the ledger stops being informative.
