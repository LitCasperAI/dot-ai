---
id: <stable-slug>
type: plan
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
owner: implementer
related:
  brief: docs/briefs/active/YYYY-MM-DD-<slug>.md
  spec: docs/specs/active/YYYY-MM-DD-<slug>.md
  test_plan: null # set to docs/plans/active/YYYY-MM-DD-<slug>-tests.md once design-tests has run
progress:
  total: 0
  done: 0
  current_phase: 1
tracker:
  parent: null # { id, url } mirror of the spec's issue, once published
  phases: [] # [{ slug, issue: { id, url } | null, blocked_by: [<slug>, ...] }]; see 17-tracker-integration.md
---

# <Feature Name> — Implementation Plan

## Context

Link to spec: `docs/specs/active/YYYY-MM-DD-<slug>.md`
Link to brief: `docs/briefs/active/YYYY-MM-DD-<slug>.md`
Link to open questions: `docs/open-questions/YYYY-MM-DD-<slug>.md`

## Phase 1 — <Name> <!-- slug: phase-1-<kebab-name> -->

- [ ] 🔄 First task
- [ ] Next task
- [ ] Last task in this phase
- [ ] **Validation**: Execute stack-mandated validation (e.g., lint, build, test).

## Phase 2 — <Name> <!-- slug: phase-2-<kebab-name> -->

- [ ] Task
- [ ] Task
- [ ] **Validation**: Execute stack-mandated validation (e.g., lint, build, test).

## Phase 3 — <Name> <!-- slug: phase-3-<kebab-name> -->

- [ ] Task
- [ ] Task
- [ ] **Validation**: Execute stack-mandated validation (e.g., lint, build, test).

## Notes

_YYYY-MM-DD: One-line summary of where we paused, what state the
code is in, what the next actionable step is, and which branch._

## Rule compliance

- [ ] Follows `rules/stacks/<stack>/...`
- [ ] Follows `rules/global/...`
- [ ] <Any gates: security review, perf review, etc.>

<!--
  Conventions (see `docs/design-rationale.md` §9):

  - 🔄 marks the *single* currently-in-progress task. Agents look
    for this marker first when resuming.
  - Each phase must end in a working, testable state. Pausing
    after any phase must leave the app runnable.
  - The Notes section is mandatory on pause, even as a one-liner.
  - `progress.total` and `progress.done` are updated on every
    checkbox flip. `current_phase` tracks the active phase.
  - Rule compliance is not exhaustive — list only rules that
    matter for this specific plan, plus any gates.
  - A plan starts at `status: draft` and must be flipped to
    `approved` (manual `status: approved` edit, or
    `approve=<plan-path>` on `create-plan`) before `implement` or
    `resume-plan` will touch it. See `04-doc-lifecycle.md`.
  - Each `## Phase N — <Name> <!-- slug: phase-N-<kebab-name> -->`
    heading carries a stable, position-independent slug, assigned
    once (by `create-plan`, or manually for hand-authored plans)
    and never changed thereafter. `tracker.phases[].slug` in the
    frontmatter matches this comment. See
    `17-tracker-integration.md`.
-->
