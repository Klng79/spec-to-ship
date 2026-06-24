---
name: spec-to-ship
description: Full lifecycle playbook — grill a vague idea into a sharp spec, produce a PRD, break it into vertical-slice issues, then implement each issue test-first via /tdd, with /agentic-coding-loop as a conditional repair fallback. Orchestrates /grill-with-docs, /to-prd, /to-issues, /tdd, and /agentic-coding-loop as sub-phases. Use when the user wants to go from idea to shipped code end-to-end, or invokes this skill directly.
---

# Spec to Ship

A four-phase playbook that takes a vague idea through grilling, PRD authoring, issue breakdown, and implementation — ending with working, verified code.

This skill is a **playbook**, not a reimplementation. It orchestrates five existing skills as sub-phases, adding sequencing, gates, state tracking, and a feedback loop for when implementation reveals spec problems.

## PRE-FLIGHT CHECKLIST — EXECUTE ON EVERY INVOCATION

Before doing anything else, complete this checklist. Do not skip any step. Do not proceed until all steps are done.

### Step 1: Read the status file

Read `docs/spec-to-ship-status.md`. If it doesn't exist, create it with all phases set to PENDING.

### Step 2: Determine current phase

Based on the status file, identify which phase is the next incomplete phase. Announce it explicitly:

```
**Spec to Ship — Pre-flight complete**
- Status file: `docs/spec-to-ship-status.md` (exists | created)
- Current phase: Phase N (<name>)
- Next action: <what this phase requires>
```

### Step 3: Execute only the current phase

Do not jump ahead. Do not combine phases. Do not "quickly finish" multiple phases in one turn. Execute only the current phase, then stop at the gate.

### Step 4: Gate check

Before moving to the next phase, verify:
- Did the user explicitly confirm the gate? (Yes/No)
- Is the status file updated? (Yes/No)

If either answer is No, do not proceed.

### Why this checklist exists

Without explicit phase announcement, the agent will drift into implementation mode without realizing it has skipped phases. This checklist creates a commitment device: once you've stated "I'm in Phase 1," you cannot easily skip to Phase 4 without acknowledging the violation.

---

## HARD RULES — NO EXCEPTIONS

These rules override all other considerations. They cannot be bypassed, rationalized away, or shortened.

1. **No phase skipping.** Every invocation runs all 4 phases in order. You cannot declare a phase "trivial" or "unnecessary for this scope." The user's time is not yours to optimize away.

2. **No coding before Phase 4.** Do not write, edit, or modify any source file until Phase 4 explicitly begins. Reading files for context is allowed. Writing code is not.

3. **Gates require explicit user confirmation.** Each gate uses `ask_user_question`. You cannot self-approve a gate. You cannot infer approval from context. The user must click an option.

4. **Status file is the source of truth.** If the status file says a phase is PENDING, that phase has not been completed — regardless of what you "remember" doing.

5. **No scope judgment.** The skill does not classify tasks as "big" or "small." A one-line CSS change and a multi-module feature go through the same pipeline. If the pipeline is too heavy for a task, the user should not have invoked this skill.

### Why these rules exist

The agent will rationalize skipping phases. It will say "this is just a layout change" or "the scope is obvious." These are the exact failure modes the skill is designed to prevent. The grilling phase catches assumptions the agent didn't know it had. The PRD catches missing edge cases. The issue breakdown catches dependency problems. Skipping any phase removes that safety net.

## Phases

| Phase | Orchestrates | Gate to next phase |
|-------|-------------|-------------------|
| 1. Grill | `/grill-with-docs` | User confirms alignment |
| 2. PRD | `/to-prd` | User approves PRD |
| 3. Issues | `/to-issues` | User approves slice breakdown |
| 4. Implement | `/tdd` per issue, `/agentic-coding-loop` as conditional fallback | All issues DONE or BLOCKED |

## Entry Point Detection

On invocation, detect where the user is in the lifecycle. Run these checks in order:

### 1. Check for existing status file

Look for `docs/spec-to-ship-status.md`. If it exists and has incomplete phases:

- Read it to determine the last completed phase
- Resume from the next incomplete phase
- Show the user the current state and ask: "Resume from Phase N, or start fresh?"

### 2. Check for existing PRD

Look for recent PRD files in `docs/prd-*.md`. If one exists and matches the user's stated topic:

- Read it to confirm scope alignment
- Skip to Phase 3 (Issues)
- Ask: "PRD found at `docs/prd-<name>.md`. Start from issue breakdown, or re-grill first?"

### 3. Check for existing issues

Check the issue tracker for issues with `ready-for-agent` label that reference a PRD. If found:

- List the issues and their status
- Skip to Phase 4 (Loop)
- Ask: "Issues found. Start implementation, or re-breakdown first?"

### 4. Default — start from Phase 1

If none of the above match, start from the beginning:

- Ask the user what they want to build
- Run Phase 1 (Grill)

**Rule:** You can skip forward past completed work, but never backward past a gate. Implementation requires issues. Issues require a PRD. A PRD requires grilling.

## Status File

Write and maintain `docs/spec-to-ship-status.md` throughout the lifecycle. Create it at the start of Phase 1. Update it at every phase transition and after each issue completes.

### Template

```markdown
# Spec to Ship: <project/feature name>

**Started:** <YYYY-MM-DD>
**Last updated:** <YYYY-MM-DD>

## Phase Status

| Phase | Status | Started | Completed | Notes |
|-------|--------|---------|-----------|-------|
| 1. Grill | DONE | <date> | <date> | |
| 2. PRD | IN_PROGRESS | <date> | — | |
| 3. Issues | PENDING | — | — | |
| 4. Loop | PENDING | — | — | |

## Artifacts

- **PRD:** `docs/prd-<name>.md`
- **CONTEXT.md:** updated with <N> new terms
- **ADRs:** `docs/adr/000N-<slug>.md`

## Issue Tracker

| Issue | Title | Type | Status | Attempt | Notes |
|-------|-------|------|--------|---------|-------|
| #N | <title> | AFK | DONE | 2/3 | |
| #N+1 | <title> | AFK | IN_PROGRESS | 1/3 | |
| #N+2 | <title> | HITL | BLOCKED | 0/3 | needs user decision |

## Spec Feedback Log

| Date | Issue | Problem Found | Action Taken |
|------|-------|--------------|--------------|
| <date> | #N | <what the implementation revealed> | <re-grill / PRD update / etc.> |
```

## Phase 1: Grill

Invoke `/grill-with-docs` with the user's idea as the topic.

**What happens:**
- Interview the user about every aspect of the plan
- Challenge against the existing domain glossary in `CONTEXT.md`
- Sharpen fuzzy terminology
- Update `CONTEXT.md` inline as terms resolve
- Create ADRs when decisions meet all three criteria (hard to reverse, surprising, real trade-off)

**Gate:** The user must explicitly confirm alignment before proceeding. Use `ask_user_question`:

- "Are we aligned on the domain model and key decisions?"
  - Options: "Yes, move to PRD" / "I have more to discuss" / "Start over"

**On gate pass:**
- Update status file: Phase 1 → DONE
- Record which terms were added to CONTEXT.md
- Record which ADRs were created

## Phase 2: PRD

Invoke `/to-prd` to synthesize the grilling output into a structured PRD.

**What happens:**
- Explore the codebase to understand current state
- Sketch major modules (look for deep, testable modules)
- Check with the user that modules match expectations
- Write PRD to `docs/prd-<short-name>.md` with frontmatter
- Publish to issue tracker with `ready-for-agent` label (or `draft` if the tracker supports it)

**Gate:** The user must review and approve the PRD. Use `ask_user_question`:

- "PRD written to `docs/prd-<name>.md`. Ready to break into issues?"
  - Options: "Yes, break into issues" / "I want to revise" / "Re-grill first"

If the user chooses "Re-grill first," loop back to Phase 1 with the PRD as context.

**On gate pass:**
- Update status file: Phase 2 → DONE
- Record PRD file path in artifacts

## Phase 3: Issues

Invoke `/to-issues` to break the PRD into vertical-slice issues.

**What happens:**
- Draft tracer-bullet slices (thin vertical cuts through all layers)
- Classify each as HITL or AFK
- Map dependencies between slices
- Present breakdown to user for approval
- Iterate on granularity until approved
- Publish issues to tracker in dependency order (blockers first)

**Gate:** The user must approve the breakdown. Use `ask_user_question`:

- "Issue breakdown approved. Start implementation?"
  - Options: "Yes, start loop" / "Adjust slices" / "Revise PRD first"

If the user chooses "Revise PRD first," loop back to Phase 2.

**On gate pass:**
- Update status file: Phase 3 → DONE
- Record issue count and breakdown in status file

## Phase 4: Implement

Execute each issue using `/tdd` as the primary implementation engine, with `/agentic-coding-loop` as a conditional repair fallback when TDD hits a wall.

### Execution Order

1. Sort issues by dependency order (blockers first)
2. Pick the first unblocked issue
3. Run `/tdd` on the issue (test-first: red → green → refactor)
4. On GREEN and refactor-clean → mark issue DONE, pick up the next
5. On RED after 3 refactors → run `/agentic-coding-loop` to diagnose & repair
6. On GREEN but review finds issues → run `/agentic-coding-loop` Review+Repair only
7. On BLOCKED (from ACL) → flag it, skip to the next unblocked issue
8. On OUT_OF_SCOPE (from ACL) → flag it, ask the user for guidance
9. Repeat until all issues are DONE, BLOCKED, or OUT_OF_SCOPE

### Why TDD is the Primary Engine

By Phase 4, the work is already decomposed into well-specified vertical slices with acceptance criteria (from Phase 3). Each slice is narrow, complete, and demoable — exactly what TDD is designed for. The grilling (Phase 1), PRD (Phase 2), and issue breakdown (Phase 3) have already done the heavy lifting that `/agentic-coding-loop`'s scope gate and plan step would repeat.

`/tdd` provides:
- **Test-first discipline** — failing test before implementation (red → green → refactor)
- **Acceptance criteria as test cases** — the checkbox list from each issue becomes the test suite
- **Low ceremony** — no scope gate, no snapshot management, no 8-step loop overhead

### When to Escalate to `/agentic-coding-loop`

TDD is sufficient for most AFK slices with clear acceptance criteria in known modules. Escalate to `/agentic-coding-loop` only when:

| Trigger | What ACL Adds |
|---------|-------------|
| RED after 3 refactors | Root-cause diagnosis, up to 3 repair attempts with rollback |
| GREEN but review finds issues | Security/performance/minimalism review, targeted repair |
| Runtime/browser verify command | Loop pattern detection (Runtime Debugging, Product Iteration) |
| HITL slice with architectural decisions | Scope gate, plan confirmation, human checkpoint |

**Do NOT run ACL on every slice.** Running ACL on a slice that TDD handles cleanly is redundant — its scope gate would classify most post-Phase-3 slices as Tactical, adding ceremony without value. ACL earns its overhead when things go wrong.

### Sequential Enforcement

**One issue at a time.** Do not parallelize. Reasons:

- Slices share files — parallel edits cause merge conflicts
- Each issue's tests depend on the previous issue's changes being committed
- Sequential execution proves each slice is independently verifiable
- Dependency order is naturally respected

**Exception:** If two slices have zero file overlap (confirmed by checking the action space of both), offer the user the option to parallelize. Default to sequential.

### Spec Feedback Loop

When implementation reveals that the PRD or spec was wrong — not just buggy, but *conceptually* wrong — handle it:

**Detection signals:**
- The same BLOCKED status occurs across 3+ issues (pattern, not coincidence)
- TDD consistently produces tests that pass but don't match expected behavior
- The user says "this isn't what I meant"
- Implementation requires changes to off-limits files that shouldn't need changing
- `/agentic-coding-loop` returns OUT_OF_SCOPE on an issue that should have been implementable

**Response:**
1. Stop the current implementation
2. Document what was found in the Spec Feedback Log (status file)
3. Ask the user: "Implementation is revealing a spec problem. Re-grill this area?"
   - Options: "Yes, re-grill" / "Update PRD directly" / "Accept and move on"
4. If re-grill → loop back to Phase 1 with the specific issue as context
5. If update PRD → go to Phase 2 with the feedback
6. If accept → mark the issue with a note and continue

**After returning from a feedback loop:**
- Re-run Phase 3 (Issues) for the affected slices — they may need re-scoping
- Resume Phase 4 from where it left off

**Circular escalation note:** If `/agentic-coding-loop` returns OUT_OF_SCOPE or classifies the task as Strategic, this triggers the spec feedback loop — do NOT re-invoke `/spec-to-ship`. Loop back to Phase 1 directly, since you are already inside spec-to-ship.

### Progress Reporting

After each issue completes (or is blocked), update the status file:

- Mark the issue's status (DONE / BLOCKED / OUT_OF_SCOPE)
- Record attempt count from the agentic loop
- Note any spec feedback

Show the user a brief summary after each issue:

```
Issue #N: <title> — DONE (2 attempts)
Progress: 3/7 issues complete
Next: #N+1 — <title> (blocked by: none)
```

## Completion

When all issues are resolved:

1. Update status file: Phase 4 → DONE
2. Run a final verification across the full codebase (not just per-issue verify)
3. Present the final summary:

```
## Spec to Ship: Complete

**Feature:** <name>
**Duration:** <start date> → <end date>
**Phases:** Grill ✓ → PRD ✓ → Issues ✓ → Loop ✓

### Artifacts
- PRD: `docs/prd-<name>.md`
- Issues: <N> total (<X> DONE, <Y> BLOCKED, <Z> OUT_OF_SCOPE)
- CONTEXT.md: <N> terms added/updated
- ADRs: <N> created

### Spec Feedback
- <N> feedback loops triggered
- <details of any spec changes>

### Remaining Risks
- <from any issue reviews>
```

## Anti-Patterns

- **Skipping grilling because "I already know what I want"** — the grilling phase catches assumptions you didn't know you had. If you truly have a complete spec, start at Phase 2 explicitly.
- **Parallel issue execution by default** — shared files will corrupt. Sequential unless proven otherwise.
- **Ignoring spec feedback** — if 3 issues hit the same wall, the wall is in the spec, not the code.
- **Endless re-grilling** — one feedback loop per issue is enough. If the second loop also reveals problems, the issue is too large. Split it.
- **Status file drift** — update the status file at every transition, not at the end. If the session dies, the file is the resume point.
- **Implementing without issues** — the issue breakdown forces you to think about dependencies and granularity. Skipping it leads to monolithic untestable changes.
