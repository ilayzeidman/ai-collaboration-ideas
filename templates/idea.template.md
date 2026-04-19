# Idea N: <Title>

> Replace `N` with the actual idea number and `<Title>` with a concrete, evocative title. Every section below is required. Fill with specifics, not placeholders.

## One-line summary
<A single sentence, 140 characters or fewer, that captures the idea. This exact line is copied verbatim into `ideas/SUMMARY.md`.>

## Tags
<Comma-separated, lowercase, hyphen-separated. Used for dedup. Examples: `shared-context`, `code-review`, `density-research`, `jenkins`, `cross-tool-routing`, `benchmarks`, `rule-file-parity`.>

## Problem
<The observed workflow pain. Point to a concrete symptom — "teammate on Cursor regenerated a file Claude Code had already refactored, because neither tool knew what the other had done" — not a hypothetical. One or two paragraphs.>

## Proposal
<The mechanism, artifact, or protocol. Explain what gets built and how it operates. Do not hand-wave: if you propose "a shared decision log", define where it lives, what each record contains, how records are appended, and how they're consumed.>

## Cross-AI-tool design

Every tool gets a named role, a shared contract, and a graceful-degradation behavior.

### Claude Code
- **Role:**
- **Shared contract it reads/writes:**
- **Fallback if unavailable:**

### GitHub Copilot
- **Role:**
- **Shared contract it reads/writes:**
- **Fallback if unavailable:**

### Codex
- **Role:**
- **Shared contract it reads/writes:**
- **Fallback if unavailable:**

### Cursor
- **Role:**
- **Shared contract it reads/writes:**
- **Fallback if unavailable:**

## Languages affected
<List which of Python, Go, Node.js, C++, C this idea touches and why. If "language-agnostic", justify it by showing the idea doesn't rely on any language's specific tooling.>

## Infra impact
<Jenkins pipeline changes (specific stage, specific shared-library call), Kubernetes objects touched, impact on density/perf research if any. "None" is acceptable only with justification.>

## Concrete artifact
<What a developer actually sees. Example: a file path, a schema snippet, a command invocation, a sample pipeline stage, a rule snippet. Show, don't describe.>

```
<code / schema / example here>
```

## Success metric
<How the team will know it worked. Quantitative if possible — "reduces duplicate refactors across tools by N per week, measured by X". Qualitative metrics must be falsifiable.>

## Risks & failure modes
<What breaks if this ships. What happens at scale. What happens when a tool's capability changes. What maintenance burden this creates.>

## Originality statement
<Required. Two parts:>

**Versus existing ideas in this repo:**
<Reference every thematically-adjacent idea in `ideas/SUMMARY.md` by number. Explicitly state how this idea is different from each. If there are no prior ideas, say so.>

**Versus common industry proposals:**
<Reference the tired-ideas list in `context/originality-guide.md`. Explain how this idea is not any of them, and does not merely reskin them.>
