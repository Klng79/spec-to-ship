---

<p align="center">
  <h1 align="center">🚢 Spec to Ship</h1>
  <p align="center">
    <strong>From vague idea to working code, in 4 phases.</strong>
  </p>
  <p align="center">
    <a href="#compatibility"><img src="https://img.shields.io/badge/AI_Agent-Universal-blue?style=flat-square" alt="AI Agent Universal" /></a>
    <a href="https://github.com/Klng79/spec-to-ship/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License" /></a>
    <a href="https://github.com/Klng79/spec-to-ship/stargazers"><img src="https://img.shields.io/github/stars/Klng79/spec-to-ship?style=flat-square" alt="Stars" /></a>
  </p>
</p>

---

## The Problem

You have a fuzzy idea. You open an AI agent. An hour later you have 47 files changed, a half-broken feature, and three misunderstandings you didn't catch until *after* implementation.

**Spec to Ship fixes this** by forcing a 4-phase pipeline — Grill → PRD → Issues → Implement — with hard gates between phases. The agent cannot write code until the spec is sharp enough to write *correct* code.

## What You Get

```
/spec-to-ship I want to build a CLI that tracks my AI subscriptions
```

One command. The skill runs a 4-phase pipeline:

| Phase | Orchestrates | What you get |
|-------|-------------|-------------|
| **1. Grill** | `/grill-with-docs` | Aligned domain model, terminology, ADRs |
| **2. PRD** | `/to-prd` | Structured PRD in `docs/prd-<name>.md` |
| **3. Issues** | `/to-issues` | Vertical-slice issues, ranked by dependency |
| **4. Implement** | `/tdd` per issue (with `/agentic-coding-loop` as repair fallback) | Working, verified code |

Each phase has a **hard gate** — explicit user confirmation required before the next phase can start. No silent phase skipping.

## Why It's Different

### 🛑 Hard Gates, No Phase Skipping

```
┌──────────┐    gate    ┌──────────┐    gate    ┌──────────┐    gate    ┌──────────┐
│ 1. Grill │ ─────────▶ │ 2. PRD   │ ─────────▶ │ 3. Issue │ ─────────▶ │ 4. Loop  │
└──────────┘  user must └──────────┘  user must └──────────┘  user must └──────────┘
              confirm                confirm                confirm
```

The agent cannot declare a phase "trivial" and skip it. Even a one-line CSS change goes through the pipeline. If the pipeline is too heavy, you shouldn't have invoked the skill.

### 📋 Status File Is the Source of Truth

Every phase writes to `docs/spec-to-ship-status.md`. Resume from any phase after a crash:

```
| Phase | Status | Started | Completed |
|-------|--------|---------|-----------|
| 1. Grill | DONE | 2026-06-22 | 2026-06-22 |
| 2. PRD | IN_PROGRESS | 2026-06-23 | — |
| 3. Issues | PENDING | — | — |
| 4. Loop | PENDING | — | — |
```

Kill the session? Restart it. The status file tells you exactly where you are.

### 🔁 Spec Feedback Loop

When implementation reveals that the spec was wrong — not buggy, but *conceptually* wrong — the pipeline loops back:

- 3+ issues hit the same wall → re-grill
- Tests pass but behavior is wrong → revise PRD
- Implementation needs off-limits files → re-scope

The skill doesn't let bad specs compound into bad code.

### 🧩 Orchestrates Existing Skills

Spec to Ship is a **playbook**, not a reimplementation. It sequences and gates:

- [`/grill-with-docs`](https://github.com/Klng79/grill-with-docs) — alignment interview
- [`/to-prd`](https://github.com/Klng79/to-prd) — PRD authoring
- [`/to-issues`](https://github.com/Klng79/to-issues) — issue breakdown
- [`/tdd`](https://github.com/Klng79/tdd) — test-first implementation
- [`/agentic-coding-loop`](https://github.com/Klng79/agentic-coding-loop) — repair fallback

You install Spec to Ship. The orchestrator calls the rest.

## The 4 Phases

### Phase 1: Grill — `/grill-with-docs`

Interview the user relentlessly. Challenge the plan against the existing domain model. Sharpen fuzzy terminology. Create ADRs for hard-to-reverse decisions.

**Gate:** User confirms the domain model is aligned. Options: proceed / discuss more / start over.

### Phase 2: PRD — `/to-prd`

Synthesize grilling output into a structured PRD. Explore the codebase, sketch modules, write `docs/prd-<name>.md`, publish to issue tracker.

**Gate:** User approves PRD. Options: proceed to issues / revise / re-grill first.

### Phase 3: Issues — `/to-issues`

Break the PRD into thin vertical slices through all layers. Classify each as HITL (needs user) or AFK (agent-runnable). Map dependencies. Publish in dependency order.

**Gate:** User approves breakdown. Options: start implementation / adjust slices / revise PRD.

### Phase 4: Implement — `/tdd` + `/agentic-coding-loop`

For each issue:
1. Run `/tdd` (red → green → refactor)
2. On GREEN and review-clean → mark DONE
3. On RED after 3 refactors → escalate to `/agentic-coding-loop` for root-cause diagnosis
4. On BLOCKED → flag it, skip to next issue
5. On OUT_OF_SCOPE → spec feedback loop

Sequential execution. No parallelization by default — slices share files.

## When Spec Feedback Triggers

The skill loops back to Phase 1 (or Phase 2) when:

- Same BLOCKED status across 3+ issues (pattern, not coincidence)
- TDD passes tests but behavior doesn't match expectations
- User says "this isn't what I meant"
- Implementation requires changes to off-limits files
- `/agentic-coding-loop` returns OUT_OF_SCOPE on a slice that should have been implementable

**Don't re-invoke `/spec-to-ship` to loop back** — you're already inside it.

## Anti-Patterns

The skill actively prevents:

- **Phase skipping** — agent rationalizes "this is trivial, I'll skip grilling" → status file says PENDING, gate check fails
- **Coding before Phase 4** — agent starts writing files during PRD → no gate, no code
- **Self-approving gates** — agent assumes user approval from context → `ask_user_question` is mandatory
- **Parallel issue execution** — shared files corrupt → sequential by default
- **Endless re-grilling** — one feedback loop per issue is enough; if the second reveals problems too, the issue is too large
- **Status file drift** — file updated at every transition, not at the end

## Entry Point Detection

The skill detects where you are and resumes accordingly:

1. **Existing status file** → read it, resume from next incomplete phase
2. **Existing PRD** → skip to Phase 3, ask: re-grill or continue?
3. **Existing issues with `ready-for-agent`** → skip to Phase 4
4. **None of the above** → start at Phase 1

You can skip forward past completed work. You can never skip backward past a gate.

## Completion

When all issues resolve:

```
## Spec to Ship: Complete

**Feature:** <name>
**Duration:** <start> → <end>
**Phases:** Grill ✓ → PRD ✓ → Issues ✓ → Loop ✓

### Artifacts
- PRD: docs/prd-<name>.md
- Issues: <N> total (<X> DONE, <Y> BLOCKED, <Z> OUT_OF_SCOPE)
- CONTEXT.md: <N> terms added
- ADRs: <N> created

### Spec Feedback
- <N> feedback loops triggered
- <details of any spec changes>
```

## Compatibility

Spec to Ship works with any AI agent that supports:
- Skill invocation via `/skill-name`
- `ask_user_question` for gates
- File system access for status files and PRDs
- Issue tracker integration (or local `docs/issues/` directory)

No specific CLI required. Tested with Qwen Code.

## Installation

### 1. Install spec-to-ship

```bash
git clone https://github.com/Klng79/spec-to-ship.git ~/.qwen/skills/spec-to-ship
```

### 2. Install required sub-skills

Spec to Ship orchestrates 4 required sub-skills. Each must be cloned into your skills directory:

```bash
git clone https://github.com/Klng79/grill-with-docs.git ~/.qwen/skills/grill-with-docs
git clone https://github.com/Klng79/to-prd.git        ~/.qwen/skills/to-prd
git clone https://github.com/Klng79/to-issues.git     ~/.qwen/skills/to-issues
git clone https://github.com/Klng79/tdd.git           ~/.qwen/skills/tdd
```

### 3. Install optional sub-skills

[`/agentic-coding-loop`](https://github.com/Klng79/agentic-coding-loop) is used as a conditional repair fallback in Phase 4. Install it if you want automatic recovery when `/tdd` hits a wall:

```bash
git clone https://github.com/Klng79/agentic-coding-loop.git ~/.qwen/skills/agentic-coding-loop
```

If any required sub-skill is missing, the phase that calls it will fail with a clear "skill not found" error.

## License

MIT — see [LICENSE](LICENSE).
