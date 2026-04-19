# Idea 6: Drift Sentinel — Continuous Parity Enforcement for AI Rule Files from a Single Source of Truth

## One-line summary
Generate all four AI instruction files from one canonical YAML and block PRs that introduce rule-file drift via a Jenkins gate.

## Tags
rule-file-parity, jenkins, shared-protocol, cross-tool-routing, anti-coordination

## Problem
The team maintains four instruction files — `CLAUDE.md`, `.github/copilot-instructions.md`, `AGENTS.md`, and `.cursorrules` — that must stay synchronized. In practice, they drift. A developer using Claude Code adds a new rule to `CLAUDE.md` and forgets the other three. A Cursor user updates `.cursorrules` with a convention that nobody replicates. Within weeks, tools give inconsistent guidance: Claude Code enforces a naming convention that Copilot has never heard of, or Cursor applies a review checklist that Codex ignores.

The `cross-tool-principles.md` explicitly calls out instruction drift as an anti-pattern, yet there is no automated enforcement. Developers are expected to manually keep four files in sync — a process that fails as soon as the team is busy.

## Proposal
Introduce `.ai-rules/source.yaml` as the single source of truth for all AI tool instructions. This YAML file contains structured sections: global rules, per-language rules, per-tool overrides (for capability-specific directives), and pointers to generated blocks (like canary DO_NOT_EMIT lists from idea 2).

A generator script (`scripts/render-ai-rules.sh`) reads `source.yaml` and emits the four tool-specific files using per-tool templates (`.ai-rules/templates/{claude,copilot,codex,cursor}.tmpl`). The generated files contain a header comment marking them as generated and pointing to the source.

A Jenkins stage `rule-parity-check` runs on every PR. It regenerates all four files from `source.yaml` and diffs them against the committed versions. If any file is out of sync, the PR is blocked with a clear message: "Rule file drift detected. Edit `.ai-rules/source.yaml` and run `scripts/render-ai-rules.sh`."

A pre-commit hook runs the same check locally, catching drift before it reaches CI.

## Cross-AI-tool design

### Claude Code
- **Role:** Rule author and parity enforcer. Claude Code's agentic terminal mode is ideal for editing `source.yaml` and running the render script in one session. `CLAUDE.md` includes a generated rule: "Never edit this file directly. Edit `.ai-rules/source.yaml` and run `scripts/render-ai-rules.sh`." Claude Code is also the preferred tool for adding complex multi-tool rules because it can validate the YAML schema and preview all four outputs before committing.
- **Shared contract it reads/writes:** Reads/writes `.ai-rules/source.yaml`. Reads generated `CLAUDE.md`.
- **Fallback if unavailable:** Any developer can edit `source.yaml` in any editor and run the render script manually. The Jenkins gate enforces parity regardless.

### GitHub Copilot
- **Role:** Inline rule consumption. Copilot reads the generated `.github/copilot-instructions.md` (which includes a header pointing to `source.yaml`). Copilot Coding Agent PRs that modify any of the four rule files trigger the parity check automatically. `.github/prompts/edit-ai-rules.prompt.md` provides a guided prompt for editing `source.yaml` through Copilot Chat.
- **Shared contract it reads/writes:** Reads generated `.github/copilot-instructions.md`. Writes to `.ai-rules/source.yaml` via prompt-guided editing.
- **Fallback if unavailable:** Manual editing of `source.yaml` + render script. Jenkins gate catches drift.

### Codex
- **Role:** Deterministic rule validator. `AGENTS.md` (itself generated) instructs Codex to run `scripts/render-ai-rules.sh --check` before submitting any task that touches rule files. Codex's task-file determinism makes it the cleanest validator — it won't skip the check.
- **Shared contract it reads/writes:** Reads generated `AGENTS.md` and `.ai-rules/source.yaml`. Validates parity as a pre-submit step.
- **Fallback if unavailable:** Jenkins parity check is the gate. Local validation is a convenience.

### Cursor
- **Role:** IDE-integrated rule editor. `.cursor/rules/ai-rules-parity.mdc` (generated) warns when a developer opens any of the four generated files directly, suggesting they edit `source.yaml` instead. A custom command `/edit-rules` opens `source.yaml` and runs the render script on save. Cursor's IDE tightness makes it the best "wrong file, redirect" surface.
- **Shared contract it reads/writes:** Reads generated `.cursorrules`. Reads/writes `.ai-rules/source.yaml` via the custom command.
- **Fallback if unavailable:** Terminal-based editing + render script. Jenkins gate is the universal backstop.

## Languages affected
Language-agnostic at the protocol level — `source.yaml` is YAML, the render script is bash/Python, and the generated files are markdown. However, the *content* of the rules is deeply multi-language: `source.yaml` contains per-language sections for Go, Python, Node.js, C++, and C conventions. The generator ensures each language's rules appear identically across all four tool files, which is the core value proposition.

## Infra impact
- **Jenkins:** New stage `rule-parity-check` in the shared library, callable as `ruleParity()`. Runs early in the pipeline (before build). Blocking — drift means the PR cannot merge. Adds <5 seconds to CI (just a diff comparison).
- **Kubernetes:** No runtime impact.
- **Density/perf research:** Indirect benefit — ensures density-research-specific rules (like the canary DO_NOT_EMIT block from idea 2 or perf-witness instructions from idea 3) are consistently enforced across all tools, preventing tool-specific gaps in density-critical conventions.

## Concrete artifact

`.ai-rules/source.yaml` (excerpt):
```yaml
version: "1.0"
global_rules:
  - id: no-direct-edit
    text: "Never edit generated AI rule files directly. Edit .ai-rules/source.yaml."
  - id: commit-trailer
    text: "Every AI-assisted commit must include an AI-Tool: trailer."
  - id: canary-do-not-emit
    source: generated
    generator: scripts/render-canary-rules.sh

per_language:
  go:
    - id: go-error-handling
      text: "Always wrap errors with fmt.Errorf and %w verb."
  cpp:
    - id: cpp-alloc
      text: "Prefer arena allocators over malloc in density-critical paths."

per_tool_overrides:
  claude_code:
    - id: claude-subagent-depth
      text: "Limit subagent depth to 2 for performance."
  cursor:
    - id: cursor-composer-scope
      text: "In Composer mode, limit file scope to 5 files per session."
```

Generated header (appears in all four files):
```markdown
<!-- GENERATED from .ai-rules/source.yaml — do not hand-edit -->
<!-- To modify rules, edit .ai-rules/source.yaml and run scripts/render-ai-rules.sh -->
<!-- Last generated: 2026-04-19T08:00:00Z -->
```

Jenkins stage:
```groovy
stage('rule-parity-check') {
  steps {
    script {
      def drift = ruleParity(source: '.ai-rules/source.yaml')
      if (drift) { error("Rule file drift detected: ${drift.files.join(', ')}. Edit source.yaml and re-render.") }
    }
  }
}
```

## Success metric
- Zero rule-file drift incidents after adoption (down from ~3/month currently), measured by the `rule-parity-check` stage block rate trending to zero after the initial rollout period.
- 100% of rule additions go through `source.yaml` within 4 weeks, measured by git log analysis of the four generated files showing only render-script commits.
- Cross-tool consistency complaints in retros drop to zero within one quarter.
- New rules propagate to all four tools within the same PR, measured by diffstat showing all four files updated atomically.

## Risks & failure modes
- **Template complexity:** Per-tool templates may diverge in structure, making `source.yaml` hard to author. Mitigated by keeping templates simple (markdown injection) and providing a schema validator.
- **Over-centralization:** All rule changes require editing YAML, which may slow down rapid iteration. Mitigated by making the render script fast (<1s) and providing IDE integration (Cursor `/edit-rules` command).
- **Merge conflicts on source.yaml:** High-traffic rule changes may conflict. Mitigated by structuring `source.yaml` as a list of independent rule blocks (no cross-references within the file).
- **Generated file confusion:** Developers may still try to edit generated files. Mitigated by the header comment, the pre-commit hook, and the Cursor "wrong file" warning.

## Originality statement

**Versus existing ideas in this repo:**
Idea 2 (Canary Identifiers) mentions a `render-canary-rules.sh` script that generates a DO_NOT_EMIT block across four files — this idea generalizes that pattern into a full rule-file parity system. Overlap with idea 2: ~25% (shared concept of generating identical blocks across tool files). Idea 3 (Perf Witness Tickets) is unrelated. This idea is a superset of the canary-rule rendering, not a duplicate — it handles all rules, not just canaries.

**Versus common industry proposals:**
This is not a lint agent, test generator, review bot, or any other tired idea. Config-as-code and template-driven generation are common infrastructure patterns, but applying them specifically to AI tool instruction files — with per-tool override semantics, a Jenkins parity gate, and integration with the cross-tool principle of "instruction-file parity" — is novel to this domain. The `cross-tool-principles.md` document explicitly calls out instruction drift as an anti-pattern but provides no enforcement mechanism; this idea is that mechanism. It satisfies novelty heuristic #1 (new inter-tool protocol: the single-source YAML) and indirectly supports #3 (density-research rules are included in the parity system).
