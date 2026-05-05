---
name: implement
description: Implement an approved plan file under docs/plans/active/ phase by phase, keeping the plan's checkboxes, progress counters, 🔄 marker, and Notes section honest as work proceeds.
---

## Inputs

- Path to a plan file in `<paths.plans>/active/` (path resolved via
  `.ai-local/project.yaml`) with `status: in-progress`. `status: draft`
  is accepted and promoted to `in-progress` in step 1.
- Optional: a specific phase to work on. If omitted, continue from
  the task marked 🔄, or from the first unchecked task in the
  earliest incomplete phase if no marker is present.

## Personas

1. `implementer` — loaded from `.ai/personas/implementer.md`, plus
   any additive content at `.ai/overrides/<stack>/implementer.md`
   if that file exists. (Overrides are not present in Stage 1; the
   loader should handle absence silently.)

## Rules loaded

From `.ai-local/project.yaml`:

- All entries in `rules.core`, applied in order.
- Relevant entries from `rules.contextual` (specifically `06-testing.md`, `07-dependencies.md`, and any stack-specific implementation rules).

This skill does not hardcode rule paths. If `project.yaml` is
missing, malformed, or references files that do not exist, stop
and ask.

## Steps

1. **Orient.** `implementer` reads `.ai-local/project.yaml`, then loads
   the plan file, the spec it references, and the brief it
   references. Loads the persona, all `rules.core`, and required
   `rules.contextual` files. If `status` on the plan is `draft`, promote it to
   `in-progress` and bump `updated`.

2. **Locate the cursor.** `implementer` finds the 🔄 marker. If
   there is no marker, uses the first unchecked task in the
   earliest incomplete phase. Announces the chosen task before
   starting work.

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
   `current_phase`.

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
