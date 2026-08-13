---
name: implement
description: Implement an approved plan file under docs/plans/active/ phase by phase, keeping the plan's checkboxes, progress counters, 🔄 marker, and Notes section honest as work proceeds.
---

## Inputs

- Path to a plan file in `<paths.plans>/active/` (path resolved via
  `.ai-local/project.yaml`) with `status` in `{approved,
  in-progress}`. `status: draft` is refused — see `create-plan`'s
  approval step. `approved` is promoted to `in-progress` in step 1.
- Optional: a specific phase to work on. If omitted, continue from
  the task marked 🔄, or from the first unchecked task in the
  earliest incomplete phase if no marker is present.
- Optional: `mode: full-plan`. Set when this skill is invoked to
  carry an entire plan to completion in one sitting (e.g. via the
  `goal` skill) rather than one phase at a time. Triggers the
  fan-out path in step 2a instead of stopping at the next phase
  boundary.

## Personas

1. `implementer` — loaded from `.ai/personas/implementer.md`, plus
   any additive content at `.ai/overrides/<stack>/implementer.md`
   if that file exists. (Overrides are not present in Stage 1; the
   loader should handle absence silently.)

## Rules loaded

From `.ai-local/project.yaml`:

- All entries in `rules.core`, applied in order.
- Relevant entries from `rules.contextual` (specifically `06-testing.md`, `07-dependencies.md`, `17-tracker-integration.md`, and any stack-specific implementation rules).

This skill does not hardcode rule paths. If `project.yaml` is
missing, malformed, or references files that do not exist, stop
and ask.

## Steps

1. **Orient.** `implementer` reads `.ai-local/project.yaml`, then loads
   the plan file, the spec it references, and the brief it
   references. Loads the persona, all `rules.core`, and required
   `rules.contextual` files. Require `status` in `{approved,
   in-progress}`; refuse `status: draft` with "this plan needs
   approval first — see `create-plan`'s approval step." If `status`
   on the plan is `approved`, promote it to `in-progress` and bump
   `updated`.

2. **Locate the cursor.** `implementer` finds the 🔄 marker. If
   there is no marker, uses the first unchecked task in the
   earliest incomplete phase. Announces the chosen task before
   starting work.

2a. **Fan-out (`mode: full-plan` only).** Skip this step entirely
    unless `mode: full-plan` was requested. Phases run in plan
    order, one at a time — never in parallel — since each phase is
    assumed to build on the file state the previous one left
    behind; if the plan explicitly marks phases as independent,
    those may be dispatched together instead. For each remaining
    phase, starting from the one located in step 2:
    - Invoke the `handoff` skill, passing the plan's path and the
      phase number as its argument. Per `handoff`'s own rules, the
      resulting document references the plan, spec, and brief by
      path rather than restating them, and its "suggested skills"
      section names `implement` with that phase as the target.
    - Dispatch a sub-agent carrying that handoff doc. The sub-agent
      loads the `implementer` persona itself (per the Personas
      section above) and runs steps 3–5 for every task in that
      phase only, then reports back instead of pausing.
    - Wait for the sub-agent to finish and confirm the phase is ✅
      (and its tracker issue, if any, is closed per step 5) before
      writing the next phase's handoff doc.
    - If a sub-agent stops on an escalation (per the persona's
      "What I escalate" list) or a failing check it cannot resolve,
      halt the fan-out, surface the issue to the user, and do not
      dispatch further phases.
    Once every phase is ✅, proceed to step 8.

3. **Implement one task.** `implementer` writes the minimum code
   that makes the task true. Matches surrounding conventions. Does
   not expand scope. If the task needs something the spec did not
   answer, stops and escalates per the persona's escalation rules.

4. **Verify.** Runs the tests, linters, and type checks the plan
   or the loaded rules call out. A failing check is not "done" —
   either fix it or stop and surface the failure.

5. **Update the plan.** Ticks the completed checkbox. Moves the 🔄
   marker to the next task. Increments `progress.done` and bumps
   `updated` in the frontmatter. If a phase just completed, marks
   its heading with ✅ and, if a later phase exists, bumps
   `current_phase`. Immediately after marking the phase ✅: if the
   tracker is configured (non-`local` `tracker:` block in
   `project.yaml`) and that phase has a recorded
   `tracker.phases[].issue.id`, call Close on it (see
   `17-tracker-integration.md`) before moving to the next phase or
   pausing. On a `local`/absent tracker, or a phase with no
   recorded issue, this is a documented no-op.

6. **Repeat** from step 2 until a phase boundary is reached or the
   user asks to pause.

7. **On pause.** Appends a one-line entry to the Notes section —
   date, code state, next actionable step, branch name. Skipping
   this is a regression.

8. **On plan completion.** **Open Questions Gate:** Extract the exact date prefix
   from the plan's filename. Check `docs/open-questions/<exact-date-prefix>-<id>.md`.
   If it exists and contains unanswered questions, stop and warn the user. You
   must not mark the plan `done` until all questions are answered.
   Once clear, set `status: done` in the frontmatter and bump
   `updated`. Does **not** move files or archive in this skill —
   archival is handled by `/archive-plan`. Surfaces that the plan
   is ready to archive.

## Outputs

- Code changes in the repository, scoped to the completed task(s).
- An updated plan file at its existing path under
  `<paths.plans>/active/` — edited in place, not moved.
- No new files under `docs/` are created by this skill. It only
  edits the plan it was handed.
